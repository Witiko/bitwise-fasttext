RG65_GERMAN=data/rg65_german.txt
GERMAN_SIMILARITY=data/german_similarity
WS353=data/wordsim353
RW=data/rw
RG65_ENGLISH=data/rg65_english.txt
CLSR_EK=data/CLSR_EK
ENGLISH_SIMILARITY=data/english_similarity
RG65_FRENCH=data/rg65_french.txt
FRENCH_SIMILARITY=data/french_similarity
SPANISH_SIMILARITY=data/spanish_similarity
ARABIC_SIMILARITY=data/arabic_similarity
ROMANIAN_SIMILARITY=data/romanian_similarity
HJ=data/hj.csv
RUSSIAN_SIMILARITY=data/russian_similarity

$(GERMAN_SIMILARITY): datasets.zip $(RG65_GERMAN)
	unzip $<
	touch $(basename $<)
	mv $(basename $<) $@
	cd $@ && cp -r --reflink=auto ../../$(RG65_GERMAN) .

$(WS353): wordsim353.zip
	mkdir $(basename $<)
	unzip $< -d $(basename $<)
	mv $(basename $<) $@

$(RW): rw.zip
	unzip $<
	touch $(basename $<)
	mv $(basename $<) $@

$(ENGLISH_SIMILARITY): $(WS353) $(RW) $(RG65_ENGLISH) $(CLSR_EK)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

$(FRENCH_SIMILARITY): $(RG65_FRENCH)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

$(SPANISH_SIMILARITY): $(CLSR_EK)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

$(ARABIC_SIMILARITY): $(CLSR_EK)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

$(ROMANIAN_SIMILARITY): $(CLSR_EK)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

$(RUSSIAN_SIMILARITY): $(HJ)
	mkdir $@
	cd $@ && cp -r --reflink=auto $(addprefix ../../,$^) .

datasets.zip:
	wget https://www.informatik.tu-darmstadt.de/media/ukp/data/fileupload_2/datasets.zip

wordsim353.zip:
	wget http://www.cs.technion.ac.il/~gabr/resources/data/wordsim353/wordsim353.zip

rw.zip:
	wget http://www-nlp.stanford.edu/~lmthang/morphoNLM/rw.zip

$(RG65_ENGLISH):
	paste > $@ \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[1]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 1') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[1]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 0') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[2]//text()' - | sed -n '/[^ ]/s/ *//gp')

$(RG65_GERMAN):
	paste > $@ \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[3]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 1') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[3]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 0') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[4]//text()' - | sed -n '/[^ ]/s/ *//gp')

$(RG65_FRENCH):
	paste > $@ \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[5]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 1') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[5]//text()' - | sed -n '/[^ ]/s/ *//gp' | awk 'NR % 2 == 0') \
	  <(curl -s 'http://www.site.uottawa.ca/~mjoub063/wordsims.htm' | iconv -f cp1252 -t utf8 | xmllint -html -xpath '//table//tr//td[6]//text()' - | sed -n '/[^ ]/s/ *//gp')

$(CLSR_EK): CLSR-EK.tar.gz
	tar xzv -C $(dir $@) -f $<
	touch $@

CLSR-EK.tar.gz:
	wget https://web.archive.org/web/20160324074109/http://lit.csci.unt.edu/~rada/downloads/CLSR-EK.tar.gz

$(HJ):
	wget https://raw.githubusercontent.com/nlpub/russe-evaluation/master/russe/evaluation/hj.csv -O $@
