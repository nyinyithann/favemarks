#!/bin/bash

set -e

INSTALL_DIR="/usr/local/bin"

set_filename() {
  local OS

  OS=$(uname -s)

  if [ "$OS" == "Linux" ]; then
    FILENAME="fm-linux-x64"
    INSTALL_DIR="/usr/bin"
  elif [ "$OS" == "Darwin" ]; then
    FILENAME="fm-darwin-x64"
  else
    echo "OS $OS is not supported."
    exit 1
  fi
}

download_spin() {
  URL=https://github.com/nyinyithann/favemarks/releases/download/0.0.1/$FILENAME.zip

  DOWNLOAD_DIR=$(mktemp -d)

  echo "Downloading $URL..."

  mkdir -p "$INSTALL_DIR" &>/dev/null
  curl --progress-bar -L "$URL" -o "$DOWNLOAD_DIR/$FILENAME.zip"

  if [ 0 -ne "$?" ]; then
    echo "Download failed. Check that the release/filename are correct."
    exit 1
  fi

  unzip -q "$DOWNLOAD_DIR/$FILENAME.zip" -d "$DOWNLOAD_DIR"
  mv "$DOWNLOAD_DIR/main.exe" "$INSTALL_DIR/fm"
  chmod u+x "$INSTALL_DIR/fm"
}

check_dependencies() {
  echo "Checking dependencies for the installation script..."

  echo -n "Checking availability of curl... "
  if hash curl 2>/dev/null; then
    echo "OK!"
  else
    echo "Missing!"
    SHOULD_EXIT="true"
  fi

  echo -n "Checking availability of unzip... "
  if hash unzip 2>/dev/null; then
    echo "OK!"
  else
    echo "Missing!"
    SHOULD_EXIT="true"
  fi

  if [ "$SHOULD_EXIT" = "true" ]; then
    exit 1
  fi
}

set_filename
check_dependencies
download_spin
