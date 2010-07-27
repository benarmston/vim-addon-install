#!/bin/bash

# See if user provided an argument
if [ $# -ne 1 ]
then
    echo "Usage: `vim-plugin-install $PLUGIN_NAME`"
    exit
fi

echo "Starting up."

# arg should not have '.vim', it will be added later
PLUGIN_NAME=$1
TEMP_FILE="temp.html"

# define dirs
VIM_PLUGIN_DIR="$HOME/.vim/plugin/"
VIM_DIR="$HOME/.vim"

# sorry to lie about the user agent, i really don't wana but google just rejects wget
USER_AGENT="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+"

# create the url with the first argument as the query (add .vim)
URL="http://www.google.com/cse?cx=partner-pub-3005259998294962:bvyni59kjr1&ie=ISO-8859-1&sa=Search&siteurl=www.vim.org/scripts/index.php&q=$PLUGIN_NAME.vim"
#URL="http://www.google.com/cse?sa=Search&siteurl=www.vim.org/scripts/index.php&q=$1"

# fetch the HTML for the google search result
echo "Looking for plugin."
wget --quiet -O $TEMP_FILE "$URL" -U "$USER_AGENT"


# use grep to find the first script url
FIRST_RESULT=$(grep -o "http:\/\/www\.vim\.org\/scripts\/script\.php?script_id=[0-9]\+" $TEMP_FILE | head -1)

# remove temp file
rm $TEMP_FILE

# if variable is unset, then no results found; exit
if [ -z "$FIRST_RESULT" ]
then
    echo "No results found."
    exit
fi

echo "Found candidate."

# go to script page of first result
echo "Fetching plugin page."
wget --quiet -O $TEMP_FILE "$FIRST_RESULT" -U "$USER_AGENT"

# find the first download link (most recent version of plugin)
echo "Grabbing download link."
DOWNLOAD_URL="http://www.vim.org/scripts/$(grep -o "download_script\.php?src_id=[0-9]\+" $TEMP_FILE | head -1)"
# grab file name from 'a href'
FILE_NAME=$(grep -o "download_script\.php?src_id=[0-9]\+[^<]*" $TEMP_FILE | awk -F'>' '{print $2}' | head -1)

# rm temp file
rm $TEMP_FILE

# download
echo "Downloading file."
wget --quiet -O "$FILE_NAME" "$DOWNLOAD_URL" -U "$USER_AGENT"

echo $FILE_NAME
if [[ $FILE_NAME == *.vim ]]
then
    echo "Copying file to plugin directory."
    cp $FILE_NAME $VIM_PLUGIN_DIR
else
    if [[ $FILE_NAME == *tar* ]]
    then
        echo "Unpacking and adding to plugin directory."
        CURRENT_DIR=$(pwd)
        cd $VIM_DIR
        tar xvf "$CURRENT_DIR/$FILE_NAME"
        cd $CURRENT_DIR
    else
        if [[ $FILE_NAME == *zip ]]
        then
            echo "Unpacking and adding to plugin directory."
            CURRENT_DIR=$(pwd)
            cd $VIM_DIR
            unzip "$CURRENT_DIR/$FILE_NAME"
            rm "$FILE_NAME"
            cd $CURRENT_DIR
        else
            echo "Unknown file type, exiting."
        fi
    fi
fi

rm "$FILE_NAME"

echo "Finished, exiting."
