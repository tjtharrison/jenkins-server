#!/bin/bash

set -e
 
getVersion () {
    version=$(cat version)
    echo "Currently on version $version"
    echo ""
}

bumpVersion () {
    major=$(cat version | awk -F'.' {'print $1'})
    minor=$(cat version | awk -F'.' {'print $2'})

    read -p "Bump Major Version (y/n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        newMajor=$(( $major +1 ))
        newVersion="$newMajor.$minor"
        echo "$version bumped to $newVersion"
        echo "$newVersion" > version
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        newMinor=$(( $minor +1 ))
        newVersion="$major.$newMinor"
        echo "$version bumped to $newVersion"
        echo "$newVersion" > version
    else
        echo "Please enter y/n"
        exit 1
    fi
    echo "$newVersion"
}

doBuild () {
    cloudRegistry="eu.gcr.io/tjth-weblock"
    newImageName="jenkins-server:$newVersion"
    echo "Building $newImageName"
    sudo docker build . -t $newImageName
    sudo docker tag $newImageName $cloudRegistry/$newImageName
    sudo docker push "$cloudRegistry/$newImageName"
}

updateDeploy() {
    newVersion=$(cat version)
    echo "Updating Kubernetes Depoloyment"
    sed -i "s/jenkins-server:.*/jenkins-server:$newVersion\'/g" ./docker-compose.yml
    sed -i "s/jenkins-server:.*/jenkins-server:$newVersion/g" ./kubernetes/03-deployment.yaml
}

deployK8s() {
    read -p "Deploy to Kubernetes immediately? (y/n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl apply -f ./kubernetes/03-deployment.yaml
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        exit 0
    else
        echo "Please enter y/n"
        exit 1
    fi
}

commitGit() {
    echo "Pushing to Git"
    git add .
    git commit -m "Bumped version"
    git push
}

buildContainer () {
    getVersion
    bumpVersion
    doBuild
    updateDeploy $newVersion
    commitGit
    deployK8s
}

buildContainer