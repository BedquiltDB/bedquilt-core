#! /usr/bin/env sh

echo ">> Installing to bedquilt_test"
python bin/install.py --database bedquilt_test

echo ">> Running tests"
python -m unittest discover test
