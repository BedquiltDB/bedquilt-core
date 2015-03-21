#! /usr/bin/env sh

./bin/install.sh

echo ">> Enabling bedquilt on localhost/bedquilt_test..."
psql -d bedquilt_test \
     -c "create extension if not exists pgcrypto;
         drop extension if exists bedquilt;
         create extension bedquilt;"


echo ">> Running tests..."
python -m unittest discover test
