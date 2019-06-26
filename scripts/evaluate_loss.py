from glob import glob
import json
import re

REGEX_PROGRESS = re.compile(r'^.*Progress:\s*(?P<done>[0-9.]*)%.*loss:\s*(?P<loss>[0-9.]*).*$')
REGEX_TIMESTAMP = re.compile(r'^(?P<timestamp>[0-9]*)\t.*$')
REGEX_DIRNAME = re.compile(r'^models/(?P<language>..)/(?P<method>.*)$')
REGEX_FILENAME = re.compile(r'^.*/100/32b_300d_vectors_e5-(?P<epoch>[0-9.]*)\.log$')
REGEX_FILENAME_ANALOGY = re.compile(r'^.*_accuracy-.*$')

all_losses = {}
for dirname in glob('models/*/*'):
    dirname_match = REGEX_DIRNAME.match(dirname)
    assert dirname_match

    losses = {}
    for filename in sorted(glob('{}/100/32b_300d_vectors_e5-*.log'.format(dirname))):
        if REGEX_FILENAME_ANALOGY.match(filename):
            continue

        filename_match = REGEX_FILENAME.match(filename)
        assert filename_match

        epoch = float(filename_match.group('epoch'))
        with open(filename, 'rt') as f:
            lines = f.readlines()
            progresses = list(filter(REGEX_PROGRESS.search, lines))
            assert progresses

            progress = progresses[-1]
            progress_match = REGEX_PROGRESS.match(progress)
            assert progress_match

            done = float(progress_match.group('done')) / 100.0
            loss = float(progress_match.group('loss'))
            assert done == 1.0, done

            losses[epoch] = loss

    language = dirname_match.group('language')
    method = dirname_match.group('method')
    if language not in all_losses:
        all_losses[language] = {}
    all_losses[language][method] = losses

print(json.dumps(all_losses, sort_keys=True, indent=4))
