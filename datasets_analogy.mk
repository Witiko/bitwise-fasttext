GOOGLE_ANALOGY_WORDS=data/google_analogy_words.txt
ENGLISH_ANALOGY=data/english_analogy/google_analogy_words.txt
CZECH_EMB_CORPUS_WORDS=data/czech_emb_corpus_no_phrase.txt
CZECH_ANALOGY=data/czech_analogy/czech_emb_corpus_no_phrase.txt
GERMAN_ANALOGY=data/german_analogy/de_trans_Google_analogies.txt
QUESTION_WORDS_ITA=data/questions-words-ITA.txt
ITALIAN_ANALOGY=data/italian_analogy/questions-words-ITA.txt

$(ENGLISH_ANALOGY): $(GOOGLE_ANALOGY_WORDS)
	mkdir $(dir $@)
	cd $(dir $@) && cp -r --reflink=auto $(addprefix ../../,$^) .

$(CZECH_ANALOGY): $(CZECH_EMB_CORPUS_WORDS)
	mkdir $(dir $@)
	cd $(dir $@) && cp -r --reflink=auto $(addprefix ../../,$^) .

$(GERMAN_ANALOGY): analogies.zip
	unzip $<
	touch $(basename $<)
	mkdir $(dir $@)
	mv $(basename $<)/de_trans_Google_analogies.txt $(dir $@)
	rm -r $(basename $<)

$(ITALIAN_ANALOGY): $(QUESTION_WORDS_ITA)
	mkdir $(dir $@)
	cd $(dir $@) && cp -r --reflink=auto $(addprefix ../../,$^) .

$(GOOGLE_ANALOGY_WORDS):
	wget https://raw.githubusercontent.com/tmikolov/word2vec/master/questions-words.txt -O $@

$(CZECH_EMB_CORPUS_WORDS):
	wget https://raw.githubusercontent.com/Svobikl/cz_corpus/master/corpus/czech_emb_corpus_no_phrase.txt -O $@

analogies.zip:
	wget https://www.ims.uni-stuttgart.de/forschung/ressourcen/lexika/analogies_ims/analogies.zip

$(QUESTION_WORDS_ITA):
	wget http://hlt.isti.cnr.it/wordembeddings/questions-words-ITA.txt -O - | grep -v '^#' | sed -r '/^:/s/([^:]) (.)/\1_\2/g' > $@
