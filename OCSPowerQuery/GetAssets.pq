(query as nullable text, startIndex as nullable datetime, endIndex as nullable datetime, interval as nullable duration) as table =>
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
            authUrlPart1 = resourceUri & "/identity",
            authUrlPart2 = "/connect/token",
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
                        authUrlPart1,
                        [
                            RelativePath = authUrlPart2,
                            Timeout = #duration(0, 0, 30, 0),
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

        // helper function for retrieving Asset Ids
        GetAssetIds = (query as nullable text) as table =>
        let 
            // read configuration parameters
            resourceUri = ReadFromConfiguration("ResourceUri"),
            tenantId = ReadFromConfiguration("TenantId"),
            namespaceId = ReadFromConfiguration("NamespaceId"),
            apiVersion = ReadFromConfiguration("ApiVersion"),

            // set default parameters from configuration
            query = if query = null then ReadFromConfiguration("AssetQuery") else query,

            // PI Cloud REST API query - window
            dataQuery = "/api/"
                &apiVersion&
                "/Tenants/"
                &tenantId&
                "/Namespaces/"
                &namespaceId&
                "/Assets/?query="     
                &query,

            // Query PI Cloud REST API
            GetJsonQuery = Json.Document(
                Web.Contents(
                    resourceUri,
                    [RelativePath=dataQuery, 
                    Headers=[Authorization=GetToken()]
                    ]
                )
            ),
            tableOfIds = Table.FromList(GetJsonQuery, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            expandedTableOfIds = Table.ExpandRecordColumn(tableOfIds, "Column1", {"Id"}, {"Column1.Id"})
        in
            expandedTableOfIds,

        // helper function for retrieving Asset data
        GetAsset = (assetId as nullable text, startIndex as nullable datetime, endIndex as nullable datetime, interval as nullable duration) as table =>
        let
            // read configuration parameters
            resourceUri = ReadFromConfiguration("ResourceUri"),
            tenantId = ReadFromConfiguration("TenantId"),
            namespaceId = ReadFromConfiguration("NamespaceId"),
            apiVersion = ReadFromConfiguration("ApiVersion"),

            // set default parameters from configuration
            assetId = if assetId = null then ReadFromConfiguration("AssetId") else assetId,
            startIndex = if startIndex = null then DateTime.FromText(ReadFromConfiguration("StartIndex")) else startIndex,
            endIndex = if endIndex = null then DateTime.FromText(ReadFromConfiguration("EndIndex")) else endIndex,
            interval = if interval = null then Duration.FromText(ReadFromConfiguration("Interval")) else interval,

            // construct Data View data window query
            dataQuery = "/api/"
                &apiVersion&
                "/Tenants/"
                &tenantId&
                "/Namespaces/"
                &namespaceId&
                "/Assets/"
                &assetId&
                "/Data?startIndex="
                &DateTime.ToText(startIndex, "o")&
                "&endIndex="
                &DateTime.ToText(endIndex, "o"),

            getJsonQuery = Json.Document(
                Web.Contents(
                    resourceUri,
                    [RelativePath=dataQuery, 
                    Headers=[Authorization=GetToken()]
                    ]
                )
            ),
            Results = getJsonQuery[Results],
            tableOfData = Record.ToTable(Results),
            expandedTableofData1 = Table.ExpandListColumn(tableOfData, "Value"),
            expandedTableofData2 = Table.ExpandRecordColumn(expandedTableofData1, "Value", {"Timestamp", "Value"}, {"Value.Timestamp", "Value.Value"})
        in
            expandedTableofData2,

        Source = GetAssetIds(query),
        assetIds = Source[Column1.Id],
        results = Table.Combine(List.Transform(assetIds, each GetAsset(_, startIndex, endIndex, interval)))
    in
        results