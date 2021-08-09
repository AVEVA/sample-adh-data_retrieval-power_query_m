using FlaUI.Core.AutomationElements;
using FlaUI.Core.Definitions;
using FlaUI.Core.Tools;
using FlaUI.UIA3;
using System;
using System.IO;
using System.Threading;
using Xunit;

namespace OCSPowerQueryTest
{
    public class UnitTests
    {
        [Fact]
        public void GetDataViewTest()
        {
            Assert.True(testPowerQueryFunction("GetDataView.pq"));
        }

        [Fact]
        public void GetAssetTest()
        {
            Assert.True(testPowerQueryFunction("GetAsset.pq"));
        }

        /// <summary>
        /// This function opens Power BI Desktop and executes the provided power query file
        /// </summary>
        /// <param powerQueryFile>The power query file to test</param>
        /// <returns>true if successful</returns>
        private static bool testPowerQueryFunction(string powerQueryFile)
        {
            bool success = false;

            // Read in power query script to run
            var pqScript = "";
            try
            {
                using (var sr = new StreamReader(powerQueryFile))
                {
                    pqScript = sr.ReadToEnd();
                }

                // Replace placeholder with configuration path
                pqScript = pqScript.Replace("PATH_TO_CONFIG", $"{Directory.GetCurrentDirectory()}/appsettings.json");
            }
            catch (IOException e)
            {
                Console.WriteLine("The file could not be read:");
                Console.WriteLine(e.Message);
            }

            using (var automation = new UIA3Automation())
            {
                using (var app = FlaUI.Core.Application.Launch(@"C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"))
                {
                    app.WaitWhileMainHandleIsMissing();
                    var window = app.GetMainWindow(automation);
                    var desktop = window.Parent;

                    try 
                    {
                        // Close the start window
                        var koStart = WaitForElement(() => window.FindFirstChild(cf => cf.ByAutomationId("KoStartDialog")));
                        var getDataButton = WaitForElement(() => koStart.FindFirstDescendant(cf => cf.ByName("Get data"))?.AsButton());
                        getDataButton?.Invoke();

                        // Select Blank Query
                        var dataSource = WaitForElement(() => window.FindFirstDescendant(cf => cf.ByAutomationId("DataSourceGalleryDialog")));
                        var searchBar = WaitForElement(() => dataSource.FindFirstDescendant(cf => cf.ByName("Search")));
                        searchBar.AsTextBox().Text = "Blank Query";
                        var blankQueryListItem = WaitForElement(() => dataSource.FindFirstDescendant(cf => cf.ByName("Blank Query"))?.AsListBoxItem());
                        blankQueryListItem?.WaitUntilClickable(TimeSpan.FromSeconds(30));
                        blankQueryListItem?.Click();
                        var connectButton = dataSource.FindFirstDescendant(cf => cf.ByName("Connect"))?.AsButton();
                        connectButton?.Invoke();

                        // Get the power query editor window
                        var queryEditor = WaitForElement(() => desktop.FindFirstChild(cf => cf.ByAutomationId("QueriesEditorWindow")));

                        // Open the advanced editor
                        var advancedEditorButton = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByName("Advanced Editor"))?.AsButton());
                        advancedEditorButton?.Invoke();

                        // Get the advanced editor window
                        var advancedEditor = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByAutomationId("ViewFormulaDialog")));

                        // Copy script into the advanced editor text field
                        var advancedEditorEdit = WaitForElement(() => advancedEditor.FindFirstDescendant(cf => cf.ByControlType(ControlType.Edit))?.AsTextBox());
                        advancedEditorEdit.Text = $"{pqScript}";
                        var doneButton = WaitForElement(() => advancedEditor.FindFirstDescendant(cf => cf.ByName("Done"))?.AsButton());
                        doneButton?.Invoke();

                        // Invoke the power query function
                        var invokeButton = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByName("Invoke"))?.AsButton());
                        invokeButton?.Invoke();

                        // Complete data privacy question
                        var continueButton = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByName("Continue"))?.AsButton());
                        continueButton?.Invoke();
                        var privacyLevels = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByAutomationId("FirewallDialog")));
                        var checkBox = WaitForElement(() => privacyLevels.FindFirstDescendant(cf => cf.ByControlType(ControlType.CheckBox))?.AsCheckBox());
                        checkBox?.Click();
                        var saveButton = privacyLevels.FindFirstDescendant(cf => cf.ByName("Save"))?.AsButton();
                        saveButton?.Invoke();

                        // Check if the query was successful
                        var dataGrid = WaitForElement(() => queryEditor.FindFirstDescendant(cf => cf.ByControlType(ControlType.DataGrid)));
                        success = dataGrid != null;
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine("An error occurred while testing the provided power query script:");
                        Console.WriteLine(e.Message);
                    }

                    app.Close();
                }
            }

            return success;
        }

        /// <summary>
        /// This is a helper function to allow time for elements to load by continuously trying to retrieve said element
        /// </summary>
        /// <param getter>The getter function to retry until the timeout window is surpassed</param>
        /// <returns>The final result returned by RetryResult</returns>
        private static T WaitForElement<T>(Func<T> getter)
        {
            RetryResult<T> retry;
            var count = 0;
            do
            {
                retry = Retry.WhileNull<T>(
                    () => getter(),
                    TimeSpan.FromSeconds(5*count), null, false, true);

                count++;
            } while (!retry.Success && count < 4);

            if (!retry.Success)
            {
                throw new Exception($"Timeout exceeded for function {getter}");
            }

            return retry.Result;
        }

    }
}
