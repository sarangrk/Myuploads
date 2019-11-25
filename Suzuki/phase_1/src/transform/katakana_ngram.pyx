import re

import pandas as pd


KATAKANA_PATTERN = re.compile('[ァ-ヴ][ァ-ヴー・]*')


def katakana_ngram(words, ns):
    cdef int i
    cdef int n
    pattern = KATAKANA_PATTERN

    result = []
    katakana_words = []
    for word in words:
        if pattern.match(word):
            katakana_words.append(word)
        else:
            if katakana_words:
                connected = ''.join(katakana_words)
                result.extend([
                    connected[i: i + n]
                    for n in ns
                    # `range()` for negative number results [].
                    for i in range(len(connected) - n + 1)
                ])
                katakana_words.clear()
            result.append(word)
    return pd.Series(result)
