#!/bin/sh
# Build, tag, push, and deploy image.

if [ $# -ne 2 ]; then
    echo "Usage: `basename $0` [image] [tag]"
    exit 1
fi

IMAGE="$1"
TAG="$2"
FUNC_NAME="${IMAGE}"

if [[ -z "${IMAGE_REGISTRY}" ]]; then
    echo "Error: please set IMAGE_REGISTRY environment variable e.g. <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com"
    exit 1
fi

IMAGE_URI="${IMAGE_REGISTRY}/${IMAGE}:${TAG}"

echo "Building docker image"
docker build -t ${IMAGE} . \
  && docker tag ${IMAGE}:${TAG} ${IMAGE_URI}

# Find out if the repository already exist
# If not, create it first before pushing the image.
aws ecr describe-repositories --output yaml 2>&1 |grep "repositoryName: ${FUNC_NAME}$" >/dev/null
if [ $? -ne 0 ]         # does not exist?
then
    echo "Repository does not exist... creating one automatically."
    aws ecr create-repository --repository-name "${FUNC_NAME}"
fi

# Push image now!
docker push ${IMAGE_URI}

# Find out if the function already exist.
aws lambda get-function-configuration --function-name ${FUNC_NAME} --output yaml 2>&1|grep FunctionName
if [ $? -eq 0 ]
then
    aws lambda update-function-code --function-name ${FUNC_NAME} --image-uri ${IMAGE_URI} --publish
else
    echo "Lambda function does not exist yet. Please create it first before deploying."
fi
