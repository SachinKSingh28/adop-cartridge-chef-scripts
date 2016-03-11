#!/bin/bash --login

###
#
# Scripts requires dos2unix, ruby1.9.3, foodcritic gem installed.
#
###

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


echo $(which jsonlint)
# Files to check
FILES=$(find . -name "*.json")
JSON_SYNTAX_EXIT=0

for FILE in $FILES
do
  echo "Checking ${FILE}"
  jsonlint $FILE
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
echo "Foodcritc Lint checks"
echo

command -v foodcritic || alias foodcritic='docker run --rm -v $(pwd):/cookbook/ spheromak/docker-chefdk foodcritic'
foodcritic . -f any --tags ~FC015 --tags ~FC003 --tags ~FC023 --tags ~FC041 --tags ~FC034 -X spec
FC_EXIT_CODE=$?

if [ "$FC_EXIT_CODE" != "0" ]; then
    echo "Lint errors found"
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


#echo
#echo "#######################"
#echo
#echo "Checking whether this cookbook version is already on the Chef Server..."
#echo "-> Later version should be used in metadata, so that the cookbook is uploaded."
#echo
#
#DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#ruby ${DIR}/chef_version_test.rb
#VERSION_EXIT_CODE=$?
#
#if [ "$VERSION_EXIT_CODE" != "0" ]; then
#  echo
#  echo "->"
#  echo "-> Version is already on Chef Server, please bump the version following SemVer 2.0.0 rules."
#  echo "-> Usualy patch number is bumped."
#  echo "->"
#  EXIT_CODE=1
#else
#  echo
#  echo "Cookbook Version OK."
#fi
#
echo
echo "#######################"
echo

exit $EXIT_CODE
