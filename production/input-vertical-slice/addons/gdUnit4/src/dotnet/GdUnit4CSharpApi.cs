// Copyright (c) 2025 Mike Schulze
// MIT License - See LICENSE file in the repository root for full license text
#pragma warning disable IDE1006
namespace gdUnit4.addons.gdUnit4.src.dotnet;
#pragma warning restore IDE1006

#if GDUNIT4NET_API_V5
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

using GdUnit4;
using GdUnit4.Api;

using Godot;
using Godot.Collections;

/// <summary>
///     The GdUnit4 GDScript - C# API wrapper.
/// </summary>
public partial class GdUnit4CSharpApi : RefCounted
{
    /// <summary>
    ///     The signal to be emitted when the execution is completed.
    /// </summary>
    [Signal]
#pragma warning disable CA1711
    public delegate void ExecutionCompletedEventHandler();
#pragma warning restore CA1711

#pragma warning disable CA2213, SA1201
    private CancellationTokenSource? executionCts;
#pragma warning restore CA2213, SA1201

    /// <summary>
    ///     Indicates if the API loaded.
    /// </summary>
    /// <returns>Returns true if the API already loaded.</returns>
    public static bool IsApiLoaded()
        => true;

    /// <summary>
    ///     Runs test discovery on the given script.
    /// </summary>
    /// <param name="sourceScript">The script to be scanned.</param>
    /// <returns>The list of tests discovered as dictionary.</returns>
    public static Array<Dictionary> DiscoverTests(CSharpScript sourceScript)
    {
        try
        {
            // Get the list of test case descriptors from the API
            var testCaseDescriptors = GdUnit4NetApiGodotBridge.DiscoverTestsFromScript(sourceScript);

            // Convert each TestCaseDescriptor to a Dictionary
            return testCaseDescriptors
                .Select(descriptor => new Dictionary
                {
                    ["guid"] = descriptor.Id.ToString(),
                    ["managed_type"] = descriptor.ManagedType,
                    ["test_name"] = descriptor.ManagedMethod,
                    ["source_file"] = sourceScript.ResourcePath,
                    ["line_number"] = descriptor.LineNumber,
                    ["attribute_index"] = descriptor.AttributeIndex,
                    ["require_godot_runtime"] = descriptor.RequireRunningGodotEngine,
                    ["code_file_path"] = descriptor.CodeFilePath ?? string.Empty,
                    ["simple_name"] = descriptor.SimpleName,
                    ["fully_qualified_name"] = descriptor.FullyQualifiedName,
                    ["assembly_location"] = descriptor.AssemblyPath
                })
                .Aggregate(
                    new Array<Dictionary>(),
                    (array, dict) =>
                        {
                            array.Add(dict);
                            return array;
                        });
        }
#pragma warning disable CA1031
        catch (Exception e)
#pragma warning restore CA1031
        {
            GD.PrintErr($"Error discovering tests: {e.Message}\n{e.StackTrace}");
#pragma warning disable IDE0028 // Do not catch general exception types
            return new Array<Dictionary>();
#pragma warning restore IDE0028 // Do not catch general exception types
        }
    }

    /// <summary>
    /// Creates a test suite based on the specified source path and line number.
    /// </summary>
    /// <param name="sourcePath">The path to the source file from which to create the test suite.</param>
    /// <param name="lineNumber">The line number in the source file where the method to test is defined.</param>
    /// <param name="testSuitePath">The path where the test suite should be created.</param>
    /// <returns>A dictionary containing information about the created test suite.</returns>
    public static Dictionary CreateTestSuite(string sourcePath, int lineNumber, string testSuitePath)
        => GdUnit4NetApiGodotBridge.CreateTestSuite(sourcePath, lineNumber, testSuitePath);

    /// <summary>
    /// Gets the version of the GdUnit4 assembly.
    /// </summary>
    /// <returns>The version string of the GdUnit4 assembly.</returns>
    public static string Version()
        => GdUnit4NetApiGodotBridge.Version();

    /// <inheritdoc />
    public override void _Notification(int what)
    {
        if (what != NotificationPredelete)
            return;
        executionCts?.Dispose();
        executionCts = null;
    }

    /// <summary>
    ///     Executes the tests and using the listener for reporting the results.
    /// </summary>
    /// <param name="tests">A list of tests to be executed.</param>
    /// <param name="listener">The listener to report the results.</param>
    public void ExecuteAsync(Array<Dictionary> tests, Callable listener)
    {
        try
        {
            // Cancel any ongoing execution
            executionCts?.Cancel();
            executionCts?.Dispose();

            // Create new cancellation token source
            executionCts = new CancellationTokenSource();

            Debug.Assert(tests != null, nameof(tests) + " != null");
            var testSuiteNodes = new List<TestSuiteNode> { BuildTestSuiteNodeFrom(tests) };
            GdUnit4NetApiGodotBridge.ExecuteAsync(testSuiteNodes, listener, executionCts.Token)
                .GetAwaiter()
                .OnCompleted(() => EmitSignal(SignalName.ExecutionCompleted));
        }
#pragma warning disable CA1031
        catch (Exception e)
#pragma warning restore CA1031
        {
            GD.PrintErr($"Error executing tests: {e.Message}\n{e.StackTrace}");
            Task.Run(() => { }).GetAwaiter().OnCompleted(() => EmitSignal(SignalName.ExecutionCompleted));
        }
    }

    /// <summary>
    ///     Will cancel the current test execution.
    /// </summary>
    public void CancelExecution()
    {
        try
        {
            executionCts?.Cancel();
        }
#pragma warning disable CA1031
        catch (Exception e)
#pragma warning restore CA1031
        {
            GD.PrintErr($"Error cancelling execution: {e.Message}");
        }
    }

    // Convert a set of Tests stored as Dictionaries to TestSuiteNode
    // all tests are assigned to a single test suit
    internal static TestSuiteNode BuildTestSuiteNodeFrom(Array<Dictionary> tests)
    {
        if (tests.Count == 0)
            throw new InvalidOperationException("Cant build 'TestSuiteNode' from an empty test set.");

        // Create a suite ID
        var suiteId = Guid.NewGuid();
        var firstTest = tests[0];
        var managedType = firstTest["managed_type"].AsString();
        var assemblyLocation = firstTest["assembly_location"].AsString();
        var sourceFile = firstTest["source_file"].AsString();

        // Create TestCaseNodes for each test in the suite
        var testCaseNodes = tests
            .Select(test => new TestCaseNode
            {
                Id = Guid.Parse(test["guid"].AsString()),
                ParentId = suiteId,
                ManagedMethod = test["test_name"].AsString(),
                LineNumber = test["line_number"].AsInt32(),
                AttributeIndex = test["attribute_index"].AsInt32(),
                RequireRunningGodotEngine = test["require_godot_runtime"].AsBool()
            })
            .ToList();

        return new TestSuiteNode
        {
            Id = suiteId,
            ParentId = Guid.Empty,
            ManagedType = managedType,
            AssemblyPath = assemblyLocation,
            SourceFile = sourceFile,
            Tests = testCaseNodes
        };
    }
}
#else
using Godot;
using Godot.Collections;

public partial class GdUnit4CSharpApi : RefCounted
{
	[Signal]
	public delegate void ExecutionCompletedEventHandler();

	public static bool IsApiLoaded()
	{
		GD.PushWarning("No `gdunit4.api` dependency found, check your project dependencies.");
		return false;
	}


	public static string Version()
		=> "Unknown";

	public static Array<Dictionary> DiscoverTests(CSharpScript sourceScript) => new();

	public void ExecuteAsync(Array<Dictionary> tests, Callable listener)
	{
	}

	public static bool IsTestSuite(CSharpScript script)
		=> false;

	public static Dictionary CreateTestSuite(string sourcePath, int lineNumber, string testSuitePath)
		=> new();
}
#endif
