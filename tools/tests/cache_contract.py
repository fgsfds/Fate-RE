"""Common cache guarantees, exercised through each real driver's adapter.

Adapters implement cache_build(clean), cache_fail(), and cache_assert_invalid().
Implementation-specific dependency, corruption, and snapshot tests stay local.
"""


class CompilerCacheContract:
    def test_clean_build_bypasses_cached_success(self):
        count = self.cache_build(clean=True)
        self.assertGreater(count, 0)
        self.assertEqual(self.cache_build(clean=False), 0)
        self.assertEqual(self.cache_build(clean=True), count)

    def test_failed_rebuild_cannot_inherit_success(self):
        self.cache_build(clean=False)
        self.cache_fail()
        with self.assertRaises(ValueError):
            self.cache_build(clean=True)
        self.cache_assert_invalid()
