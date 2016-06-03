#!/bin/bash

###
#
# Scripts requires ruby1.9.3, foodcritic and cookstyle gems installed.
#
###

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

COOKBOOK_NAME=$(grep "name.*" metadata.rb | sort -r | head -n -1)
COOKBOOK_VERSION=$(grep version metadata.rb | head -n 1)

# Setting variables
EXIT_CODE=0

echo
echo "Testing Cookbook:"
echo "${COOKBOOK_NAME}"
echo "${COOKBOOK_VERSION}"
echo
echo
echo "#######################"
echo
echo "Foodcritc Lint checks"
echo

echo Using: $(which foodcritic)
foodcritic . -f any --tags ~FC015 --tags ~FC003 --tags ~FC023 --tags ~FC041 --tags ~FC034 -X spec
FC_EXIT_CODE=$?

if [ "$FC_EXIT_CODE" != "0" ]; then
    echo "Foodcritic errors found"
    EXIT_CODE=1
else
   echo "Foodcritic tests successful"
fi

echo
echo "#######################"
echo

echo
echo "#######################"
echo
echo "Cookstyle checks"
echo

echo Using: $(which cookstyle)
cookstyle -D
CK_EXIT_CODE=$?

if [ "$CK_EXIT_CODE" != "0" ]; then
    echo "Cookstyle errors found"
    EXIT_CODE=1
else
   echo "Cookstyle tests successful"
fi

echo
echo "#######################"
echo

exit $EXIT_CODE
