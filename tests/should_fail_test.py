import unittest

class TestShouldFail(unittest.TestCase):

    def test_non_equal(self):
        self.assertEqual([], 'a')

    def test_false(self):
        self.assertFalse(True)

if __name__ == '__main__':
    unittest.main()
