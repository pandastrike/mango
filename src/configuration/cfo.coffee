#===============================================================================
# CFo Template Configuration
# Pull in the main API definition and assorted mixins to generate a
# CloudFormation template.  Each mixin's template is merged into a large CFo
# template that is attached to the main configuration object.
#===============================================================================
{join, resolve} = require "path"
{async, read, merge, readdir, isFile, last} = require "fairmont"
{yaml} = require "panda-serialize"
_render = require "panda-template"
preprocessors = require "./preprocessors"

module.exports = async (config, env) ->

  globals = yaml yield read join process.cwd(), "sky.yaml"
  globals = merge config, {env}

  # Each mixin has a template that gets rendered before joining the others.
  render = async (name) ->
    template = yield read join __dirname, "..", "..", "mixins", "#{name}.yaml"
    name = "mixins/#{name}" if name != "api"
    data = yaml yield read join process.cwd(), "#{name}.yaml"
    data = yield preprocessors[name] merge data, globals
    yaml _render template, data

  # Compile a CFo template using the API base and mixins within the repo's "mixin" directory.
  files = yield readdir join process.cwd(), "mixins"
  mixins = (last(file.split("/")).split(".yaml")[0] for file in files when isFile file)
  mixins.unshift "api"
  cfo =
    AWSTemplateFormatVersion: "2010-09-09"
    Description: config.description || "#{config.name} - deployed by Panda Sky"
    Resources: merge yield render mixins...

  # Add the stringified, rendered CloudFormation template to the config object.
  config.aws.cfoTemplate = JSON.stringify cfo
  config
