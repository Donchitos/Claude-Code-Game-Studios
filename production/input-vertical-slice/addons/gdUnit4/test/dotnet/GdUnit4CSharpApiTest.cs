#if GDUNIT4NET_API_V5
namespace gdUnit4.addons.gdUnit4.test.dotnet;

using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Threading.Tasks;

using GdUnit4;

using Godot;
using Godot.Collections;

using src.dotnet;

using static GdUnit4.Assertions;

[TestSuite]
[RequireGodotRuntime]
public partial class GdUnit4CSharpApiTest
{
    [TestCase]
    public void GetVersion()
    {
        var version = long.Parse(GdUnit4CSharpApi.Version().Replace(".", string.Empty, StringComparison.Ordinal));
        AssertThat(version).IsGreaterEqual(423);
    }

    [TestCase]
    [SuppressMessage("Reliability", "CA2000:Dispose objects before losing scope")]
    public void DiscoverTestsFromScript()
    {
        var script = GD.Load<CSharpScript>("res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs");
        var fullScriptPath = Path.GetFullPath(ProjectSettings.GlobalizePath(script.ResourcePath));
        var tests = GdUnit4CSharpApi.DiscoverTests(script);

        // Filter out the Guid from each test dictionary before comparing
        var testsWithoutGuids = tests.Select(dict =>
        {
            // Verify id contains the Guid and the assembly location
            AssertThat(dict).ContainsKeys("guid", "assembly_location");
            AssertThat(dict["assembly_location"].AsString()).Contains("gdUnit4.dll");
            var newDict = new Dictionary();
            newDict.Merge(dict);
            newDict.Remove("guid");
            newDict.Remove("assembly_location");
            return newDict;
        }).ToArray();

        AssertThat(testsWithoutGuids).HasSize(14)
            // Check for single test `IsFoo`
            .Contains(
                new Dictionary
                {
                    ["test_name"] = "IsFoo",
                    ["source_file"] = "res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs",
                    ["line_number"] = 16,
                    ["attribute_index"] = 0,
                    ["require_godot_runtime"] = true,
                    ["code_file_path"] = fullScriptPath,
                    ["fully_qualified_name"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite.IsFoo",
                    ["simple_name"] = "IsFoo",
                    ["managed_type"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite"
                },
                // Check exemplary two of the `ParameterizedTest` (index 0, index 11)
                new Dictionary
                {
                    ["test_name"] = "ParameterizedTest",
                    ["source_file"] = "res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs",
                    ["line_number"] = 32,
                    ["attribute_index"] = 0,
                    ["require_godot_runtime"] = true,
                    ["code_file_path"] = fullScriptPath,
                    ["fully_qualified_name"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite.ParameterizedTest.ParameterizedTest:0 (A, 2)",
                    ["simple_name"] = "ParameterizedTest:0 (A, 2)",
                    ["managed_type"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite"
                },
                new Dictionary
                {
                    ["test_name"] = "ParameterizedTest",
                    ["source_file"] = "res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs",
                    ["line_number"] = 32,
                    ["attribute_index"] = 11,
                    ["require_godot_runtime"] = true,
                    ["code_file_path"] = fullScriptPath,
                    ["fully_qualified_name"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite.ParameterizedTest.ParameterizedTest:11 (\"HalloWorld\", 4)",
                    ["simple_name"] = "ParameterizedTest:11 (\"HalloWorld\", 4)",
                    ["managed_type"] = "gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite"
                });
    }

    [TestCase]
    public void BuildTestSuiteNodeFrom()
    {
        var script = GD.Load<CSharpScript>("res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs");
        var tests = GdUnit4CSharpApi.DiscoverTests(script);

        // convert the discovered tests into a test suite node
        var testSuite = GdUnit4CSharpApi.BuildTestSuiteNodeFrom(tests);
        AssertThat(testSuite).IsNotNull();
        AssertThat(testSuite.ManagedType).IsEqual("gdUnit4.addons.gdUnit4.test.dotnet.ExampleTestSuite");
        AssertThat(testSuite.AssemblyPath).EndsWith("gdUnit4.dll");
        AssertThat(testSuite.Tests).HasSize(14);
    }

    [TestCase]
    public async Task ExecuteAsync()
    {
        var script = GD.Load<CSharpScript>("res://addons/gdUnit4/test/dotnet/ExampleTestSuite.cs");
        var tests = GdUnit4CSharpApi.DiscoverTests(script);

        // Create a list to track received events
        var receivedEvents = new List<Dictionary>();

        // Create a TestEventHandler object to handle the events
        using var eventHandler = new TestEventHandler();
        eventHandler.EventReceived += eventData =>
        {
            // Track the event
            receivedEvents.Add(
                new Dictionary
                {
                    ["type"] = eventData["type"],
                    ["guid"] = eventData["guid"],
                    ["suite_name"] = eventData["suite_name"],
                    ["test_name"] = eventData["test_name"]
                });
        };

        // Create a Callable that references the handler method
        var listener = new Callable(eventHandler, nameof(TestEventHandler.PublishEvent));

        using var api = new GdUnit4CSharpApi();
        api.ExecuteAsync(tests, listener);

        // await execution is finished
        await api.ToSignal(api, GdUnit4CSharpApi.SignalName.ExecutionCompleted);

        // tests * 2 (beforeTest and afterTest) + before and after
        var expectedCount = (tests.Count * 2) + 2;
        AssertArray(receivedEvents).HasSize(expectedCount).Contains(
            new Dictionary
            {
                ["type"] = 2, // before
                ["guid"] = "00000000-0000-0000-0000-000000000000",
                ["suite_name"] = "ExampleTestSuite",
                ["test_name"] = "Before"
            },
            new Dictionary
            {
                ["type"] = 3, //  after
                ["guid"] = "00000000-0000-0000-0000-000000000000",
                ["suite_name"] = "ExampleTestSuite",
                ["test_name"] = "After"
            },
            // check exemplary for one test
            new Dictionary
            {
                ["type"] = 4, // beforeTest
                ["guid"] = tests.First()["guid"],
                ["suite_name"] = "ExampleTestSuite",
                ["test_name"] = "IsFoo"
            },
            new Dictionary
            {
                ["type"] = 5, // afterTest
                ["guid"] = tests.First()["guid"],
                ["suite_name"] = "ExampleTestSuite",
                ["test_name"] = "IsFoo"
            });
    }

    // Helper class to handle events
    private sealed partial class TestEventHandler : RefCounted
    {
        // Event to notify when events are received
        public event Action<Dictionary>? EventReceived;

        // Method that will be called by the Callable
        public void PublishEvent(Dictionary eventData)
            => EventReceived?.Invoke(eventData);
    }
}
#endif
