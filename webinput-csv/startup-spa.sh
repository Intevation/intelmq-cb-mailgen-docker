#! /bin/sh
echo "$PWD"
yarn 2>&1
yarn serve 2>&1 &
tail -F anything
