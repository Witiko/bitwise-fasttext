CORPORA=$(CORPORA_GERMAN) $(CORPORA_ENGLISH) $(CORPORA_FRENCH) $(CORPORA_SPANISH) $(CORPORA_ARABIC) $(CORPORA_ROMANIAN) $(CORPORA_RUSSIAN) $(CORPORA_CZECH) $(CORPORA_ITALIAN)

CORPORA_SUBS=1 2 5 10 20 50 100

CORPORA_GERMAN=$(addprefix data/wikimedia/wiki.de.sub,$(addsuffix .txt,$(CORPORA_SUBS)))
CORPORA_ENGLISH=$(addprefix data/wikimedia/wiki.en.sub,$(addsuffix .txt,$(CORPORA_SUBS)))
CORPORA_FRENCH=data/wikimedia/wiki.fr.sub100.txt
CORPORA_SPANISH=data/wikimedia/wiki.es.sub100.txt
CORPORA_ARABIC=data/wikimedia/wiki.ar.sub100.txt
CORPORA_ROMANIAN=data/wikimedia/wiki.ro.sub100.txt
CORPORA_RUSSIAN=data/wikimedia/wiki.ru.sub100.txt
CORPORA_CZECH=data/wikimedia/wiki.cs.sub100.txt
CORPORA_ITALIAN=data/wikimedia/wiki.it.sub100.txt

data/wikimedia/wiki.%.txt:
	fastText/get-wikimedia.sh <<<$(patsubst data/wikimedia/wiki.%.txt,%,$@)$$'\n'y
	cd data/wikimedia && ln -s */$(patsubst data/wikimedia/%,%,$@) .

data/wikimedia/wiki.%.sub1.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` *  1 / 100)) < $< > $@

data/wikimedia/wiki.%.sub2.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` *  2 / 100)) < $< > $@

data/wikimedia/wiki.%.sub5.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` *  5 / 100)) < $< > $@

data/wikimedia/wiki.%.sub10.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` * 10 / 100)) < $< > $@

data/wikimedia/wiki.%.sub20.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` * 20 / 100)) < $< > $@

data/wikimedia/wiki.%.sub50.txt: data/wikimedia/wiki.%.txt
	head -n $$((`wc -l < $<` * 50 / 100)) < $< > $@

data/wikimedia/wiki.%.sub100.txt: data/wikimedia/wiki.%.txt
	cd data/wikimedia && cp -r --reflink=auto $(notdir $<) $(notdir $@)
