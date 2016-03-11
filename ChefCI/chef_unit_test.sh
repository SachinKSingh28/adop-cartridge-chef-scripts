#!/bin/bash

###
#
# Running chefspec unit tests.
#
###
echo
echo "Running chefspec unit tests."
echo


if [ -n "$1" ]
then
  if [ -d "$1" ]; then
    cd $1
    pwd
  else
    echo Usage: $0 '<directory to run in>(optional)'
    exit 1
  fi
fi


rspec --format documentation spec

EXIT_CODE=$?

echo
echo "#######################"

if [ "$EXIT_CODE" != "0" ]; then 
	exit $EXIT_CODE
fi

echo
echo "Unit tests successful!"
echo
