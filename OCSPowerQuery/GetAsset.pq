(assetId as nullable text, startIndex as nullable datetime, endIndex as nullable datetime, interval as nullable duration) as table =>
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
            clientId = ReadFromConfiguration("clientId"),
            clientSecret = ReadFromConfiguration("clientSecret"),
            resourceUri = ReadFromConfiguration("resourceUri"),
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
            // Authentiate
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

        // read configuration parameters
        resourceUri = ReadFromConfiguration("resourceUri"),
        tenantId = ReadFromConfiguration("tenantId"),
        namespaceId = ReadFromConfiguration("namespaceId"),
        apiVersion = ReadFromConfiguration("apiVersion"),

        // set default parameters from configuration
        assetId = if assetId = null then ReadFromConfiguration("assetId") else assetId,
        startIndex = if startIndex = null then DateTime.FromText(ReadFromConfiguration("startIndex")) else startIndex,
        endIndex = if endIndex = null then DateTime.FromText(ReadFromConfiguration("endIndex")) else endIndex,
        interval = if interval = null then Duration.FromText(ReadFromConfiguration("interval")) else interval,

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
            &DateTime.ToText(startIndex, "yyyy-MM-ddThh:mm:ssZ")&
            "&endIndex="
            &DateTime.ToText(endIndex, "yyyy-MM-ddThh:mm:ssZ"),

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
    expandedTableofData2