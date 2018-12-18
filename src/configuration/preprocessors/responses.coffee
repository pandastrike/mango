import possibleResponses from "./possible-responses"
import addResponseMappingTemplates from "./content-types"
import {cat, first, rest} from "panda-parchment"

# Gateway does not, by default, support arbitrary HTTP responses.  Each response
# type must be explicitly specified in an API method description.  The code
# below adds these responses based on the enumerated response codes in the API
# description.

allowedHeaders = "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Cache-Control,ETag,Last-Modified"

Responses = (description) ->
  # Array of possible responses generated by the Lambda integration
  addIntegrationResponses = (method, methodList) ->
    {cache, status:statuses} = method.signatures.response
    {maxAge, etag, lastModified} = cache if cache

    addDefault = ->
      headers =
        "Access-Control-Allow-Headers": "'#{allowedHeaders}'"
        "Access-Control-Allow-Methods": "'#{methodList}'"
        "Access-Control-Allow-Origin": "'*'"
      if cache
        headers["Cache-Control"] = "integration.response.body.metadata.headers.Cache-Control"
      if etag
        headers["ETag"] = "integration.response.body.metadata.headers.ETag"
      if lastModified
        headers["Last-Modified"] = "integration.response.body.metadata.headers.Last-Modified"
      if (first statuses) == 201
        headers["Location"] = "integration.response.body.metadata.headers.Location"

      response =
        StatusCode: first statuses
        headers: headers
      addResponseMappingTemplates response, method

    addOthers = ->
      for code in rest statuses
        StatusCode: code
        SelectionPattern: "^<#{possibleResponses[code]}>.*"
        headers:
          "Access-Control-Allow-Headers": "'#{allowedHeaders}'"
          "Access-Control-Allow-Methods": "'#{methodList}'"
          "Access-Control-Allow-Origin": "'*'"

    # First response is "default" response, then all others.
    cat [addDefault()], addOthers()

  # Array of possible responses whitelisted by the Method response, coming from
  # the Integration response.
  addMethodResponses = (method) ->
    {cache, status:statuses} = method.signatures.response
    {maxAge, etag, lastModified} = cache if cache

    addDefault = ->
      headers =
        "Content-Type": true
        "Access-Control-Allow-Headers": true
        "Access-Control-Allow-Methods": true
        "Access-Control-Allow-Origin": true
      if cache
        headers["Cache-Control"] = true
      if etag
        headers["ETag"] = true
      if lastModified
        headers["Last-Modified"] = true
      if (first statuses) == 201
        headers["Location"] = true

      [
        StatusCode: first statuses
        headers: headers
      ]

    addOthers = ->
      for code in rest statuses
        StatusCode: code
        headers:
          "Access-Control-Allow-Headers": true
          "Access-Control-Allow-Methods": true
          "Access-Control-Allow-Origin": true

    cat addDefault(), addOthers()


  # Add responses that we don't require the developer to explicitly define
  implicitResponses = (method) ->
    if 500 not in method.signatures.response.status
      method.signatures.response.status.push 500
    if 415 not in method.signatures.response.status
      method.signatures.response.status.push 415
    if 422 not in method.signatures.response.status
      method.signatures.response.status.push 422
    if method.signatures.response.cache
      method.signatures.response.status.push 304
    method

  {resources} = description
  for r, resource of resources
    for httpMethod, method of resource.methods
      method = implicitResponses method

      resources[r].methods[httpMethod].IntegrationResponses = addIntegrationResponses method, resource.methodList
      resources[r].methods[httpMethod].MethodResponses = addMethodResponses method

  description.resources = resources
  description

export default Responses
