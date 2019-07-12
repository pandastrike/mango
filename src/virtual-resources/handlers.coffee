import {md5} from "fairmont"
import {read} from "panda-quill"
import {toLower, cat, sleep, empty, last, dashed} from "panda-parchment"
import {partition} from "panda-river"
import {yaml} from "panda-serialize"
import Bucket from "../bucket"
import Logs from "../logs"

fail = ->
  console.warn "WARNING: No Sky metadata detected for this deployment.  This feature is meant only for pre-existing Sky deployments and will not continue."
  console.log "Done."
  process.exit()

Handlers = class Handlers
  constructor: (@config) ->
    @stack = @config.aws.stack
    @Lambda = @config.sundog.Lambda()

  initialize: ->
    api = yaml await read @stack.apiDef
    names =
      for r, resource of api.resources
        for m, method of resource.methods
          dashed "#{@config.name} #{@config.env} #{r} #{m}"

    @names = cat names...
    @bucket = await Bucket @config
    @logs = await Logs @config

  update: (hard) ->
    fail() if !@bucket.metadata
    await @bucket.syncHandlersSrc()
    await do =>
      for batch from partition 20, @names
        await Promise.all(
          @Lambda.update name, @stack.src, "package.zip" for name in batch
        )

    if hard
      await sleep 5000
      LambdaConfig =
        MemorySize: @config.aws.memorySize
        Timeout: @config.aws.timeout
        Runtime: @config.aws.runtime
        Environment:
          Variables: @config.environmentVariables
      await do =>
        for batch from partition 20, @names
          await Promise.all(
            @Lambda.updateConfig name, LambdaConfig for name in batch
          )

  # Tail the logs output by the various Lambdas.
  tail: (isVerbose) ->
    time = new Date().getTime()
    latestTime = false
    latestEvent = false

    while true
      events = await @logs.scan time
      if !empty events
        events = @logs.reconcile events, latestTime, latestEvent

      if !empty events
        lastEvent = last events
        latestTime = lastEvent.timestamp
        latestEvent = md5 lastEvent.message
        @logs.output isVerbose, events
        time = latestTime - 1
      await sleep 2000

handlers = (config) ->
  h = new Handlers config
  await h.initialize()
  h

export default handlers
