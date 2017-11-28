{async} = require "fairmont"

module.exports = (s) ->
  lambdaUpdate = async (names, bucket) ->
    republish = ->
      s.lambda.update(name, bucket, "package.zip") for name in names

    yield s.meta.handlers.update()
    yield Promise.all republish()
