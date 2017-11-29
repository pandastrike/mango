{join} = require "path"
{define, write} = require "panda-9000"
{yaml} = require "panda-serialize"
{async, go, tee, pull, values, shell, exists} = require "fairmont"

{bellChar} = require "../utils"
configuration = require "../configuration"
{render} = Asset = require "../asset"

define "update", ["survey"], async (env) ->
  try
    appRoot = process.cwd()
    config = yield configuration.compile(appRoot, env)
    sky = yield require("../aws/sky")(env, config)

    # Push code through asset pipeline.
    source = "src"
    target = "lib"
    pkg = "deploy/package.zip"

    fail() if !yield exists join process.cwd(), pkg

    yield go [
      Asset.iterator()
      tee async (formats) ->
        yield go [
          values formats
          tee render
          pull
          tee write target
        ]
    ]

    # Push code into pre-existing Zip archive.
    #yield shell "zip -qr #{pkg} lib -x *node_modules*"

    process.exit()
    # Update Sky metadata with new Zip acrhive, and republish all lambdas.
    yield sky.lambdas.update()

  catch e
    console.error e.stack
  console.error bellChar

fail = ->
  console.error """
  WARNING: Unable to find project Zip archive.  This suggests that the project has never been through the 'sky build' step.  `sky update` is only meant to be used for pre-existing deployments.

  Done.
  """
  process.exit()
