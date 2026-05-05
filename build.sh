#!/usr/bin/env bash
set -e

IMAGE="jehoshua02/claude-code"
VERSION=""
PUSH=false

for arg in "$@"; do
  case "$arg" in
    --push) PUSH=true ;;
    *) VERSION="$arg" ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "Usage: ./build.sh <version> [--push]"
  echo "  Example: ./build.sh 1.0.0"
  echo "  Example: ./build.sh 1.0.0 --push"
  exit 1
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: version must be semver (e.g. 1.0.0), got: $VERSION"
  exit 1
fi

echo "Building $IMAGE:$VERSION ..."
docker build \
  --tag "$IMAGE:$VERSION" \
  --tag "$IMAGE:latest" \
  .

echo ""
echo "Built:"
echo "  $IMAGE:$VERSION"
echo "  $IMAGE:latest"

echo ""
echo "Running tests..."
./test.sh
echo ""

if $PUSH; then
  echo ""
  echo "Pushing ..."
  docker push "$IMAGE:$VERSION"
  docker push "$IMAGE:latest"
  echo ""
  echo "Pushed:"
  echo "  $IMAGE:$VERSION"
  echo "  $IMAGE:latest"
else
  echo ""
  echo "To push: ./build.sh $VERSION --push"
fi
