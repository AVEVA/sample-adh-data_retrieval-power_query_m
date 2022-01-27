(dataViewId as nullable text, startIndex as nullable datetime, endIndex as nullable datetime, interval as nullable duration) as table =>
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

        // read configuration parameters
        resourceUri = ReadFromConfiguration("ResourceUri"),
        tenantId = ReadFromConfiguration("TenantId"),
        namespaceId = ReadFromConfiguration("NamespaceId"),
        apiVersion = ReadFromConfiguration("ApiVersion"),

        // set default parameters from configuration
        dataViewId = if dataViewId = null then ReadFromConfiguration("DataViewId") else dataViewId,
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
            "/Dataviews/"
            &dataViewId&
            "/Data/Interpolated?startIndex="
            &DateTime.ToText(startIndex, "o")&
            "&endIndex="
            &DateTime.ToText(endIndex, "o")&
            "&count=250000&interval="
            &Duration.ToText(interval),

        getJsonQuery = Json.Document(
            Web.Contents(
                resourceUri,
                [RelativePath=dataQuery, 
                Headers=[Authorization=GetToken()]
                ]
            )
        ),

        // convert json result to table
        tableOfData = Table.FromList(getJsonQuery, Splitter.SplitByNothing(), null, null, ExtraValues.Error)

    in 
        tableOfData