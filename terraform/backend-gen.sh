#!/usr/bin/env bash

err() {
  echo "[$(date +'%Y-%m-%d-%H:%M:%S')]: $*" >&2
  exit 1
}

TABLE_NAME="$(basename "$PWD")_tf_state_$(date +%s)"
BUCKET_NAME="$(basename "$PWD")-$(date +%s)-bucket"
REGION="$(aws configure get region)"

while getopts "n:r:h" FLAG
do
	case "$FLAG" in
		n)
			BUCKET_NAME="$OPTARG"
		  ;;
		r)
			REGION="${OPTARG}"
		  ;;
    h)
      echo -e "-n\tUse custom S3 bucket name"
      echo -e "-r\tUse custom AWS region"
      exit
      ;;
    *);;
	esac
done

# Check if backend.tf not exists and if contains bucket definition
if ! [ -e "backend.tf" ] || [ -z "$(grep -w "bucket" backend.tf | xargs | cut -d ' ' -f3)" ]; 
then
  # Create S3 Bucket
  bucketstatus="$(aws s3api head-bucket --bucket "${BUCKET_NAME}" 3>&2 2>&1 1>&3)"
  if echo "${bucketstatus}" | grep 'Not Found';
  then
    BUCKET="$(aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" --output text)"
    echo "Bucket created s3:/$BUCKET"
    elif echo "${bucketstatus}" | grep 'Forbidden';
    then
      err "Bucket exists but isn't owned by you"
    fi
  else
    err "Bucket ${BUCKET_NAME} was already declared in backend.tf"
fi

# Check dynamodb_table exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" 2>/dev/null ; then
  err "Table $TABLE_NAME already exists"
fi

# Create DynamoDB table
if ! [ -e "backend.tf" ] || [ -z "$(grep -w "dynamodb_table" backend.tf | xargs | cut -d ' ' -f3)" ]; 
then
  aws dynamodb create-table \
      --table-name "$TABLE_NAME" \
      --attribute-definitions \
          AttributeName=LockID,AttributeType=S \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --table-class STANDARD 1>/dev/null
  echo "Table created $TABLE_NAME"
else
    err "Table ${TABLE_NAME} was already declared in backend.tf"
fi

# Write backend.tf
cat << EOF > backend.tf
terraform {
  backend "s3" {
    bucket = "${BUCKET_NAME}"
    key    = "$(basename "$PWD")/terraform.tfstate"
    dynamodb_table = "${TABLE_NAME}"
    region = "${REGION}"
  }
}
EOF