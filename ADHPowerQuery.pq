section ADHPowerQuery;

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

GetStreams = Extension.LoadFunction("GetStreams.pqm");
GetStreamWindowData = Extension.LoadFunction("GetStreamWindowData.pqm");
GetAssets = Extension.LoadFunction("GetAssets.pqm");
GetAssetWindowData = Extension.LoadFunction("GetAssetWindowData.pqm");
GetCommunityStreamSearch = Extension.LoadFunction("GetCommunityStreamSearch.pqm");
GetCommunityStreamWindowData = Extension.LoadFunction("GetCommunityStreamWindowData.pqm");
GetDataViewInterpolatedData = Extension.LoadFunction("GetDataViewInterpolatedData.pqm");
GetDataViewStoredData = Extension.LoadFunction("GetDataViewStoredData.pqm");
GraphQLQuery = Extension.LoadFunction("GraphQLQuery.pqm");
GetToken = Extension.LoadFunction("GetToken.pqm");

TryRetrieveParameterFromAppsettings = (configurationParameter as text) =>
    let
        result =
            try
                Record.Field(Json.Document(Extension.Contents("appsettings.json")), configurationParameter)
            otherwise
                error
                    Error.Record(
                        Extension.LoadString("ErrorInvalidConfigurationParameterReason"),
                        Extension.LoadString("ErrorInvalidConfigurationParameterMessage") & configurationParameter
                    )
    in
        result;

resource = TryRetrieveParameterFromAppsettings("Resource");
apiVersion = TryRetrieveParameterFromAppsettings("ApiVersion");
tenantId = TryRetrieveParameterFromAppsettings("TenantId");
namespaceId = TryRetrieveParameterFromAppsettings("NamespaceId");
communityId = TryRetrieveParameterFromAppsettings("CommunityId");
clientId = TryRetrieveParameterFromAppsettings("ClientId");
clientSecret = TryRetrieveParameterFromAppsettings("ClientSecret");

streamId = TryRetrieveParameterFromAppsettings("StreamId");
assetId = TryRetrieveParameterFromAppsettings("AssetId");
communityStreamUrl = TryRetrieveParameterFromAppsettings("CommunityStreamUrl");
dataViewId = TryRetrieveParameterFromAppsettings("DataViewId");

token = GetToken(resource, clientId, clientSecret);

CreateNavTable = () =>
    let
        objects = #table(
            {"Name", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {
                    "GetStreams",
                    GetStreams(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        "*"
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetStreamWindowData",
                    GetStreamWindowData(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        streamId,
                        #datetime(2020, 3, 10, 0, 0, 0),
                        #datetime(2020, 3, 11, 0, 0, 0)
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetAssets",
                    GetAssets(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        "*"
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetAssetWindowData",
                    GetAssetWindowData(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        assetId,
                        #datetime(2020, 3, 10, 0, 0, 0),
                        #datetime(2020, 3, 11, 0, 0, 0)
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetCommunityStreamSearch",
                    GetCommunityStreamSearch(
                        token,
                        resource,
                        apiVersion,
                        communityId,
                        "*"
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetCommunityStreamWindowData",
                    GetCommunityStreamWindowData(
                        token,
                        communityStreamUrl,
                        communityId,
                        #datetime(2020, 3, 10, 0, 0, 0),
                        #datetime(2020, 3, 11, 0, 0, 0)
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetDataViewInterpolatedData",
                    GetDataViewInterpolatedData(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        dataViewId,
                        #datetime(2020, 3, 10, 0, 0, 0),
                        #datetime(2020, 3, 11, 0, 0, 0),
                        #duration(0, 1, 0, 0)
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GetDataViewStoredData",
                    GetDataViewStoredData(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        dataViewId,
                        #datetime(2020, 3, 10, 0, 0, 0),
                        #datetime(2020, 3, 11, 0, 0, 0)
                    ),
                    "Table",
                    "Table",
                    true
                },
                {
                    "GraphQLQuery",
                    GraphQLQuery(
                        token,
                        resource,
                        apiVersion,
                        tenantId,
                        namespaceId,
                        "{ assets { queryAsset { id } } }"
                    ),
                    "Table",
                    "Table",
                    true
                }
            }
        ),
        NavTable = Table.ToNavigationTable(objects, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable;

[DataSource.Kind = "ADHPowerQuery", Publish = "ADHPowerQuery.Publish"]
shared ADHPowerQuery.Contents = CreateNavTable;

ADHPowerQuery = [
    Authentication = [
        Anonymous = []
    ]
];

ADHPowerQuery.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = {"Data Hub sample", "Data Hub sample"}
];

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;
