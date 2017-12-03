{async} = require "fairmont"

{bellChar} = require "../../utils"
configuration = require "../../configuration"

module.exports = async (env, options) ->
  try
    appRoot = process.cwd()
    console.error "Compiling configuration for API custom domain."
    config = yield configuration.compile(appRoot, env)
    sky = yield require("../../aws/sky")(env, config)

    yield sky.domain.prePublish config.aws.hostnames[0], options
    console.error "\nPublishing..."
    yield sky.domain.publish config.aws.hostnames[0]
    console.error "Done.\n\n"
  catch e
    console.error "Publish failure:"
    console.error e.stack
  console.error bellChar
  sky.cfo
