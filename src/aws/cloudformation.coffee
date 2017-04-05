{async, first, sleep} = require "fairmont"

module.exports = async (env, config) ->
    {cfo} = yield require("./index")(config.aws.region)
    src = yield require("./app-root")(env, config)
    name = "#{config.name}-#{env}"

    stackConfig = (type) ->
      t = "template.yaml" if type == "full"
      t = "soft-template.yaml" if type == "soft"
      t = "hard-template.yaml" if type == "hard"
      t = "empty-template.yaml" if type == "empty"

      StackName: name
      TemplateURL: "http://#{env}-#{config.projectID}.s3.amazonaws.com/#{t}"
      Capabilities: ["CAPABILITY_IAM"]
      Tags: config.tags

    getStack = async (id) ->
      try
        first (yield cfo.describeStacks({StackName: id})).Stacks
      catch
        false

    getApiUrl = async ->
      params =
        LogicalResourceId: "API"
        StackName: name

      data = yield cfo.describeStackResource params
      apiID = data.StackResourceDetail.PhysicalResourceId
      "https://#{apiID}.execute-api.#{config.aws.region}.amazonaws.com/#{env}"

    # Update an existing stack with a new template.
    update = async (updates) ->
      # Because of GW quirk, all API resources have to be wiped out before
      # making edits to child resources. Updating is a two-step process.
      console.log "Existing stack detected. Updating."

      # Step 1: Destroy guts of Stack
      if "All" in updates
        updateWith = "empty" # destroys entire stack
      else if "GW" in updates
        updateWith = "hard"  # destroys most of stack
      else
        updateWith = "soft" # targets only Lamba handlers

      yield cfo.updateStack stackConfig updateWith
      yield publishWait name

      # Step 2: Apply the full, updated Stack. Put it all back.
      yield cfo.updateStack stackConfig "full"

    # Create a new stack from scrath with the template.
    create = async ->
      console.log "Creating fresh stack."
      yield cfo.createStack stackConfig "full"

    publish = async ->
      console.log "Scanning AWS for current deploy."
      needsDeploy = yield src.prepare()  # Prep the app's core bucket
      if !needsDeploy
        console.log "#{name} is up to date."
        return false

      # If the stack already exists, update instead of create.
      if {StackId} = yield getStack name
        yield update needsDeploy
      else
        {StackId} = yield create()
      StackId

    # Delete the application using CloudFormation
    destroy = async ->
      {StackId} = yield getStack name
      yield cfo.deleteStack StackName: name
      StackId

    # Confirm the stack is viable and online.
    publishWait = async (id) ->
      while true
        {StackStatus, StackStatusReason} = yield getStack id
        switch StackStatus
          when "CREATE_IN_PROGRESS", "UPDATE_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS"
            yield sleep 5000
          when "CREATE_COMPLETE", "UPDATE_COMPLETE"
            return true
          else
            console.error "Stack creation failed. Aborting.", StackStatus,
              StackStatusReason
            throw new Error()


    # Confirm the stack is fully and properly deleted.
    deleteWait = async (id) ->
      while true
        s = yield getStack id
        return true if !s
        switch s.StackStatus
          when "DELETE_IN_PROGRESS"
            yield sleep 5000
          when "DELETE_COMPLETE"
            return true
          else
            console.warn "Stack deletion failed.", s.StackStatus,
              s.StackStatusReason
            return false

    # Handle stuff that happens after we've confirmed the stack deployed.
    postPublish = async ->
      yield src.syncMetadata()
      if !config.aws.environments[env].cache
        console.log "Your API is online and ready at the following endpoint:"
        console.log "  #{yield getApiUrl()}"


    # Handle stuff that happens after we've confirmed the stack deleted.
    postDelete = async -> yield src.destroy()


    {publish, delete: destroy, publishWait, deleteWait, postPublish, postDelete}
