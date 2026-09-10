namespace gdUnit4.addons.gdUnit4.test.core.discovery.resources;
#if GDUNIT4NET_API_V5
using GdUnit4;

using static GdUnit4.Assertions;

[TestSuite]
public class DiscoverExampleTestSuite
{
    [TestCase]
    public void TestCase1()
        => AssertBool(true).IsEqual(true);

    [TestCase]
    public void TestCase2()
        => AssertBool(false).IsEqual(false);
}
#endif
