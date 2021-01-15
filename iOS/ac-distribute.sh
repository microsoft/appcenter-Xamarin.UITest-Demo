#!/bin/bash

# Environment Variables created by App Center
# $APPCENTER_SOURCE_DIRECTORY
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_BRANCH

# Custom Environment Variables set in Build configuration
# $API_KEY
# $DEVICE_SET
# $DISTRIBUTION_GROUP
# $TEAM_APP

OWNER_NAME=XTCTeam
APP_NAME=Kent-G.-UITestDemo-1
FILE=$APPCENTER_OUTPUT_DIRECTORY/UITestDemo.ipa
DISTRIBUTION_GROUP="My Device"
UPLOAD_DOMAIN="https://file.appcenter.ms/upload"
API_DOMAIN="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME"

AUTH="X-API-Token: $API_KEY"
CONTENT_TYPE=application/octet-stream

echo "Creating release (1/7)"
request_url="$API_DOMAIN/uploads/releases"
upload_json=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" "$request_url")

RELEASES_ID=$(echo $upload_json | jq -r '.id')
PACKAGE_ASSET_ID=$(echo $upload_json | jq -r '.package_asset_id')
URL_ENCODED_TOKEN=$(echo $upload_json | jq -r '.url_encoded_token')

FILE_NAME=$(basename $FILE)
FILE_SIZE=$(wc -c $FILE | awk '{print $1}')

echo "Creating metadata (2/7)"
set_metadata_url="$UPLOAD_DOMAIN/upload/set_metadata/$PACKAGE_ASSET_ID?file_name=$FILE_NAME&file_size=$FILE_SIZE&token=$URL_ENCODED_TOKEN&content_type=$CONTENT_TYPE"


meta_response=$(curl -s -d POST -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" "$set_metadata_url")
chunk_size=$(echo $meta_response | jq -r '.chunk_size')

echo $meta_response
echo $chunk_size

TMP_BUILD_DIR=build/appcenter-tmp

rm -rf $TMP_BUILD_DIR
mkdir -p $TMP_BUILD_DIR
split -b $chunk_size $FILE $TMP_BUILD_DIR/split

echo "Uploading chunked binary (3/7)"
binary_upload_url="$UPLOAD_DOMAIN/upload/upload_chunk/$PACKAGE_ASSET_ID?token=$URL_ENCODED_TOKEN"

block_number=1
for f in $TMP_BUILD_DIR/*
do
    echo "start uploading chunk $f"
    url="$binary_upload_url&block_number=$block_number"
    size=$(wc -c $f | awk '{print $1}')
    curl -X POST $url --data-binary "@$f" -H "Content-Length: $size" -H "Content-Type: $CONTENT_TYPE"
    block_number=$(($block_number + 1))
    printf "\n"
done

echo "Finalising upload (4/7)"
finish_url="$UPLOAD_DOMAIN/upload/finished/$PACKAGE_ASSET_ID?token=$URL_ENCODED_TOKEN"
curl -d POST -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" "$finish_url"

echo "Commit release (5/7)"
commit_url="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME/uploads/releases/$RELEASES_ID"
curl -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" \
  --data '{"upload_status": "uploadFinished","id": "$RELEASES_ID"}' \
  -X PATCH \
  $commit_url

release_status_url="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME/uploads/releases/$RELEASES_ID675%"

release_id=null
counter=0
max_poll_attempts=15

echo "Polling for release id (6/7)"
while [[ $release_id == null && ($counter -lt $max_poll_attempts)]]
do
    poll_result=$(curl -s -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" $release_status_url)
    release_id=$(echo $poll_result | jq -r '.release_distinct_id')
    echo $counter $release_id
    counter=$((counter + 1))
    sleep 3
done

if [[ $release_id == null ]];
then
    echo "Failed to find release from appcenter"
    exit 1
fi

echo "Applying destination to release (7/7)"
distribute_url="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME/releases/$release_id"
curl -H "Content-Type: application/json" -H "Accept: application/json" -H "$AUTH" \
  --data '{"destinations": [{ "name": "$DISTRIBUTION_GROUP"}] }' \
  -X PATCH \
  $distribute_url

echo https://appcenter.ms/orgs/$OWNER_NAME/apps/$APP_NAME/distribute/releases/$release_id
