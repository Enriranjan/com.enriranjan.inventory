using NUnit.Framework;

namespace EnriRanjan.__PACKAGE_NAME__.Tests
{
    /// <summary>
    /// Plain NUnit tests for the noEngineReferences runtime assembly.
    /// No UnityTest / coroutines here on purpose: code under
    /// EnriRanjan.__PACKAGE_NAME__ must stay engine-free and testable with
    /// pure NUnit, without needing PlayMode.
    /// </summary>
    public class RuntimePlaceholderTests
    {
        [Test]
        public void RuntimePlaceholder_CanBeConstructed()
        {
            var instance = new RuntimePlaceholder();

            Assert.IsNotNull(instance);
        }
    }
}
