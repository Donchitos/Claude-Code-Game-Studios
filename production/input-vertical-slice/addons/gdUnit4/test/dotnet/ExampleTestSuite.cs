// GdUnit generated TestSuite
namespace gdUnit4.addons.gdUnit4.test.dotnet;

#if GDUNIT4NET_API_V5
using GdUnit4;

using Godot;

using static GdUnit4.Assertions;

[TestSuite]
[RequireGodotRuntime]
public class ExampleTestSuite
{
    [TestCase]
    public void IsFoo() => AssertThat("Foo").IsEqual("Foo");

    [TestCase('A', Variant.Type.Int)]
    [TestCase(sbyte.MaxValue, Variant.Type.Int)]
    [TestCase(byte.MaxValue, Variant.Type.Int)]
    [TestCase(short.MaxValue, Variant.Type.Int)]
    [TestCase(ushort.MaxValue, Variant.Type.Int)]
    [TestCase(int.MaxValue, Variant.Type.Int)]
    [TestCase(uint.MaxValue, Variant.Type.Int)]
    [TestCase(long.MaxValue, Variant.Type.Int)]
    [TestCase(ulong.MaxValue, Variant.Type.Int)]
    [TestCase(float.MaxValue, Variant.Type.Float)]
    [TestCase(double.MaxValue, Variant.Type.Float)]
    [TestCase("HalloWorld", Variant.Type.String)]
    [TestCase(true, Variant.Type.Bool)]
    public void ParameterizedTest(dynamic? value, Variant.Type type)
    {
        Variant v = value == null ? new Variant() : Variant.CreateFrom(value);
        AssertObject(v.VariantType).IsEqual(type);
    }
}
#endif
