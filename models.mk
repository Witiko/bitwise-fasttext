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

define skipgram =
make -C $(dir $(FASTTEXT))
mkdir -p $(1)
LANGUAGE=`sed -r 's#$(MODEL_REGEX)#\1#' <<< $(1)`
TYPE=`sed -r 's#$(MODEL_REGEX)#\2#' <<< $(1)`
SUB=`sed -r 's#$(MODEL_REGEX)#\3#' <<< $(1)`
INPUT=data/wikimedia/wiki.\$$LANGUAGE.sub\$$SUB.txt
OUTPUT_BASENAME=32b_$(DIM)d_vectors_e$(EPOCH_TOTAL)
if [[ \$$TYPE = none ]]
then
  $(call skipgram_inner,\$$INPUT,$(1),\$$OUTPUT_BASENAME,$(2),$(3))
elif [[ \$$TYPE = sbc || \$$TYPE = dbc ]]
then
  $(call skipgram_inner,\$$INPUT,$(1),\$$OUTPUT_BASENAME,$(2),$(3),-binarization \$$TYPE)
elif [[ \$$TYPE = l2reg ]]
then
  $(call skipgram_inner,\$$INPUT,$(1),\$$OUTPUT_BASENAME,$(2),$(3),-l2reg $(L2REG))
fi
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
                   -output $(2)/$(3)-$(5) \
                   -bucket $(BUCKET) \
                   -dim $(DIM) \
                   -epochSkip $(4) \
                   -epochTotal $(EPOCH_TOTAL) \
                   -epoch $(EPOCH) \
                   -loss $(LOSS) \
                   -lr $(LR) \
                   -minn $(MIN_N) \
                   -maxn $(MAX_N) \
                   -minCount $(MIN_COUNT) \
                   -neg $(NEG) \
                   \$$(if [[ $(4) != 0 ]]
                       then
                         echo " -pretrainedModel $(2)/$(3)-$(4)"
                       fi
                   ) \
                   -t $(T) \
                   -thread $(THREAD) \
                   -ws $(WS) \
                   $(6)
  echo Trained the model

  echo Cleaning up
  if [[ $(4) != 0 ]]
  then
    rm $(2)/$(3)-$(4).{bin,vec}
  fi
 echo Cleaned up
) |&
while read -r LINE
do
  printf '%s\t%s\n' \$$(date +%s) "\$$LINE"
done | tee $(2)/$(3)-$(5).log
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
	touch $@/finished
	EOF
	PREVIOUS_JOB=$$(qsub $$TEMPFILE)
