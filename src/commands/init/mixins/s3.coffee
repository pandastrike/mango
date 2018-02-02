{resolve} = require "path"
{async, values, randomWords, read, write, shell, exists} = require "fairmont"
PandaTemplate = require("panda-template").default
Interview = require("panda-interview").default

{safe_cp, safe_mkdir} = require "../../../utils"

module.exports = async ->
  # Ask politely to install fairmont and js-yaml
  {ask} = new Interview()
  questions = [
    name: "s3"
    description: "Add sky-mixin-s3 as a dev-dependency to package.json? [Y/n]"
    default: "Y"
  ,
    name: "ps"
    description: "Add panda-sky-helpers as a dependency to package.json? [Y/n]"
    default: "Y"
  ,
    name: "yaml"
    description: "Add js-yaml as a dependency to package.json? [Y/n]"
    default: "Y"
  ]

  console.error "Press ^C at any time to quit."
  try
    answers = yield ask questions
  catch e
    console.error "\nProcess aborted. \nDone.\n\n"
    process.exit()

  if true in values answers
    console.error "\n Adding module(s). One moment..."
    yield shell "npm install sky-mixin-s3 --save-dev" if answers.s3
    yield shell "npm install panda-sky-helpers --save" if answers.ps
    yield shell "npm install js-yaml --save" if answers.yaml

  projectID = yield randomWords 6
  config =
    projectID: projectID
    buckets: ["sky-#{projectID}-alpha", "sky-#{projectID}-beta"]

  # Drop in the file stubs.
  src = (file) -> resolve __dirname, "..", "..", "..", "..",
    "init", "s3", "#{file}"
  target = (file) -> resolve process.cwd(), file

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
  console.error "Done.\n\n"