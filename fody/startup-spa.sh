#! /bin/sh
echo "$PWD"
yarn 2>&1
yarn run dev 2>&1 &
tail -F anything
