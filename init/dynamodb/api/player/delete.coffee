import AWS from "aws-sdk"

# Access the Panda Sky helpers.
import sky from "panda-sky-helpers"
{env, AWS:{DynamoDB}, response:{NotFound}} = sky AWS

# Instantiate new DynamoDB helper and define deployment "alpha" table.
tableName = "sky-#{env.environment}-alpha"
{tableGet, query, del, to, qv, keysFilter} = DynamoDB
encode = qv to.S

handler = (request, context) ->
  if !await tableGet tableName
    throw new NotFound "The Table #{tableName} cannot be found."
  else
    # Fetch every record that includes this player.
    {PlayerID} = request.url.path
    {Items} = await query tableName, "PlayerID = #{encode PlayerID}"

    # Delete them...
    filter = keysFilter ["PlayerID", "GameTitle"]
    await del tableName, filter i for i in Items
    "Deletion of Player #{PlayerID} complete."

export default handler
