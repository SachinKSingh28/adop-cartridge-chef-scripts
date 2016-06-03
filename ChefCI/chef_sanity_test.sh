#!/bin/bash

###
#
# Scripts requires dos2unix, ruby1.9.3, foodcritic gem installed.
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
IGNORE="(jpg$|gif$|png$|gd2$|jar$|swp$|war$)"
LOG=dosfiles.txt
EXIT_CODE=0

echo
echo "Testing Cookbook:"
echo "${COOKBOOK_NAME}"
echo "${COOKBOOK_VERSION}"
echo
echo "#######################"
echo
echo "Windows Line endings check"
echo

grep -rl $'\r' * | egrep -v $IGNORE | tee $LOG

if [ -s $LOG ]
then
  echo "CrLf, windows line endings found!"
  echo "Converting Windows files to unix"

  cat dosfiles.txt | while read LINE
  do
  	dos2unix ${LINE}

  done
else
  echo "No Windows files found!"
fi

# Clean up log so that this is not uploaded to knife server
rm -rf $LOG

echo
echo "#######################"
echo
echo "Ruby Syntax Check"
echo

echo $(which ruby)
# Files to check
FILES=$(find . -name "*.rb")
RB_SYNTAX_EXIT=0

for FILE in $FILES
do
  RESULT=$(ruby -c $FILE)
  RB_SYNTAX_EXIT=$(($RB_SYNTAX_EXIT + $?))
  echo "Checking ${FILE} - ${RESULT}"
done

if [ "$RB_SYNTAX_EXIT" -ne "0" ]; then
	echo "Syntax Errors found"
	EXIT_CODE=1
else
	echo
	echo "Ruby Syntax Check Successful"
fi

echo
echo "#######################"
echo
echo "Ruby JSON Syntax checks"
echo


echo $(which jq)
# Files to check
FILES=$(find . -name "*.json")
JSON_SYNTAX_EXIT=0

for FILE in $FILES
do
  echo "Checking ${FILE}"
  jq . $FILE
  JSON_SYNTAX_EXIT=$(($JSON_SYNTAX_EXIT + $?))
done

if [ "$JSON_SYNTAX_EXIT" != "0" ]; then
	echo "JSON Syntax Errors found"
	EXIT_CODE=1
else
	echo
	echo "JSON Syntax Check Successful"
fi

echo
echo "#######################"
echo

echo
echo "#######################"
echo
echo "Checking for local cookbook depencies..."
echo "-> Dependencies should be from external GIT repositories accessible by Jenkins."
echo

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ruby ${DIR}/chef_berksfile_test.rb
BERKS_EXIT_CODE=$?

if [ "$BERKS_EXIT_CODE" != "0" ]; then
 echo
 echo "->"
 echo "-> Berksfile local path cookbook dependencies found - please ensure all dependencies are from GIT!"
 echo "->"
 EXIT_CODE=1
else
 echo
 echo "Berksfile dependencies OK."
fi

echo
echo "#######################"
echo

exit $EXIT_CODE
