{async, sleep, collect, where, empty, deepEqual} = require "fairmont"

AWS = require "../index"
Helpers = require "./primatives"

module.exports = async (sky) ->
  {route53} = yield AWS sky.config.aws.region
  {_delete, _getHostedZoneID, _listRecords, _target,
   _upsert, _wait} = Helpers sky

  # Determine if the user owns the requested URL as a public hosted zone
  getHostedZoneID = async (name) -> yield _getHostedZoneID name

  get = async (name) ->
    records = yield _listRecords yield getHostedZoneID name
    result = collect where {Name: name}, records
    if empty result then false else result[0]

  needsUpdate = async (name, target) ->
    if {Type, AliasTarget} = yield get name
      if Type == "A" && deepEqual AliasTarget, _target target
        false
    else
      true

  publish = async (name, target) ->
    if yield needsUpdate name, target
      id = yield _upsert name, target
      yield _wait id

  destroy = async (name, target) ->
    if !yield needsUpdate name, target
      id = yield _delete name, target
      yield _wait id


  {delete: destroy, get, getHostedZoneID, publish}
