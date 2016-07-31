#! /usr/bin/env sh

#./bin/install.sh

echo ">> Enabling bedquilt on localhost/bedquilt_test..."
psql -d bedquilt_test \
     -c "create extension if not exists pgcrypto;
         create extension if not exists plpython3u;
         drop extension if exists bedquilt;
         create extension bedquilt;"
if [ $? -ne 0 ]
then
  echo ">> Error while installing bedquilt, exiting..."
  exit 1
fi


echo ">> Running tests..."
python -m unittest discover test
