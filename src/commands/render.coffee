YAML = require "js-yaml"
{yaml, json} = require "panda-serialize"
{async, merge} = require "fairmont"

{bellChar} = require "../utils"
configuration = require "../configuration"
cloudformation = require("../configuration/cloudformation")

module.exports = async (env) ->
  try
    appRoot = process.cwd()
    config = yield configuration.compile appRoot, env
    console.log yaml json config.aws.cfoTemplate
  catch e
    console.error e.message
    if e.errors
      console.error YAML.dump {errors: e.errors}

  console.log bellChar

