{async, collect, where, empty} = require "fairmont"

module.exports = async ->
  # TODO: Consider how to handle multiple region cert placement.
  {acm} = yield require("./index")("us-east-1")
  {root, regularlyQualify} = do require "./url"

  wild = (name) -> regularlyQualify "*." + root name
  apex = (name) -> regularlyQualify root name

  getCertList = async ->
    data = yield acm.listCertificates CertificateStatuses: [ "ISSUED" ]
    data.CertificateSummaryList

  # Look for certs that contain wildcard permissions
  match = async (name, list) ->
    certs = collect where {DomainName: wild name}, list
    return certs[0].CertificateArn if !empty certs # Found what we need.

    # No primary wildcard cert.  Look for apex.
    certs = collect where {DomainName: apex name}, list
    for cert in certs
      data = yield acm.describeCertificate {CertificateArn: cert.CertificateArn}
      alternates = data.Certificate.SubjectAlternativeNames
      return cert.CertificateArn if wild(name) in alternates

    false # Failed to find wildcard cert among alternate names.

  fetch = async (name) ->
    try
      arn = yield match name, yield getCertList()
    catch e
      e.description = "Unexpected response while searching SSL certs."
      throw new Error()

    if !arn
      throw new Error "You do not have an active certificate for #{wild name}"
    else
      arn

  {fetch}
