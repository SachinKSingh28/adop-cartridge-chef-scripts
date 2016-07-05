#!/bin/bash

###
#
# Scripts requires knife and knife.rb setup in .chef
#
###

if [ -n "$1" ]
then
  if [ -d "$1" ]; then
    cd $1
    pwd
  else
    echo "Please, set the PATH for the script."
    exit 1
  fi
fi

if [ -z ${CHEF_SERVER_URL} ]; then echo "CHEF_SERVER_URL is unset."; exit 1; fi
if [ -z ${USERNAME} ]; then echo "USERNAME is unset."; exit 1; fi
if [ -z ${VALIDATOR} ]; then echo "VALIDATOR is unset."; exit 1; fi

echo
echo "****************************"
echo "Downloading cookbooks from the Berksfile"

METADATA_FILE=$(find . -path ./cookbooks/\*/metadata.rb | grep -v test)
COOKBOOK_NAME=$(grep "name.*" $METADATA_FILE | sort -r | head -n1 | awk '{print $2}' | tr -d "'" | sed 's/\"//g')
BERKSFILE=$(find . -path ./cookbooks/\*/Berksfile)
BERKS_LOCK=$(find . -path ./cookbooks/\*/Berksfile.lock)
BERKS_CONFIG=$(find . -path ./.chef/berks-config.json)

if [ -e "$BERKSFILE" ]; then
    echo "Found: $BERKSFILE !"
    which berks
    berks -v

    echo "Updating configs..."
    SERVER_URL=$(echo $CHEF_SERVER_URL | sed 's:/:\\/:g')
    sed -i "s/chef_server_url.*"/chef_server_url\":"\"$SERVER_URL\",/" $BERKS_CONFIG
    CONF_DIR=$(find . -name ".chef")
    CLIENT_KEY_FULL_PATH=$(echo $CONF_DIR/$USERNAME.pem | sed 's:/:\\/:g')
    sed -i "s/client_key.*"/client_key\":"\"$CLIENT_KEY_FULL_PATH\",/" $BERKS_CONFIG
    sed -i "s/node_name.*"/node_name\":"\"$USERNAME\"/" $BERKS_CONFIG

    echo "Uploading cookbooks."
    berks install -b $BERKSFILE
    knife -v
    knife ssl fetch
    TRUSTED_CRT=$(find . -path ./.chef/trusted_certs/\*.crt)
    export SSL_CERT_FILE=$TRUSTED_CRT

    berks upload -b $BERKSFILE -c $BERKS_CONFIG --ssl-verify=false
    knife cookbook upload $COOKBOOK_NAME --force

else
    echo "Berksfile not found."
    echo "Trying upload via knife..."
    knife cookbook upload $COOKBOOK_NAME --force
fi

EXIT_CODE=$?

echo
echo "****************************"
echo

exit $EXIT_CODE
