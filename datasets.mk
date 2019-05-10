include datasets_similarity.mk
include datasets_analogy.mk

DATASETS=$(DATASETS_GERMAN) $(DATASETS_ENGLISH) $(DATASETS_FRENCH) $(DATASETS_SPANISH) $(DATASETS_ARABIC) $(DATASETS_ROMANIAN) $(DATASETS_RUSSIAN) $(DATASETS_CZECH) $(DATASETS_ITALIAN)

DATASETS_GERMAN=$(GERMAN_SIMILARITY) $(GERMAN_ANALOGY)
DATASETS_ENGLISH=$(ENGLISH_SIMILARITY) $(ENGLISH_ANALOGY)
DATASETS_FRENCH=$(FRENCH_SIMILARITY)
DATASETS_SPANISH=$(SPANISH_SIMILARITY)
DATASETS_ARABIC=$(ARABIC_SIMILARITY)
DATASETS_ROMANIAN=$(ROMANIAN_SIMILARITY)
DATASETS_RUSSIAN=$(RUSSIAN_SIMILARITY)
DATASETS_CZECH=$(CZECH_ANALOGY)
DATASETS_ITALIAN=$(ITALIAN_ANALOGY)