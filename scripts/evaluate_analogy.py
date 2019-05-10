from glob import glob
import json
from multiprocessing import Pool
import re

from gensim.models import KeyedVectors
from tqdm import tqdm

REGEX_DIRNAME = re.compile(r'^models/(?P<language>..)/(?P<method>.*)$')
REGEX_SYNTACTIC = re.compile(r'^gram[0-9]*-.*$')
FILENAMES = {
    'en': 'data/english_analogy/google_analogy_words.txt',
    'de': 'data/german_analogy/de_trans_Google_analogies.txt',
    'it': 'data/italian_analogy/questions-words-ITA.txt',
    'cs': 'data/czech_analogy/czech_emb_corpus_no_phrase.txt',
}

def evaluate(dirname):
    dirname_match = REGEX_DIRNAME.match(dirname)
    assert dirname_match

    language = dirname_match.group('language')
    method = dirname_match.group('method')

    vectors = KeyedVectors.load_word2vec_format('{}/100/32b_300d_vectors_e5-5.vec'.format(dirname))
    semantic_correct, semantic_total, syntactic_correct, syntactic_total = 0, 0, 0, 0
    _, sections = vectors.evaluate_word_analogies(FILENAMES[language], restrict_vocab=200000, dummy4unknown=False)
    for section in sections:
        if section['section'] == 'Total accuracy':
            continue
        if REGEX_SYNTACTIC.match(section['section']):
            syntactic_correct += len(section['correct'])
            syntactic_total += len(section['correct']) + len(section['incorrect'])
        else:
            semantic_correct += len(section['correct'])
            semantic_total += len(section['correct']) + len(section['incorrect'])
    assert syntactic_total > 0
    assert syntactic_correct <= syntactic_total
    assert semantic_total > 0
    assert semantic_correct <= semantic_total

    syntactic_accuracy = float(syntactic_correct) / float(syntactic_total) * 100.0
    semantic_accuracy = float(semantic_correct) / float(semantic_total) * 100.0
    total_accuracy = float(syntactic_correct + semantic_correct) / float(syntactic_total + semantic_total) * 100.0
    return (language, method, syntactic_accuracy, semantic_accuracy, total_accuracy)

dirnames = []
for dirname in glob('models/*/*'):
    dirname_match = REGEX_DIRNAME.match(dirname)
    assert dirname_match

    language = dirname_match.group('language')
    method = dirname_match.group('method')

    if language in FILENAMES.keys():
        dirnames.append(dirname)

accuracies = {}
with Pool(None) as pool:
    for language, method, syntactic_accuracy, semantic_accuracy, total_accuracy in tqdm(pool.imap_unordered(evaluate, dirnames), total=len(dirnames)):
        if language not in accuracies:
            accuracies[language] = {
                'syntactic': {},
                'semantic': {},
                'total': {},
            }
        accuracies[language]['syntactic'][method] = syntactic_accuracy
        accuracies[language]['semantic'][method] = semantic_accuracy
        accuracies[language]['total'][method] = total_accuracy

print(json.dumps(accuracies, sort_keys=True, indent=4))
