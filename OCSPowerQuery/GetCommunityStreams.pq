(query as nullable text, communityId as nullable text, startIndex as nullable datetime, endIndex as nullable datetime) as table =>
    let
        // helper function for reading from a configuration file
        ReadFromConfiguration = (configurationParameter as text) =>
        let
            result = 
                    Record.Field(
                        Json.Document(File.Contents("PATH_TO_CONFIG")),
                        configurationParameter)

        in
            result,

        // helper function for retrieving a token
        GetToken = () =>
        let
            // read configuration parameters
            clientId = ReadFromConfiguration("ClientId"),
            clientSecret = ReadFromConfiguration("ClientSecret"),
            resourceUri = ReadFromConfiguration("ResourceUri"),
            // split URL to avoid Power BI Service error regarding unsupported function Web.Contents
            authUrl = "/identity/connect/token",
            // Construct message for authentication
            escapedClientSecret = Uri.EscapeDataString(clientSecret),
            authPOSTBody =
                "client_id="
                & clientId
                & "&client_secret="
                & escapedClientSecret
                & "&grant_type=client_credentials",
            authPOSTBodyBinary = Text.ToBinary(authPOSTBody),
            // Authenticate
            GetJson =
                try
                    Web.Contents(
                        resourceUri,
                        [
                            RelativePath = authUrl,
                            Headers = [
                                #"Content-Type" = "application/x-www-form-urlencoded;charset=UTF-8",
                                Accept = "application/json"
                            ],
                            IsRetry = true,
                            Content = authPOSTBodyBinary
                        ]
                    ),
            // Get token from the Json response
            FormatAsJson = Json.Document(GetJson[Value]),
            AccessToken = FormatAsJson[access_token],
            AccessTokenHeader = "bearer " & AccessToken
        in
            AccessTokenHeader,

        // helper function for retrieving Commmunity Stream urls
        GetCommunityStreamUrls = (query as nullable text, communityId as nullable text) as table =>
        let
            // read configuration parameters
            resourceUri = ReadFromConfiguration("ResourceUri"),
            tenantId = ReadFromConfiguration("TenantId"),
            apiVersion = ReadFromConfiguration("ApiVersion"),

            // set default parameters from configuration
            query = if query = null then ReadFromConfiguration("CommunityQuery") else query,
            communityId = if communityId = null then ReadFromConfiguration("CommunityId") else communityId,

            // PI Cloud REST API query - window
            dataQuery = "/api/"
                &apiVersion&
                "/Tenants/"
                &tenantId&
                "/Search/Communities/"
                &communityId&
                "/Streams?query="     
                &query,

            // Query PI Cloud REST API
            getJsonQuery = Json.Document(
                Web.Contents(
                    resourceUri,
                    [
                        RelativePath=dataQuery, 
                        Headers=
                        [
                            Authorization=GetToken(), 
                            #"Community-Id"=communityId
                        ]
                    ]
                )
            ),
            tableOfData = Table.FromList(getJsonQuery, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            expandedTableOfData = Table.ExpandRecordColumn(tableOfData, "Column1", {"Self", "Name", "Id"}, {"Self", "Name", "Id"})
        in
            expandedTableOfData,

        // helper function for retrieving Community Stream data
        GetCommunityStream = (communityStreamUrl as nullable text, communityId as nullable text, startIndex as nullable datetime, endIndex as nullable datetime) as table=>
        let
            // read configuration parameters
            resourceUri = ReadFromConfiguration("ResourceUri"),
            tenantId = ReadFromConfiguration("TenantId"),
            namespaceId = ReadFromConfiguration("NamespaceId"),
            apiVersion = ReadFromConfiguration("ApiVersion"),

            // set default parameters from configuration
            communityStreamUrl = if communityStreamUrl = null then ReadFromConfiguration("CommunityStreamUrl") else communityStreamUrl,
            communityId = if communityId = null then ReadFromConfiguration("CommunityId") else communityId,
            startIndex = if startIndex = null then DateTime.FromText(ReadFromConfiguration("StartIndex")) else startIndex,
            endIndex = if endIndex = null then DateTime.FromText(ReadFromConfiguration("EndIndex")) else endIndex,

            // construct community stream data query
            dataQuery = communityStreamUrl&
                "/Data?startIndex="
                &DateTime.ToText(startIndex, "o")&
                "&endIndex="
                &DateTime.ToText(endIndex, "o"),

            getJsonQuery = Json.Document(
                Web.Contents(
                    dataQuery,
                    [
                        Headers=[
                            Authorization=GetToken(), 
                            #"Community-Id"=communityId]
                    ]
                )
            ),
            tableOfData = Table.FromList(getJsonQuery, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            expandedTableofData = Table.ExpandRecordColumn(tableOfData, "Column1", {"Timestamp", "Value"}, {"Timestamp", "Value"}),
            transformTypes = Table.TransformColumnTypes(expandedTableofData,{{"Timestamp", type datetime}}),
            streamId = List.Last(Text.Split(communityStreamUrl, "/")),
            addColumn = Table.AddColumn(transformTypes, "Stream Id", each streamId)
        in
            addColumn,


        communityStreamUrlsTable = GetCommunityStreamUrls(query, communityId),
        communityStreamUrlsList = communityStreamUrlsTable[Self],
        communityStreamData = Table.Combine(List.Transform(communityStreamUrlsList, each GetCommunityStream(_, communityId, startIndex, endIndex))),
        mergedTable = Table.NestedJoin(communityStreamData, {"Stream Id"}, communityStreamUrlsTable, {"Id"}, "Invoked Function", JoinKind.LeftOuter),
        expandedTable = Table.ExpandTableColumn(mergedTable, "Invoked Function", {"Name"}, {"Stream Name"})
in
        expandedTable
