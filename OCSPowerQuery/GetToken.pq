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
    AccessTokenHeader