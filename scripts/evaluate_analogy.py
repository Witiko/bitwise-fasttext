from glob import glob
import json
import re

REGEX_FILENAME = re.compile(
    r'^models/(?P<language>..)/(?P<method>.*)/100/32b_300d_vectors_e5-5_accuracy-(?P<function>.*)\.log$'
)
REGEX_ACCURACIES = re.compile(
    r'^Total accuracy: (?P<total_accuracy>.*) % *'
    r'Semantic accuracy: (?P<semantic_accuracy>.*) % *'
    r'Syntactic accuracy: (?P<syntactic_accuracy>.*) % *$'
)
REGEX_ARITHMETIC_DURATION = r'^Solved analogies in (?P<duration>[0-9.]*) seconds$'
REGEX_EVALUTION_DURATION = r'^Evaluated solution in (?P<duration>[0-9.]*) seconds$'
LANGUAGES = set(['en', 'de', 'it', 'cs'])

def get_accuracies(filename):
    with open(filename, 'rt') as f:
        matches = (re.match(REGEX_ACCURACIES, line) for line in f)
        matches = [match for match in matches if match is not None]
    assert matches, 'Failed to find accuracies in {}'.format(filename)

    match = matches[-1]
    semantic_accuracy = float(match.group('semantic_accuracy'))
    syntactic_accuracy = float(match.group('syntactic_accuracy'))
    total_accuracy = float(match.group('total_accuracy'))

    return (semantic_accuracy, syntactic_accuracy, total_accuracy)

def get_durations(filename):
    evaluation_duration_match = None
    arithmetic_duration_match = None
    with open(filename, 'rt') as f:
        for line in f:
            if arithmetic_duration_match is None:
               arithmetic_duration_match = re.match(REGEX_ARITHMETIC_DURATION, line)
            if evaluation_duration_match is None:
               evaluation_duration_match = re.match(REGEX_EVALUTION_DURATION, line)
            if arithmetic_duration_match and evaluation_duration_match:
                break
    assert arithmetic_duration_match, 'Failed to find arithmetic duration in {}'.format(filename)
    assert evaluation_duration_match, 'Failed to find evaluation duration in {}'.format(filename)

    arithmetic_duration = float(arithmetic_duration_match.group('duration'))
    evaluation_duration = float(evaluation_duration_match.group('duration'))
    return (arithmetic_duration, evaluation_duration)

filenames = []
for filename in glob('models/*/*/100/*_accuracy-*.log'):
    filename_match = REGEX_FILENAME.match(filename)
    assert filename_match

    language = filename_match.group('language')
    if language in LANGUAGES:
        filenames.append(filename)

results = {}
for filename in filenames:
    filename_match = REGEX_FILENAME.match(filename)

    language = filename_match.group('language')
    if language not in results:
        results[language] = {}

    method = filename_match.group('method')
    if method not in results[language]:
        results[language][method] = {}

    function = filename_match.group('function')
    assert function not in results[language][method]
    results[language][method][function] = {
        'accuracies': {},
        'durations': {},
    }

    semantic_accuracy, syntactic_accuracy, total_accuracy = get_accuracies(filename)
    results[language][method][function]['accuracies']['semantic'] = semantic_accuracy
    results[language][method][function]['accuracies']['syntactic'] = syntactic_accuracy
    results[language][method][function]['accuracies']['total'] = total_accuracy

    arithmetic_duration, evaluation_duration = get_durations(filename)
    results[language][method][function]['durations']['vector arithmetic'] = arithmetic_duration
    results[language][method][function]['durations']['nearest neighbor'] = evaluation_duration

print(json.dumps(results, sort_keys=True, indent=4))
