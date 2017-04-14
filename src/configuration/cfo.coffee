#===============================================================================
# CFo Template Configuration
# Pull in the main API definition and assorted mixins to generate a
# CloudFormation template.  Each mixin's template is merged into a large CFo
# template that is attached to the main configuration object.
#===============================================================================
{join, resolve} = require "path"
{async, read, merge} = require "fairmont"
{yaml} = require "panda-serialize"
_render = require "panda-template"
preprocessors = require "./preprocessors"

module.exports = async (config, env) ->

  # TODO: first assignment here is getting clobbered.
  # Presumably we just need to remove it.
  globals = yaml yield read join process.cwd(), "sky.yaml"
  globals = merge config, {env}

  # Each mixin has a template that gets rendered before joining the others.
  # TODO: Is there any reason to keep this function here, rather than hoisting
  # it up to the file level?  Just add `globals` to the parameters.
  render = async (name) ->
    template = yield read join __dirname, "..", "..", "mixins", "#{name}.yaml"
    data = yaml yield read join process.cwd(), "#{name}.yaml"
    data = yield preprocessors[name] merge data, globals
    console.log yaml JSON.parse JSON.stringify data
    yaml _render template, data

  # Compile a CFo template using the API base (mixins pending.)
  mixins = []
  mixins.push yield render "api"
  cfo =
    AWSTemplateFormatVersion: "2010-09-09"
    Description: config.description || "#{config.name} - deployed by Panda Sky"
    Resources: merge mixins...

  # Add the stringified, rendered CloudFormation template to the config object.
  config.aws.cfoTemplate = JSON.stringify cfo
  config
