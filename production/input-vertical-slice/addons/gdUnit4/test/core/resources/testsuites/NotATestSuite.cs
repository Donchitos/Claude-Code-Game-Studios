namespace GdUnit4.Tests.Resources;
#if GDUNIT4NET_API_V5
using static Assertions;

// will be ignored because of missing `[TestSuite]` anotation
public class NotATestSuite
{
    [TestCase]
    public void TestFoo() => AssertBool(true).IsEqual(false);
}

#endif
