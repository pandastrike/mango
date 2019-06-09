import possibleResponses from "./possible-responses"
import addResponseMappingTemplates from "./content-types"
import {cat, first, rest} from "panda-parchment"

# Gateway does not, by default, support arbitrary HTTP responses.  Each response
# type must be explicitly specified in an API method description.  The code
# below adds these responses based on the enumerated response codes in the API
# description.

allowedHeaders = "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Cache-Control,ETag,Last-Modified,Accept,Accept-Encoding, Location,Capability"
exposedHeaders = "Content-Type,X-Amz-Date,Authorization,Cache-Control,ETag,Last-Modified,Content-Encoding,Vary,Location,Capability"

within = (collection, example) -> example in collection
without = (collection, example) -> example not in collection

Responses = (description) ->
  # Array of possible responses generated by the Lambda integration
  addIntegrationResponses = (method, methodList) ->
    {cache, status:statuses, mediatype} = method.signatures.response
    {maxAge, etag, lastModified} = cache if cache

    addDefault = ->
      headers =
        "Access-Control-Allow-Headers": "'#{allowedHeaders}'"
        "Access-Control-Allow-Methods": "'#{methodList}'"
        "Access-Control-Allow-Origin": "'*'"
        "Access-Control-Expose-Headers": "'#{exposedHeaders}'"
      if mediatype
        headers["Content-Type"] =
          "integration.response.body.metadata.headers.Content-Type"
      if cache
        headers["Cache-Control"] =
          "integration.response.body.metadata.headers.Cache-Control"
        headers["Vary"] =
          "integration.response.body.metadata.headers.Vary"
      if etag
        headers["ETag"] =
          "integration.response.body.metadata.headers.ETag"
      if lastModified
        headers["Last-Modified"] =
          "integration.response.body.metadata.headers.Last-Modified"
      if (first statuses) == 201
        headers["Location"] =
          "integration.response.body.metadata.headers.Location"

      response =
        StatusCode: first statuses
        headers: headers
      addResponseMappingTemplates response, method

    addOthers = ->
      for code in rest statuses
        headers =
          "Content-Type": "'application/json'"
          "Access-Control-Allow-Headers": "'#{allowedHeaders}'"
          "Access-Control-Allow-Methods": "'#{methodList}'"
          "Access-Control-Allow-Origin": "'*'"
          "Access-Control-Expose-Headers": "'#{exposedHeaders}'"

        if code == 304
          headers["Cache-Control"] =
            "integration.response.body.errorMessage.metadata.headers.Cache-Control"
          headers["Vary"] =
            "integration.response.body.errorMessage.metadata.headers.Vary"
          if etag
            headers["ETag"] =
              "integration.response.body.errorMessage.metadata.headers.ETag"
          if lastModified
            headers["Last-Modified"] =
              "integration.response.body.errorMessage.metadata.headers.Last-Modified"

        StatusCode: code
        SelectionPattern: "\\{\"httpStatus\"\\:#{code}.*"
        ResponseTemplates: "application/json": """$input.json('$.data')"""
        headers: headers




    # First response is "default" response, then all others.
    cat [addDefault()], addOthers()

  # Array of possible responses whitelisted by the Method response, coming from
  # the Integration response.
  addMethodResponses = (method) ->
    {cache, status:statuses, mediatype} = method.signatures.response
    {maxAge, etag, lastModified} = cache if cache

    addDefault = ->
      headers =
        "Access-Control-Allow-Headers": true
        "Access-Control-Allow-Methods": true
        "Access-Control-Allow-Origin": true
        "Access-Control-Expose-Headers": true
      if mediatype
        headers["Content-Type"] = true
      if cache
        headers["Cache-Control"] = true
        headers["Vary"] = true
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
        headers =
          "Content-Type": true
          "Access-Control-Allow-Headers": true
          "Access-Control-Allow-Methods": true
          "Access-Control-Allow-Origin": true
          "Access-Control-Expose-Headers": true
        if code == 304
          headers["Cache-Control"] = true
          headers["Vary"] = true
          if etag
            headers["ETag"] = true
          if lastModified
            headers["Last-Modified"] = true

        StatusCode: code
        headers: headers


    cat addDefault(), addOthers()


  # Infer request-response signature from the API configuration to not require the developer to explicitly define each time.
  expandImplicitSignature = (method) ->
    {signatures:{request, response}} = method
    {status} = response

    if request.schema && !request.mediatype
      request.mediatype = ["application/json"]

    if !response.mediatype && (within [200, 201], first status)
      response.mediatype = ["application/json"]

    status.push 304 if response.cache && (without status, 304)
    status.push 400 if (without status, 400)
    status.push 406 if response.mediatype && (without status, 406)
    status.push 415 if request.mediatype && (without status, 415)
    status.push 500 if (without status, 500)

    method




  {resources} = description
  for r, resource of resources
    for httpMethod, method of resource.methods
      method = expandImplicitSignature method

      resources[r].methods[httpMethod].IntegrationResponses = addIntegrationResponses method, resource.methodList
      resources[r].methods[httpMethod].MethodResponses = addMethodResponses method

  description.resources = resources
  description

export default Responses
