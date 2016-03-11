#!/bin/bash --login

###
#
# Running chefspec unit tests.
#
###
echo
echo "Running chefspec unit tests."
echo

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