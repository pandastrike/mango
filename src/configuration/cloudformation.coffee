#===============================================================================
# CFo Template Configuration
# Pull in the main API definition and assorted mixins to generate a
# CloudFormation template.  Each mixin's template is merged into a large CFo
# template that is attached to the main configuration object.
#===============================================================================
{resolve, basename} = require "path"
{async, read, merge, readdir, isFile, last, exists} = require "fairmont"
{yaml} = require "panda-serialize"
_render = require "panda-template"
preprocessors = require "./preprocessors"

AWSTemplateFormatVersion = "2010-09-09"

skyMixinsPath = resolve __dirname, "..", "..", "mixins"


# Adapter to keep existing code working
transitional = async (config, envName) ->
  globals = merge config, {env: envName}
  appRoot = process.cwd()
  cfoTemplate = yield renderTemplate appRoot, globals
  config.aws.cfoTemplate = JSON.stringify cfoTemplate
  config

# Returns an object, not a serialized string.
renderTemplate = async (appRoot, globals) ->
  Description = globals.description || "#{globals.name} - deployed by Panda Sky"
  Resources = yield renderResources appRoot, globals

  return {
    AWSTemplateFormatVersion
    Description
    Resources
  }

# Finds and renders all mixins as the Resources for a CloudFormation Template.
renderResources = async (appRoot, globals) ->
  resources = []
  mixinNames = yield listMixins appRoot
  for name in mixinNames
    resources.push yield renderMixin appRoot, name, globals
  # Each mixin template may define a number of CloudFormation Resources. We
  # merge them in a blind manner, so it is possible for one mixin to clobber a
  # Resource key supplied by a predecessor. Predictability depends on the order
  # of results returned by `fairmont.readdir`.
  merge resources...
  

renderMixin = async (dir, name, globals) ->

  # TODO: template = getMixinTemplate(name)
  template = yield read resolve skyMixinsPath, "#{name}.yaml"

  # FIXME: This is a good indication that the Sky API description
  # isn't the same kind of mixin as the other mixins.
  dataPath = if name == "api" then "api" else "mixins/#{name}"

  # acquire the parameters for this particular mixin from the app files
  mixinConfig = yaml yield read resolve dir, "#{dataPath}.yaml"

  # FIXME: should globals be winning over mixin-specific params?
  mungedConfig = merge mixinConfig, globals

  preprocessor = preprocessors[name]
  mungedConfig = yield preprocessor mungedConfig
  yaml _render template, mungedConfig


listMixins = async (appRoot) ->
  mixinPath = resolve appRoot, "mixins"
  mixins = ["api"]

  if yield exists mixinPath
    files = yield readdir mixinPath
    for file in files when isFile file
      mixins.push basename file, ".yaml"
  mixins



module.exports = {
  transitional
  renderTemplate
  listMixins
  renderResources
  renderMixin
}

