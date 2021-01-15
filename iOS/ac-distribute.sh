#!/bin/bash

# Environment Variables created by App Center
# $APPCENTER_SOURCE_DIRECTORY
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_BRANCH

# Custom Environment Variables set in Build configuration
# $API_KEY
# $DEVICE_SET
# $DISTRIBUTION_GROUP
# $TEAM_APP => OWNER_NAME + APP_NAME
# $APP_PACKAGE
# $CONTENT_TYPE

# Vars to simplify repeated syntax
UPLOAD_DOMAIN="https://file.appcenter.ms/upload"
API_URL="https://api.appcenter.ms/v0.1/apps/$OWNER_NAME/$APP_NAME"
AUTH="X-API-Token: $API_KEY"
ACCEPT_JSON="Accept: application/json"

# Body
echo "Creating release (1/7)"
request_url="$API_URL/uploads/releases"
upload_json=$(curl -s -X POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$request_url")

releases_id=$(echo $upload_json | jq -r '.id')
package_asset_id=$(echo $upload_json | jq -r '.package_asset_id')
url_encoded_token=$(echo $upload_json | jq -r '.url_encoded_token')

file_name=$(basename $APP_PACKAGE)
file_size=$(wc -c $APP_PACKAGE | awk '{print $1}')

echo "Creating metadata (2/7)"
metadata_url="$UPLOAD_DOMAIN/set_metadata/$package_asset_id?file_name=$file_name&file_size=$file_size&token=$url_encoded_token&content_type=$CONTENT_TYPE"


meta_response=$(curl -s -d POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$metadata_url")
chunk_size=$(echo $meta_response | jq -r '.chunk_size')

echo $meta_response
echo $chunk_size

split_dir=$APPCENTER_OUTPUT_DIRECTORY/split-dir
split -b $chunk_size $APP_PACKAGE $split_dir/split

echo "Uploading chunked binary (3/7)"
binary_upload_url="$UPLOAD_DOMAIN/upload_chunk/$package_asset_id?token=$url_encoded_token"

block_number=1
for i in $split_dir/*
do
    echo "start uploading chunk $f"
    url="$binary_upload_url&block_number=$block_number"
    size=$(wc -c $f | awk '{print $1}')
    curl -X POST $url --data-binary "@$i" -H "Content-Length: $size" -H "Content-Type: $CONTENT_TYPE"
    block_number=$(($block_number + 1))
    printf "\n"
done

echo "Finalising upload (4/7)"
finish_url="$UPLOAD_DOMAIN/finished/$package_asset_id?token=$url_encoded_token"
curl -d POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$finish_url"

echo "Commit release (5/7)"
commit_url="$API_URL/uploads/releases/$releases_id"
curl -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" \
  --data '{"upload_status": "uploadFinished","id": "$releases_id"}' \
  -X PATCH \
  $commit_url

release_status_url="$API_URL/uploads/releases/$releases_id"

release_id=null
counter=0
max_poll_attempts=15

echo "Polling for release id (6/7)"
while [[ $release_id == null && ($counter -lt $max_poll_attempts)]]
do
    poll_result=$(curl -s -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" $release_status_url)
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
curl -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" \
  --data '{"destinations": [{ "name": "$DISTRIBUTION_GROUP"}] }' \
  -X PATCH \
  $distribute_url

echo https://appcenter.ms/orgs/$OWNER_NAME/apps/$APP_NAME/distribute/releases/$release_id
