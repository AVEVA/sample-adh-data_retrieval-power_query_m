# OCS Power Query M Data Retrieval Sample

**Version:** 1.0.0

[![Build Status](https://dev.azure.com/osieng/engineering/_apis/build/status/product-readiness/PI-System/osisoft.sample-ocs-data_retrieval-power_query_m?branchName=main)](https://dev.azure.com/osieng/engineering/_build/latest?definitionId=3927&branchName=main)

Built with .NET Framework 5.0


The sample code in this repository demonstrates how to connect to OCS and pull data from either Data Views or Assets using Power Query M. Power Query works with a variety of Microsoft products such as Analysis Services, Excel, and Power BI workbooks. For more information on Power Query M please refer to [Microsoft's documentation](https://docs.microsoft.com/en-us/powerquery-m/).

## Requirements

The sample is configured using the file [appsettings.placeholder.json](ClientCredentialFlow/appsettings.placeholder.json). Before editing, rename this file to `appsettings.json`. This repository's `.gitignore` rules should prevent the file from ever being checked in to any fork or branch, to ensure credentials are not compromised.

Replace the placeholders in the `appsettings.json` file with your Tenant Id, Client Id and Client Secret, Namespace Id, and the current Api Version. Optionally, a default Asset, Data View, start index, end index, and interval can be configured for queries.

## Running the sample

### Prerequisites

- Register a Client Credential client in OCS.
- Replace the placeholders in the `appsettings.json` as mentioned above.

### Using Power BI

1. Open Power BI Desktop
1. Click the *Get data* button in the Data section of the ribbon
1. In the *Get Data* window search for "Blank Query"
1. Select *Blank Query* and click the *Connect* button
1. Click the *Advanced Editor* button in the Query section of the ribbon in the *Power Query Editor*
1. Paste the query from the desired .pq file
1. Click the *Done* button
1. If the .pq file defines a function, fill out the parameters and click the *Invoke* button
1. If GetDataView.pq is being used, the table that is generated will need to be expanded by clicking the expand column button on the *Column1* header
1. Selecting the data type of each column may also be necessary. To do this automatically for all columns, select the *Transform* section of the ribbon, highlight all columns of your table, and click the *Detect Data Type* button in the ribbon under *Any Column*
1. Click *Close & Apply* in the *Home* section of the ribbon

Note: If you are using the Power BI service you will be unable to access the referenced appsettings.json file. Therefore, it will be necessary to modify the provided power query scripts to read the app settings from another source (e.g. [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)). It is not recommended to hard code the app settings directly in the power query scripts as this could pose a security risk.

### Using Excel

1. Open Excel
1. Under the *Data* section of the ribbon, click the *Get Data* button
1. In the dropdown drill down to *From Other Sources* and click *Blank Query*
1. Click the *Advanced Editor* button in the Query section of the ribbon in the *Power Query Editor*
1. Paste the query from the desired .pq file
1. Click the *Done* button
1. If the .pq file defines a function, fill out the parameters and click the *Invoke* button
1. If GetDataView.pq is being used, the table that is generated will need to be expanded by clicking the expand column button on the *Column1* header
1. Selecting the data type of each column may also be necessary. To do this automatically for all columns, select the *Transform* section of the ribbon, highlight all columns of your table, and click the *Detect Data Type* button in the ribbon under *Any Column*
1. Click *Close & Apply* in the *Home* section of the ribbon

## Testing the sample

### Prerequisites for Testing

- .NET 5.0 or later
  - Note: Visual Studio 16.8 or later is required for development against .NET 5.0
- To allow syntax highlighting and intellisense for .pq file in Visual Studio, the [Power Query SDK extension](https://marketplace.visualstudio.com/items?itemName=Dakahn.PowerQuerySDK) will need to be installed.
- Replace the placeholders in the `appsettings.json` as mentioned above.
- Disable M Intellisese in the advanced editor
  1. Open the *Power Query Editor*
  1. Click *File*
  1. Click *Options and settings*
  1. Click *Options*
  1. Select *Power Query Editor*
  1. Uncheck *Enable M Intellisese...*
  1. Click *Ok*

### Running the sample

- Load the .csproj from the OCSPowerQueryTest directory above this in Visual Studio
- Rebuild project
- Open Test Explorer and make sure there are tests showing
- Run the test

Note: Do not touch your mouse or keyboard as the the tests are running since this could interfere with the automated process.

---

For the main AF SDK Custom Calculations Samples landing page [ReadMe](https://github.com/osisoft/OSI-Samples-PI-System/tree/main/docs/AF-SDK-Custom-Calculations-Docs)  
For the main PI System Samples landing page [ReadMe](https://github.com/osisoft/OSI-Samples-PI-System)  
For the main OSIsoft Samples landing page [ReadMe](https://github.com/osisoft/OSI-Samples)