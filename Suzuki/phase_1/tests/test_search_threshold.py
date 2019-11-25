import unittest

import pandas as pd

from modeling.search_threshold import search_threshold


class TestSearchThreshold(unittest.TestCase):

    def test_search_threshold(self):
        df = pd.DataFrame({
            'feature1': [1, 2, 2, 3, 4, 5, 6],
            'feature2': [0, 2, 2, 2, 1, 1, 3],
            'target': ['hoge', 'hige', 'foo', 'foo', 'foo', 'hige', 'foo'],
        })
        target = 'foo'
        features = ['feature1: Y', 'feature2: N']
        result = search_threshold(df, target, features)
        self.assertEqual([1, 1], result['thresholds'])
        self.assertAlmostEqual(4 / 7, result['average_response'])
        self.assertAlmostEqual(0.5, result['target_response'])
        self.assertAlmostEqual(7 / 8, result['lift'])
        self.assertEqual(2, result['n_pattern'])
