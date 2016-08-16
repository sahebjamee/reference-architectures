#!/bin/bash

echo -en 'travis_fold:start:setup-azure-cli\\r'
azure telemetry --disable
azure login --username $SPN --password $SPP --tenant $T --service-principal
echo -en 'travis_fold:end:setup-azure-cli\\r'
echo
