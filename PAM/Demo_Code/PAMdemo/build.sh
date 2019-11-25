#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage: $0 version"
  exit 1
fi

VERSION=$1
IMAGE=pamdemo

echo $VERSION
echo $DOCKER_REGISTRY

docker build -t $IMAGE .
$(aws ecr get-login --no-include-email --region us-east-1)
docker tag $IMAGE $DOCKER_REGISTRY/$IMAGE:latest
docker tag $IMAGE $DOCKER_REGISTRY/$IMAGE:$VERSION
docker push $DOCKER_REGISTRY/$IMAGE:$VERSION
docker push $DOCKER_REGISTRY/$IMAGE:latest
