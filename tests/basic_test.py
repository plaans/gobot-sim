import unittest

class BasicTest(unittest.TestCase):

    def test_basic_operations(self):
        self.assertEqual(10, 100/10)
        self.assertTrue(15 >0)
        self.assertFalse('o' in 'abc')

    def test_exception_raise(self):
        with self.assertRaises(IndexError):
            L = ['a', 'b', 'c', 'd', 'e']
            L[5]

if __name__ == '__main__':
    unittest.main()
