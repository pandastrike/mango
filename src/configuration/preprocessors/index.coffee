# Sky tries to accept only simple configuration and then apply them in a clever
# way to AWS.  That requires building up the more detialed configuration the
# underlying configuraiton requires.  These preprocessors do quite a bit to
# add that layer of sophistication.
import checkEnvironmentIntegrity from "./environment"
import extractPaths from "./paths"
import extractResources from "./resources"
import extractMethods from "./methods"
import addTags from "./tags"
import extractDomains from "./custom-domains"
import addAuthorization from "./authorization"
import addResponses from "./responses"
import addVariables from "./variables"
import addPolicyStatements from "./policy-statements"
import splitTemplates from "./split"
import fetchMixins from "./mixins"
import extractVPC from "./vpc"

Preprocessor = (config) ->
  config = await checkEnvironmentIntegrity config

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

  # Final odds and ends for applying these resources to the template.
  config = await splitTemplates config

  # Fetch the declared mixins installed in the project directory and instantiate
  # their CLI and render interfaces.
  config = await fetchMixins config

  config

export default Preprocessor
