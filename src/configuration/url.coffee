module.exports = (config, env) ->
  # Pull config data for the requested environment.
  desired = config.aws.environments[env]
  {domain} = config.aws

  # Construct an array of full subdomains to feed the process.
  hostnames = []
  if desired.hostnames
    hostnames.push "#{name}.#{domain}" for name in desired.hostnames
  config.aws.hostnames = hostnames

  # Pull CloudFront (cdn / caching) info into the config
  config.aws.cache = applyDefaultCacheConfig desired.cache

  config

# Accept the cache configuraiton and fill in any default values.
applyDefaultCacheConfig = (config={}) ->
  config.httpVersion ||= "http2"
  config.protocol ||= "TLSv1.2_2018"
  config.expires ||= 0
  config.priceClass ||= 100
  config.headers = setHeaders config.headers

  config

setHeaders = (headers) ->
  if !headers
    defaultHeaders
  else if "*" in headers && headers.length > 1
    console.error """
      ERROR: Incorrect header cache specificaton.  Wildcard cannot be used with
      other named headers.  Please adjust the cache configuration for this
      environment within sky.yaml and try again.

      This process will discontinue.
      Done.
    """
    process.exit()
  else
    headers

defaultHeaders = [
  "Accept",
  "Accept-Charset",
  "Accept-Datetime",
  "Accept-Language",
  "Access-Control-Request-Headers",
  "Access-Control-Request-Method",
  "Authorization",
  "Origin",
  "Referer"
]
