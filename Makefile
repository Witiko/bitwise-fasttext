.ONESHELL:
SHELL=/bin/bash
.SHELLFLAGS=-ec

.PHONY: all
all: results

include corpora.mk
include datasets.mk
include models.mk
include results.mk

data: $(CORPORA) $(DATASETS)

models: $(MODELS)
	while ! stat $(MODELS_FINISHED) &>/dev/null
	do
	  sleep 30
	done

results: $(RESULTS)
