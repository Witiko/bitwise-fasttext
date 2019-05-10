RESULTS=results.ipynb results/duration.json results/loss.json results/analogy.json

results.ipynb: results/duration.json results/loss.json results/analogy.json
	jupyter nbconvert --to notebook --inplace --ExecutePreprocessor.timeout=-1 --execute $@

results/duration.json:
	mkdir -p results
	python scripts/evaluate_duration.py > $@

results/loss.json:
	mkdir -p results
	python scripts/evaluate_loss.py > $@

results/analogy.json:
	mkdir -p results
	python scripts/evaluate_analogy.py > $@
