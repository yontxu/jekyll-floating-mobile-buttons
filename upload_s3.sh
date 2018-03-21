#!/bin/bash
#
# Simple upload to S3_BUCKET_NAME
#

BRANCH="$(git symbolic-ref -q HEAD)"

if [[ $BRANCH != *master* ]]; then
  echo "Usage: You MUST be in the master branch to use `basename $0`"
  exit 1
fi

HERE=$(pwd)
echo "Script invoked from [$HERE]"

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR
echo "Changed to [$DIR] to execute the jekyll build"

# Generate the website files
JEKYLL_ENV=production bundle exec jekyll b

cd _site
echo "Changed to [_site] to execute the AWS S3 sync"

# Sync with the server
aws s3 sync . s3://S3_BUCKET_NAME --include "*" --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

echo "Moving back to [$HERE]"
cd $HERE