#!/bin/bash 
set -o pipefail
fold_label=$1
shift
dir_name=$(dirname $1)
script_name=$(basename $1)
shift

echo -en "travis_fold:start:${fold_label}\r"
pushd "${dir_name}/"
sudo chmod +x ./$script_name
./$script_name $@
exit_code=$?
popd
echo -en "travis_fold:end:${fold_label}\r"
exit $exit_code
