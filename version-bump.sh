#!/bin/bash

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#
# Takes a version number, and the mode to bump it, and increments/resets
# the proper components so that the result is placed in the variable
# `NEW_VERSION`.
#
# $1 = mode (major, minor, patch)
# $2 = version (x.y.z[-suffix])
#
function bump {
  local mode="$1"
  local old="$2"

  old="${old%%-*}"

  local parts=( ${old//./ } )
  case "$1" in
    major)
      local bv=$((parts[0] + 1))
      NEW_VERSION="${bv}.0.0-SNAPSHOT"
      ;;
    minor)
      local bv=$((parts[1] + 1))
      NEW_VERSION="${parts[0]}.${bv}.0-SNAPSHOT"
      ;;
    patch)
      local bv=$((parts[2] + 1))
      NEW_VERSION="${parts[0]}.${parts[1]}.${bv}-SNAPSHOT"
      ;;
    release)
      NEW_VERSION="${old}"
      ;;
    esac
}

git config --global user.email github-actions[bot]@users.noreply.github.com
git config --global user.name Version Updater[bot]

OLD_VERSION=$($DIR/get-version.sh)
BUMP_MODE="none"

case "$TYPE" in
  major)
    BUMP_MODE="major"
    ;;
  minor)
    BUMP_MODE="minor"
    ;;
  patch)
    BUMP_MODE="patch"
    ;;
  release)
    BUMP_MODE="release"
    ;;
esac

if [[ "${BUMP_MODE}" == "none" ]]
then
  echo "ERROR: "
  exit 1
else
  echo $BUMP_MODE "version bump detected"
  bump $BUMP_MODE $OLD_VERSION
  echo "pom.xml at" $POMPATH "will be bumped from" $OLD_VERSION "to" $NEW_VERSION
  mvn --file $POMPATH/pom.xml -q versions:set -DnewVersion="${NEW_VERSION}"
  git add $POMPATH/pom.xml
  REPO="https://$GITHUB_ACTOR:$TOKEN@github.com/$GITHUB_REPOSITORY.git"
  if [ "$TYPE" == "release" ]; then
      git commit -m "release($NEW_VERSION)"
  else
      git commit -m "snapshot($NEW_VERSION)"
  fi
  git tag $NEW_VERSION
  git push $REPO --follow-tags
  git push $REPO --tags
fi
