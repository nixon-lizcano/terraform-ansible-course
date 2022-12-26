#!/usr/bin/env bash

err() {
    echo "[$(date +'%Y-%m-%d-%H:%M:%S')]: $*" >&2
    exit 1
}

# Check backend file
if ! [ -e "backend.tf" ]; then
    err "backend.tf not found"
fi

# User confirmation
read -r -p "Are you sure to destroy remote backend? [y/n] " response
response=${response,,}
if ! [[ $response =~ ^(y| ) ]] || [[ -z $response ]]; then
    exit
fi

# Read from backend.tf
BUCKET_NAME="$(grep -w "bucket" backend.tf | xargs | cut -d ' ' -f3)"
TABLE_NAME="$(grep -w "dynamodb_table" backend.tf | xargs | cut -d ' ' -f3)"

# Check s3 bucket
bucketstatus="$(aws s3api head-bucket --bucket "${BUCKET_NAME}" 3>&2 2>&1 1>&3)"
if echo "${bucketstatus}" | grep 'Not Found';
then
    :
elif echo "${bucketstatus}" | grep 'Forbidden';
then
    err "Bucket ${BUCKET_NAME} exists but is not owned by you"
fi
# Delete S3 Bucket
aws s3 rm s3://"${BUCKET_NAME}" --recursive
aws s3api delete-bucket --bucket "${BUCKET_NAME}"
echo "Bucket ${BUCKET_NAME} was deleted"

# Check DynamoDB table
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" 1>/dev/null ; then
    err "Table ${TABLE_NAME} does not exist"
fi

# Delete DynamoDB table
aws dynamodb delete-table --table-name "${TABLE_NAME}" &>/dev/null
echo "Table ${TABLE_NAME} was deleted"
rm "$PWD/"backend.tf
echo "backend.tf file was deleted"