# ADH Power Query M Data Retrieval Sample

**Version:** 2.0.0

Built with [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk) in [Visual Studio Code](https://code.visualstudio.com/)


The sample code in this repository demonstrates how to connect to ADH and pull data from Streams, Assets, and Data Views using Power Query M. Power Query works with a variety of Microsoft products such as Analysis Services, Excel, and Power BI workbooks. For more information on Power Query M please refer to [Microsoft's documentation](https://docs.microsoft.com/en-us/powerquery-m/).

## Requirements

- [Power BI Desktop](https://powerbi.microsoft.com/en-us/desktop/)
- Register a [Client-Credentials Client](https://datahub.connect.aveva.com/clients) in your AVEVA Data Hub tenant and create a client secret to use in the configuration of this sample. ([Video Walkthrough](https://www.youtube.com/watch?v=JPWy0ZX9niU))
  - __NOTE__: This sample only requires read access to resources (Streams, Assets, etc.) to run successfully
  - It is strongly advised to not elevate the permissions of a client beyond what is necessary.

## Setting up Power BI

1. Open Power BI Desktop.
1. Click the **Get data** button in the Data section of the ribbon.
1. In the **Get Data** window search for "Blank Query".
1. Select **Blank Query** and click the **Connect** button.
1. Click the **Advanced Editor** button in the Query section of the ribbon in the **Power Query Editor**.
1. Paste the query from the desired .pqm file. See the [Power Query Functions](#power-query-functions) section below for descriptions of each provided function.
1. Click the **Done** button.
1. Right click on the function and rename it to match the copied function.
1. Create all functions that will be used.
1. Optionally create parameters for connection information like your Tenant Id by clicking **Manage Parameters** in the Parameters section of ribbon.
1. Use functions in your queries. See the [Using Functions](#using-functions) section below for more information.
1. You may encounter the prompt to "Please specify how to connect." If this occurs, click **Edit Credentials**, select **Anonymous**, and click **Connect**.

Note: It is not recommended to hard code the app settings directly in the power query scripts as this could pose a security risk.

### PowerBI Service Refreshes

If you plan to publish your PowerBI dashboard to the cloud PowerBI service, you may run into an issue where you cannot refresh your Semantic Model and you'll see the error message **"This dataset includes a dynamic data source. Since dynamic data sources aren't refreshed in the Power BI service, this dataset won't be refreshed."** The problem is that when a published dataset is refreshed, Power BI does some static analysis on the code to determine what the data sources for the dataset are and whether the supplied credentials are correct. Unfortunately in some cases, such as when the definition of a data source depends on the parameters from a custom M function, that static analysis fails and therefore the dataset does not refresh. To determine whether your dynamic data source can be refreshed, open the Data source settings dialog in Power Query Editor, and then select Data sources in current file. In the window that appears, look for the warning message, **"Some data sources may not be listed because of hand-authored queries."** In order to work around this issue, you can edit the sample code to replace any usage of the **"resource"** variable within **Web.Contents()** with your data services resource url. 

**For example:**
```C#
GetJson =
    try
                    Web.Contents(
                        "https://euno.datahub.connect.aveva.com/",
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
```

When configuring your scheduled refresh, you should turn on the **“Skip Test Connection”** option on the data source in the Power BI Service and the dataset will refresh even if the call to the CONNECT resource on its own, without the dynamically added client credentials, would result in an error.

## Setting up Excel

1. Open Excel
1. Under the **Data** section of the ribbon, click the **Get Data** button.
1. In the dropdown drill down to **From Other Sources** and click **Blank Query**.
1. Click the **Advanced Editor** button in the Query section of the ribbon in the *Power Query Editor*.
1. Paste the query from the desired .pqm file. See the [Power Query Functions](#power-query-functions) section below for descriptions of each provided function.
1. Click the **Done** button.
1. Right click on the function and rename it to match the copied function.
1. Create all functions that will be used.
1. Optionally create parameters for connection information like your Tenant Id by clicking **Manage Parameters** in the Parameters section of ribbon.
1. Use functions in your queries. See the [Using Functions](#using-functions) section below for more information.
1. You may encounter the prompt to "Please specify how to connect." If this occurs, click **Edit Credentials**, select **Anonymous**, and click **Connect**.

Note: It is not recommended to hard code the app settings directly in the power query scripts as this could pose a security risk.

## Using Functions

The provided functions can be chained together in your queries to meet your needs. Every function (besides GetToken) requires a token for authorization to resources so you will usually start by generating one using GetToken. This pattern can be seen in the following example:

```C#
let
    token = GetToken(Resource, ClientId, ClientSecret),
    data = GetStreamWindowData(token, Resource, ApiVersion, TenantId, NamespaceId, "SLTC.SensorUnit1.TMP117", #datetime(2023, 5, 28, 0, 0, 0), #datetime(2023, 5, 29, 0, 0, 0)),
    expandedData = Table.ExpandRecordColumn(data, "Column1", {"Timestamp", "Temperature"}, {"Timestamp", "Temperature"})
in
    expandedData
```

The generated token can also be used for subsequent calls so long as it has not expired (tokens expire after 1 hour by default).

Functions can also be chained together to accomplish more complex tasks like retrieving data from a set of streams returned by a query. An example of this can be seen below:

```C#
let
    token = GetToken(Resource, ClientId, ClientSecret),
    streams = GetStreams(token, Resource, ApiVersion, TenantId, NamespaceId, "SLTC.SensorUnit1.TMP117 OR SLTC.SensorUnit1.DPS310"),
    streamIds = Table.ToList(Table.SelectColumns(streams,"Id")),
    data = Table.Combine(
        List.Transform(
            streamIds, 
            (streamId) => let 
                result = Table.AddColumn(
                    GetStreamWindowData(
                        token, Resource, ApiVersion, TenantId, NamespaceId, streamId, #datetime(2023, 5, 28, 0, 0, 0), #datetime(2023, 5, 29, 0, 0, 0)
                    ), 
                    "StreamId", 
                    each streamId
                )
            in
                result
        )
    ),
    expandedData = Table.ExpandRecordColumn(data, "Column1", {"Timestamp", "Temperature", "AtmosphericPressure"}, {"Timestamp", "Temperature", "AtmosphericPressure"})
in
    expandedData
```

## Using the Results

After you have made a query, you should be left with a result that looks something like this:

![Power Query Editor Result](images/Power%20Query%20Editor%20Result.png)

To get the result in a format that is useable by Power BI you will need to expand the results. This can be done by clicking the expand icon ![Expand Icon](/images/Expand%20Icon.png) then clicking `Done` or `Expand to New Rows`. This may need to be repeated a few times to fully expand the results.

Once the data is expanded, if necessary, right click on column headers and use the "Change Type" options to assign the proper types, as all fields are treated as strings by default.

At this point, the data should be consumable in a Power BI Dashboard or Excel Workbook!

### Power Query Functions

| Function                         | Description                                                                                                                |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| GetToken.pqm                     | Retrieves a token using Client Credentials OAuth flow. Each of the functions below need this function to generate a token. |
| GetStreams.pqm                   | Retrieves Streams based on query.                                                                                          |
| GetStreamWindowData.pqm          | Returns a collection of stored values from a Stream based on request parameters.                                           |
| GetAssets.pqm                    | Retrieves Assets based on query.                                                                                           |
| GetAssetWindowData.pqm           | Returns a collection of stored values from an Asset based on request parameters.                                           |
| GetCommunityStreamSearch.pqm     | Retrieves Streams in a Community based on query.                                                                           |
| GetCommunityStreamWindowData.pqm | Returns a collection of stored values from a Community Stream based on request parameters.                                 |
| GetDataViewInterpolatedData.pqm  | Returns interpolated data for the provided Data View and index parameters.                                                 |
| GetDataViewStoredData.pqm        | Returns stored data for the provided Data View and index parameters.                                                       |
| GetGraphQLQuery.pqm              | Submit a GraphQL query to AVEVA Data Hub.                                                                                  |

## Running Tests

1. Open Visual Studio Code with the Power Query SDK installed.
1. Open the sample folder.
1. Rename [appsettings.placeholder.json](appsettings.placeholder.json) file to `appsettings.json`.
1. Replace the placeholders in the `appsettings.json` file with your connection information and resources (Streams, Assets, etc.).
1. Set a credential. See [Microsoft's documentation](https://learn.microsoft.com/en-us/power-query/power-query-sdk-vs-code#set-credential) for more information.
1. Evaluate `DataHubGraphQLConnector.query.pq`. See [Microsoft's documentation](https://learn.microsoft.com/en-us/power-query/power-query-sdk-vs-code#evaluate-a-query-and-the-results-panel) for more information.

---

For the main ADH samples page [ReadMe](https://github.com/osisoft/OSI-Samples-OCS)  
For the main AVEVA samples page [ReadMe](https://github.com/osisoft/OSI-Samples)
