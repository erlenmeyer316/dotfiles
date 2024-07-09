#!/usr/bin/env bash
GO_CMD=go

if ! command -v -- "$GO_CMD" > /dev/null 2>&1; then
   # https://gist.github.com/codenoid/4806365032bb4ed62f381d8a76ddb8e6
   printf "Checking latest Go version...\n";
   LATEST_GO_VERSION="$(curl --silent https://go.dev/VERSION?m=text | head -n 1)";
   LATEST_GO_DOWNLOAD_URL="https://go.dev/dl/${LATEST_GO_VERSION}.linux-amd64.tar.gz"

   cd $HOME

   printf "Downloading ${LATEST_GO_DOWNLOAD_URL}\n\n";
   curl -OJ -L --progress-bar $LATEST_GO_DOWNLOAD_URL

   printf "Extracting file...\n"
   tar -xf ${LATEST_GO_VERSION}.linux-amd64.tar.gz
   
   rm ${LATEST_GO_VERSION}.linux-amd64.tar.gz
   
   export GOROOT="$HOME/go"
   export GOPATH="$HOME/go/packages"
   export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
fi
