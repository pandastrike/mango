{merge} = require "fairmont"

# This helper makes it easier to manipulate data in S3.  It takes a bucket name
# and returns an interface that lets you put, get, or delete an object.
module.exports = (AWS) ->
  s3 = new AWS.S3
  (bucketName) ->
    get = (key) ->
      new Promise (resolve, reject) ->
        s3.getObject
          Bucket: bucketName
          Key: key
          (error, data) ->
            unless error?
              resolve data.Body
            else
              reject error

    del = (key) ->
      new Promise (resolve, reject) ->
        s3.deleteObject
          Bucket: bucketName
          Key: key
          (error, data) ->
            unless error?
              resolve null
            else
              reject error

    put = (key, value, opts={}) ->
      params =
        Bucket: bucketName
        Key: key
        Body: value

      params = merge params, opts

      new Promise (resolve, reject) ->
        s3.putObject params, (error, data) ->
          unless error?
            resolve null
          else
            reject error

    {get, put, del}
