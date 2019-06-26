from glob import glob
import json
import re

REGEX_FILENAME_ANALOGY = re.compile(r'^.*_accuracy-.*$')
REGEX_BEGINNING = re.compile(r'^.*Progress:.*$')
REGEX_END = re.compile(r'^.*Saving model to file .*$')
REGEX_TIMESTAMP = re.compile(r'^(?P<timestamp>[0-9]*)\t.*$')
REGEX_DIRNAME = re.compile(r'^models/(?P<language>..)/(?P<method>.*)$')

durations = {}
for dirname in glob('models/*/*'):
    dirname_match = REGEX_DIRNAME.match(dirname)
    assert dirname_match

    duration = 0
    for filename in glob('{}/100/32b_300d_vectors_e5-*.log'.format(dirname)):
        if REGEX_FILENAME_ANALOGY.match(filename):
            continue

        with open(filename, 'rt') as f:
            lines = f.readlines()
            beginnings = list(filter(REGEX_BEGINNING.search, lines))
            ends = list(filter(REGEX_END.search, lines))
            assert beginnings
            assert ends

            beginning_match = REGEX_TIMESTAMP.match(beginnings[0])
            end_match = REGEX_TIMESTAMP.match(ends[0])
            assert beginning_match
            assert end_match

            beginning = int(beginning_match.group('timestamp'))
            end = int(end_match.group('timestamp'))
            assert end >= beginning

            duration += end - beginning

    language = dirname_match.group('language')
    method = dirname_match.group('method')
    if language not in durations:
        durations[language] = {}
    durations[language][method] = duration

print(json.dumps(durations, sort_keys=True, indent=4))
