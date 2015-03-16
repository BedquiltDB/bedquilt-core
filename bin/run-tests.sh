#! /usr/bin/env sh


echo ">> Installing latest version of bedquilt to localhost"


make install
psql -d bedquilt_test \
     -c "create extension if not exists pgcrypto;
         drop extension if exists bedquilt;
         create extension bedquilt;"


echo ">> Running tests"
python -m unittest discover test
