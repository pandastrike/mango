{async} = require "fairmont"

scan = require "./scan"
Confirm = require "./confirm"

module.exports = (s) ->
  {isViable} = scan s
  confirm = Confirm s

  # All of the stuff needed before we're sure it's safe to proceed.
  preDelete = async (name, options) ->
    console.error "-- Scanning AWS for appropriate Cloud resources."
    yield isViable name
    yield confirm name, options

  # This is the main domain publishing engine.
  destroy = async (name) ->
    # Deploy the CloudFront distribution
    console.error "-- Issuing edge cache teardown..."
    yield s.cfr.delete name

    # Update the corresponding DNS records.
    console.error "-- Issuing DNS record removal..."
    yield s.route53.delete name

    # Remove this hostname to the environment's Sky Bucket.
    yield s.meta.hostnames.remove name

  {preDelete, delete: destroy}
