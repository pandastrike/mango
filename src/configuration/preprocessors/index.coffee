# Sky tries to accept only simple configuration and then apply them in a clever
# way to AWS.  That requires building up the more detialed configuration the
# underlying configuraiton requires.  These preprocessors do quite a bit to
# add that layer of sophistication.

{async, capitalize} = require "fairmont"
STS = require "../../aws/sts"

extractPaths = require "./paths"
extractResources = require "./resources"
extractMethods = require "./methods"
addTags = require "./tags"
extractDomains = require "./custom-domains"
addAuthorization = require "./authorization"
addResponses = require "./responses"
addVariables = require "./variables"
addPolicyStatements = require "./policy-statements"
fetchMixins = require "./mixins"
extractVPC = require "./vpc"
#addCustomResources = require "./custom-resources"

module.exports = async (config) ->
  {name, env} = config
  {whoAmI} = yield STS config
  config.accountID = (yield whoAmI()).Account

  config.gatewayName = config.stackName = "#{name}-#{env}"
  config.roleName = "#{capitalize name}#{capitalize env}LambdaRole"
  config.policyName = "#{name}-#{env}"


  # Add in default tags.
  config = addTags config

  # Extract path from configuration
  config = extractPaths config

  # Add environment variables that are injected into every Lambda.
  config = addVariables config

  # Apply default configuration to custom domain configuration
  config = extractDomains config

  # Extract and validate optional VPC configuration.
  config = extractVPC config

  # Build up resource array that includes virtual resources needed by Gateway.
  config = extractResources config

  # Compute the formatted template names for API action defintions.
  config = extractMethods config

  # Add in authorization via a Gateway Authorizer, if specified.
  config = addAuthorization config

  # Add the possible HTTP responses to every API action specification.
  config = addResponses config

  # Add base Sky policy statements that give Lambdas access to AWS resources.
  config = addPolicyStatements config

  # Custom resources are developer defined resources in CloudFormation
  # TODO: Think about how to approach this.  A mixin form might be better.
  #config = yield addCustomResources config

  # Remove the root resource, because it needs special handling
  rootKey = config.rootResourceKey
  delete config.resources[rootKey]
  delete config.rootResourceKey

  # Fetch the declared mixins installed in the project directory and instantiate
  # their CLI and render interfaces.
  config = yield fetchMixins config

  config
