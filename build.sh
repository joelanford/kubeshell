#!/bin/bash
set -e

DOCKER_ORG=joelanford
DOCKER_IMAGE=kubeshell
KUBECTL_VERSION=v1.7.0

function build() {
    setGitInfo
    IMAGE_VERSION="${KUBECTL_VERSION}-$(getVersion)"

    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    docker build -t ${DOCKER_ORG}/${DOCKER_IMAGE}:${IMAGE_VERSION} -f ${DIR}/Dockerfile --build-arg KUBECTL_VERSION=${KUBECTL_VERSION} ${DIR}

    if [[ $GIT_DIRTY == "false" ]]; then
        if [[ $GIT_BRANCH == "master" ]]; then
            docker tag ${DOCKER_ORG}/${DOCKER_IMAGE}:${IMAGE_VERSION} ${DOCKER_ORG}/${DOCKER_IMAGE}:${KUBECTL_VERSION}-latest
            docker push ${DOCKER_ORG}/${DOCKER_IMAGE}:${IMAGE_VERSION}
            docker push ${DOCKER_ORG}/${DOCKER_IMAGE}:${KUBECTL_VERSION}-latest
        elif [[ $GIT_BRANCH == release/* && $IMAGE_VERSION != *pre* ]]; then
            docker push ${DOCKER_ORG}/${DOCKER_IMAGE}:${IMAGE_VERSION}
        elif [[ $GIT_BRANCH == "develop" ]]; then
            docker tag ${DOCKER_ORG}/${DOCKER_IMAGE}:${IMAGE_VERSION} ${DOCKER_ORG}/${DOCKER_IMAGE}:${KUBECTL_VERSION}-beta
            docker push ${DOCKER_ORG}/${DOCKER_IMAGE}:${KUBECTL_VERSION}-beta
        fi
    fi
}

function getVersion() {
    setGitInfo

    local version=""
    if [[ $GIT_BRANCH == "master" ]]; then
        version="${GIT_LAST_VERSION}"
        if [[ $GIT_COMMITS_SINCE_LAST_TAG != "0" ]]; then
            version="${version}-${GIT_COMMITS_SINCE_LAST_TAG}"
        fi
    elif [[ $GIT_BRANCH == release/* ]]; then
        GIT_NEXT_VERSION=${GIT_BRANCH#release/}
        if [[ $GIT_LAST_VERSION == ${GIT_NEXT_VERSION}-rc* ]]; then
            thisRc=${GIT_LAST_VERSION#${GIT_NEXT_VERSION}-rc}
            if [[ $GIT_COMMITS_SINCE_LAST_TAG == "0" ]]; then
                version=${GIT_NEXT_VERSION}-rc${thisRc}
            else
                nextRc=$((thisRc+1))
                version=${GIT_NEXT_VERSION}-rc${nextRc}
            fi
        else
            version="${GIT_NEXT_VERSION}-rc1"
        fi
        if [[ $GIT_COMMITS_SINCE_LAST_TAG != "0" ]]; then
            version="${version}.pre.${GIT_COMMIT_HASH}"
        fi
    elif [[ $GIT_BRANCH == feature/* ]]; then
        GIT_FEATURE=${GIT_BRANCH#feature/}
        version="${GIT_NEXT_VERSION}-feature-${GIT_FEATURE}.${GIT_COMMIT_HASH}"
    elif [[ $GIT_BRANCH == "develop" ]]; then
        version="${GIT_NEXT_VERSION}-develop.${GIT_COMMIT_HASH}"
    fi

    if [[ $GIT_DIRTY == "true" ]]; then
        version="${version}-dirty"
    fi

    echo $version
}


function setGitInfo() {
    GIT_BRANCH="$((git symbolic-ref HEAD 2>/dev/null || echo undefined) | sed 's|refs/heads/||')"
    GIT_LAST_VERSION="$(git describe --abbrev=0 2>/dev/null || echo 0.0.0)"
    if [[ "$GIT_LAST_VERSION" = "0.0.0" ]]; then
        GIT_COMMITS_SINCE_LAST_TAG=0
    else 
        GIT_COMMITS_SINCE_LAST_TAG="$(git rev-list  `git rev-list --tags --no-walk --max-count=1`..HEAD --count)"
    fi
    GIT_COMMITS_SINCE_DEVELOP="$(( $(git rev-list --count develop...HEAD)+1 ))"
    GIT_COMMIT_HASH="$(git rev-parse --short HEAD)"
    [[ -n "$(git status --porcelain)" ]] && GIT_DIRTY="true" || GIT_DIRTY="false"

    local version_bits=(${GIT_LAST_VERSION//./ })
    local major=${version_bits[0]}
    local minor=${version_bits[1]}
    minor=$((minor+1))

    GIT_NEXT_VERSION="${major}.${minor}.0"
}

build
