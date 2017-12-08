{join} = require "path"
{define, run} = require "panda-9000"
{async, randomWords, read, write, shell, exists} = require "fairmont"
PandaTemplate = require("panda-template").default
{safe_cp, safe_mkdir, bellChar, outputDuration} = require "../utils"
interview = require "../interview"

# This sets up an existing directory to hold a Panda Sky project.
START = 0
module.exports = (start) ->
  START = start
  run "init"


define "init", async ->
  try
    # Ask politely to install fairmont and js-yaml
    interview.setup()
    questions = [
      name: "ps"
      description: "Add panda-sky-helpers as a dependency to package.json? [Y/n]"
      default: "Y"
    ,
      name: "yaml"
      description: "Add js-yaml as a dependency to package.json? [Y/n]"
      default: "Y"
    ]

    console.error "Press ^C at any time to quit."
    answers = yield interview.ask questions

    if answers.fairmont || answers.yaml
      console.error "\n Adding module(s). One moment..."
      yield shell "npm install panda-sky-helpers --save" if answers.ps
      yield shell "npm install js-yaml --save" if answers.yaml



    config =
      projectID: yield randomWords 6

    # Drop in the file stubs.
    src = (file) -> join( __dirname, "../../init/#{file}")
    target = (file) -> join process.cwd(), file

    T = new PandaTemplate()
    render = async (src, target) ->
      if yield exists target
        console.error "Warning: #{target} exists. Skipping."
        return
      template = yield read src
      output = T.render template, config
      yield write target, output

    # Drop in an API description stub.
    yield safe_cp (src "api.yaml"), (target "api.yaml")

    # Drop in a Panda Sky configuration stub.
    yield render (src "sky.yaml"), (target "sky.yaml")

    # Drop in a dispatcher stub and corresponding API handlers.
    yield safe_cp (src "api"), (target "src/")

    console.error "Panda Sky project initialized."
    console.error "Done. (#{outputDuration START})\n\n"
  catch e
    console.error e.stack
  console.error bellChar
