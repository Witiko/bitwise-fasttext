MODELS=$(MODELS_GERMAN) $(MODELS_ENGLISH) $(MODELS_FRENCH) $(MODELS_SPANISH) $(MODELS_ARABIC) $(MODELS_ROMANIAN) $(MODELS_RUSSIAN) $(MODELS_CZECH) $(MODELS_ITALIAN)
MODELS_FINISHED=$(addsuffix /finished,$(MODELS))

MODELS_METHODS=none dbc l2reg

MODELS_GERMAN=$(addprefix models/de/,$(foreach X,$(MODELS_METHODS),$(foreach Y,$(CORPORA_SUBS),$X/$Y)))
MODELS_ENGLISH=$(addprefix models/en/,$(foreach X,$(MODELS_METHODS),$(foreach Y,$(CORPORA_SUBS),$X/$Y)))
MODELS_FRENCH=$(addprefix models/fr/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_SPANISH=$(addprefix models/es/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_ARABIC=$(addprefix models/ar/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_ROMANIAN=$(addprefix models/ro/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_RUSSIAN=$(addprefix models/ru/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_CZECH=$(addprefix models/cs/,$(addsuffix /100,$(MODELS_METHODS)))
MODELS_ITALIAN=$(addprefix models/it/,$(addsuffix /100,$(MODELS_METHODS)))

MODEL_REGEX=models/([^/]*)/([^/]*)/([^/]*)

COMPUTE_ACCURACY_3COSADD=Word2Bits/compute_accuracy
COMPUTE_ACCURACY_3HAMMOR=Word2Bits/compute_accuracy_bitwise
FASTTEXT=fastText/fasttext

BUCKET=2000000
DIM=300
EPOCH=0.2
EPOCH_TOTAL=5
LOSS=ns
L2REG=0.001
LR=0.05
MIN_N=3
MAX_N=6
MIN_COUNT=5
NEG=5
T=0.0001
THREAD=16
MEM=16gb
SCRATCH=25g
WS=5
THRESHOLD=200000

OUTPUT_BASENAME=32b_$(DIM)d_vectors_e$(EPOCH_TOTAL)

define compute_accuracy =
LANGUAGE=`sed -r 's#$(MODEL_REGEX)#\1#' <<< $(1)`
case \$$LANGUAGE in
cs) ANALOGY=$(CZECH_ANALOGY);;
it) ANALOGY=$(ITALIAN_ANALOGY);;
de) ANALOGY=$(GERMAN_ANALOGY);;
en) ANALOGY=$(ENGLISH_ANALOGY);;
*)  exit 0;;
esac
BASENAME=$(1)/$(OUTPUT_BASENAME)-$(2)
INPUT=\$$BASENAME.vec
COSADD_OUTPUT=\$${BASENAME}_accuracy-3cosadd.log
HAMMOR_OUTPUT=\$${BASENAME}_accuracy-3hammor.log
make -C $(dir $(COMPUTE_ACCURACY_3COSADD)) $(notdir $(COMPUTE_ACCURACY_3COSADD))
$(COMPUTE_ACCURACY_3COSADD) -binary 0 \$$INPUT 0 $(THRESHOLD) < \$$ANALOGY &> \$$COSADD_OUTPUT
make -C $(dir $(COMPUTE_ACCURACY_3HAMMOR)) $(notdir $(COMPUTE_ACCURACY_3HAMMOR))
$(COMPUTE_ACCURACY_3HAMMOR) -binary 0 \$$INPUT 0 $(THRESHOLD) < \$$ANALOGY &> \$$HAMMOR_OUTPUT
endef

define skipgram =
make -C $(dir $(FASTTEXT))
mkdir -p $(1)
LANGUAGE=`sed -r 's#$(MODEL_REGEX)#\1#' <<< $(1)`
TYPE=`sed -r 's#$(MODEL_REGEX)#\2#' <<< $(1)`
SUB=`sed -r 's#$(MODEL_REGEX)#\3#' <<< $(1)`
INPUT=data/wikimedia/wiki.\$$LANGUAGE.sub\$$SUB.txt
case \$$TYPE in
none)    $(call skipgram_inner,\$$INPUT,$(1),$(2),$(3));;
[sd]bc)  $(call skipgram_inner,\$$INPUT,$(1),$(2),$(3),-binarization \$$TYPE);;
[sd]bc+) $(call skipgram_inner,\$$INPUT,$(1),$(2),$(3),-binarization \$${TYPE%+} -binarizeHidden);;
l2reg)   $(call skipgram_inner,\$$INPUT,$(1),$(2),$(3),-l2reg $(L2REG));;
esac
endef

define skipgram_inner =
(
  echo Copying data to scratch storage
  trap 'rm "\$$SCRATCHDIR"/input' TERM EXIT
  cp $(1) "\$$SCRATCHDIR"/input
  echo Copied data to scratch storage

  echo Training the model
  time $(FASTTEXT) skipgram \
                   -input "\$$SCRATCHDIR"/input \
                   -output $(2)/$(OUTPUT_BASENAME)-$(4) \
                   -bucket $(BUCKET) \
                   -dim $(DIM) \
                   -epochSkip $(3) \
                   -epochTotal $(EPOCH_TOTAL) \
                   -epoch $(EPOCH) \
                   -loss $(LOSS) \
                   -lr $(LR) \
                   -minn $(MIN_N) \
                   -maxn $(MAX_N) \
                   -minCount $(MIN_COUNT) \
                   -neg $(NEG) \
                   \$$(if [[ $(3) != 0 ]]
                       then
                         echo " -pretrainedModel $(2)/$(OUTPUT_BASENAME)-$(3)"
                       fi
                   ) \
                   -t $(T) \
                   -thread $(THREAD) \
                   -ws $(WS) \
                   $(5)
  echo Trained the model

  echo Cleaning up
  if [[ $(3) != 0 ]]
  then
    rm $(2)/$(OUTPUT_BASENAME)-$(3).{bin,vec}
  fi
 echo Cleaned up
) |&
while read -r LINE
do
  printf '%s\t%s\n' \$$(date +%s) "\$$LINE"
done | tee $(2)/$(OUTPUT_BASENAME)-$(4).log
endef

define qsub_headers =
#!/bin/bash
#PBS -N $(subst /,-,$(1))-$(3)
#PBS -l select=1:ncpus=$(THREAD):mem=$(MEM):debian9=True:cl_nympha=True:scratch_ssd=$(SCRATCH)
#PBS -l place=shared
#PBS -l walltime=24:00:00
#PBS -p 1023
$(2)
set -e
module add gcc-7.2.0
cd "\$$PBS_O_WORKDIR"
endef

$(MODELS):
	TEMPFILE=`tempfile`
	trap 'rm $$TEMPFILE' EXIT
	
	cat > $$TEMPFILE <<-EOF
	$(call qsub_headers,$@,,$(EPOCH))
	$(call skipgram,$@,0,$(EPOCH))
	EOF
	PREVIOUS_JOB=$$(qsub $$TEMPFILE)
	
	for EPOCH_SKIP in $$(LC_ALL=C seq $(EPOCH) $(EPOCH) $$(bc -l <<< '$(EPOCH_TOTAL) - $(EPOCH)'))
	do
	  EPOCH_SKIP=$$(LC_ALL=C printf '%g' $$EPOCH_SKIP)
	  EPOCH_STOP=$$(LC_ALL=C printf '%g' $$(bc -l <<< "$$EPOCH_SKIP + $(EPOCH)"))
	  cat > $$TEMPFILE <<-EOF
	  $(call qsub_headers,$@,#PBS -W depend=afterok:$$PREVIOUS_JOB,$$EPOCH_STOP)
	  $(call skipgram,$@,$$EPOCH_SKIP,$$EPOCH_STOP)
	EOF
	  PREVIOUS_JOB=$$(qsub $$TEMPFILE)
	done
	
	cat > $$TEMPFILE <<-EOF
	$(call qsub_headers,$@,#PBS -W depend=afterok:$$PREVIOUS_JOB,finish)
	$(call compute_accuracy,$@,$$EPOCH_STOP)
	touch $@/finished
	EOF
	PREVIOUS_JOB=$$(qsub $$TEMPFILE)
