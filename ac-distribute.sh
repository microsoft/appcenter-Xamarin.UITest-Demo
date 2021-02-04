#!/bin/bash

# Environment Variables created by App Center
# $APPCENTER_SOURCE_DIRECTORY
# $APPCENTER_OUTPUT_DIRECTORY
# $APPCENTER_BRANCH

# Custom Environment Variables set in Build configuration
# $API_TOKEN 
# $APP_PACKAGE
# $APP_NAME 
# $OWNER_NAME
# $TEAM_APP = values for $OWNER_NAME/$APP_NAME
# $CONTENT_TYPE for 
#   Android: "application/vnd.android.package-archive"
#   iOS: "application/octet-stream"
# $DISTRIBUTION_GROUP

# Vars to simplify frequently used syntax
UPLOAD_DOMAIN="https://file.appcenter.ms/upload"
API_URL="https://api.appcenter.ms/v0.1/apps/$TEAM_APP"
AUTH="X-API-Token: $API_TOKEN"
ACCEPT_JSON="Accept: application/json"

# Body - Step 1/7
echo "Creating release (1/7)"
request_url="$API_URL/uploads/releases"
upload_json=$(curl -s -X POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$request_url")

releases_id=$(echo $upload_json | jq -r '.id')
package_asset_id=$(echo $upload_json | jq -r '.package_asset_id')
url_encoded_token=$(echo $upload_json | jq -r '.url_encoded_token')

file_name=$(basename $APP_PACKAGE)
file_size=$(eval wc -c $APP_PACKAGE | awk '{print $1}')

# Step 2/7
echo "Creating metadata (2/7)"
metadata_url="$UPLOAD_DOMAIN/set_metadata/$package_asset_id?file_name=$file_name&file_size=$file_size&token=$url_encoded_token&content_type=$CONTENT_TYPE"

meta_response=$(curl -s -d POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$metadata_url")
chunk_size=$(echo $meta_response | jq -r '.chunk_size')

echo $meta_response
echo $chunk_size

split_dir=$APPCENTER_OUTPUT_DIRECTORY/split-dir
mkdir -p $split_dir
eval split -b $chunk_size $APP_PACKAGE $split_dir/split

# Step 3/7
echo "Uploading chunked binary (3/7)"
binary_upload_url="$UPLOAD_DOMAIN/upload_chunk/$package_asset_id?token=$url_encoded_token"

block_number=1
for i in $split_dir/*
do
    echo "start uploading chunk $i"
    url="$binary_upload_url&block_number=$block_number"
    size=$(wc -c $i | awk '{print $1}')
    curl -X POST $url --data-binary "@$i" -H "Content-Length: $size" -H "Content-Type: $CONTENT_TYPE"
    block_number=$(($block_number + 1))
    printf "\n"
done

# Step 4/7
echo "Finalising upload (4/7)"
finish_url="$UPLOAD_DOMAIN/finished/$package_asset_id?token=$url_encoded_token"
curl -d POST -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" "$finish_url"

# Step 5/7
echo "Commit release (5/7)"
commit_url="$API_URL/uploads/releases/$releases_id"
curl -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" \
  --data '{"upload_status": "uploadFinished","id": "$releases_id"}' \
  -X PATCH \
  $commit_url

# Step 6/7
echo "Polling for release id (6/7)"
release_id=null
counter=0
max_poll_attempts=15

while [[ $release_id == null && ($counter -lt $max_poll_attempts)]]
do
    poll_result=$(curl -s -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" $commit_url)
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

# Step 7/7
echo "Applying destination to release (7/7)"
distribute_url="$API_URL/releases/$release_id"
curl -H "Content-Type: application/json" -H "$ACCEPT_JSON" -H "$AUTH" \
  --data '{"destinations": [{ "name": "'"$DISTRIBUTION_GROUP"'"}] }' \
  -X PATCH \
  $distribute_url

echo https://appcenter.ms/orgs/$OWNER_NAME/apps/$APP_NAME/distribute/releases/$release_id
