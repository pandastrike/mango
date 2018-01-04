# Accept a configuration for the deployment and come up with tags for every
# resource we label within the stack.
module.exports = (config) ->
  tags = [
    {
      Key: "project"
      Value: config.name
    }
    {
      Key: "skyID"
      Value: config.projectID
    }
    {
      Key: "environment"
      Value: config.env
    }
  ]

  if config.tags
    tags.push(tag) for tag in config.tags
  config.tags = tags
  config
