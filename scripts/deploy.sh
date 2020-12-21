#!/bin/sh
# Build, tag, push, and deploy image.

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` [docker-repo] [tag]"
    exit 1
fi

REPO="$1"
TAG="$2"
FUNC_NAME="${REPO}"

if [[ -z "${AWS_ACCOUNT_ID}" ]]; then
    echo "Error: please set AWS_ACCOUNT_ID environment variable"
    exit 1
fi

DKR="${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com"
IMAGE_URI="${DKR}/${REPO}:${TAG}"
DELAY=15

docker build -t ${REPO} . \
  && docker tag ${REPO}:${TAG} ${IMAGE_URI} \
  && docker push ${IMAGE_URI} \
  && aws lambda update-function-code --function-name ${FUNC_NAME} --image-uri ${IMAGE_URI} --publish

echo "It usually takes 15 seconds to take effect..."
sleep $DELAY
