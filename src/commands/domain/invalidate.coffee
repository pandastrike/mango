{async} = require "fairmont"

{bellChar, outputDuration} = require "../../utils"
configuration = require "../../configuration"

module.exports = async (START, env, options) ->
  try
    appRoot = process.cwd()
    console.error "Compiling configuration for API custom domain."
    config = yield configuration.compile(appRoot, env, options.profile)
    sky = yield require("../../aws/sky")(env, config)

    yield sky.domain.preInvalidate config.aws.hostnames[0], options
    yield sky.domain.invalidate config.aws.hostnames[0]
    console.error "Done. (#{outputDuration START})\n\n"
  catch e
    console.error "Invalidation failure:"
    console.error e.stack
  console.error bellChar
  sky.cfo
