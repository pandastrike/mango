{async, cat} = require "fairmont"

module.exports = async (config) ->
  {lambda} = yield require("./index")(config.aws.region, config.profile)

  update = async (name, bucket, key) ->
    yield lambda.updateFunctionCode
      FunctionName: name
      Publish: true
      S3Bucket: bucket
      S3Key: key

  list = async (fns=[], marker) ->
    params = {MaxItems: 100}
    params.Marker = marker if marker

    {NextMarker, Functions} = yield lambda.listFunctions params
    fns = cat fns, Functions
    if NextMarker
      yield list fns, NextMarker
    else
      fns

  Delete = async (name) -> yield lambda.deleteFunction FunctionName: name

  {update, list, delete:Delete}
