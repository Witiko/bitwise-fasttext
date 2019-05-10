# Downloading the code
To download our code, execute the following commands:

```sh
git clone --recurse-submodules https://github.com/witiko/bitwise-fasttext.git
cd bitwise-fasttext
```

# Reproducing our results
To reproduce our evaluation, you will need our datasets and models. You can
either download the preprocessed datasets and the pretrained models, or you
can preprocess the datasets and train the models on your own.

## Downloading pretrained datasets and models
To preprocess the datasets and train the models, you will require the following
tools:

- `python` and
- `pip`.

To start downloading the preprocessed datasets and the pretrained models,
execute the following commands:

```sh
pip install -r requirements.txt
dvc pull
```

To reproduce our results, execute the following command to open [the notebook
with results](results.ipynb), and run all cells:

```sh
jupyter-notebook results.ipynb
```

## Recreating datasets and retraining models
To preprocess the datasets and train the models, you will require the following
tools:

- `bash`,
- `bc`,
- `git`,
- `head`,
- `make`,
- `paste`,
- `python`,
- `pip`,
- `unzip`,
- `wget`, and
- `xmllint`.

To train the models, you will also require a node where the Portable Batch
System (PBS) is installed, as indicated by the presence of the `qsub` tool.
Configuration of the individual PBS jobs is located in the file `models.mk`.

To start creating the datasets and training the models, execute the following
command:

```sh
pip install -r requirements.txt
dvc repro results.dvc
```

To reproduce our results, execute the following command to open [the notebook
with results](results.ipynb), and run all cells:

```sh
jupyter-notebook results.ipynb
```
