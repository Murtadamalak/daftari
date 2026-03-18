#!/bin/bash

echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release

echo "Build complete."
