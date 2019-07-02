# Set the environment variables that are injected into each Lambda and tags for AWS resources.  The developer may add or overwrite default values.
import {join} from "path"
import {merge} from "panda-parchment"
import {go} from "panda-river"

applyStackVariables = (config) ->
  config.stack =
    name: "#{config.name}-#{config.env}"
    src: "#{config.name}-#{config.env}-#{config.projectID}"
    pkg: join process.cwd(), "deploy", "package.zip"
    apiDef: join process.cwd(), "api.yaml"
    skyDef: join process.cwd(), "sky.yaml"
  config

applyEnvironmentVariables = (config) ->
  for _, partition of config.environment.partitions
    partition.variables = merge config.environment.variables,
      partition.variables,
      environment: config.env
      skyBucket: config.stack.src # S3 Bucket that orchastrates state

  config

applyTags = (config) ->
  values =
    project: config.name
    environment: config.env

  # Apply explicit tags, deleteing defaults if there is an override.
  values = merge values, config.tags
  for name, partition of config.environment.partitions
    partition.tags = merge values, partition: name, partition.tags

  # Format as "Key" and "Value" for CloudFormation
  config.tags = {Key, Value} for Key, Value of values
  for _, partition of config.environment.partitions
    partition.tags = {Key, Value} for Key, Value of partition.tags

  config

Variables = (config) ->
  go [
    applyStackVariables config
    applyEnvironmentVariables
    applyTags
  ]

export default Variables
