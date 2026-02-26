#!/bin/bash
set -e

echo "Downloading aarch64 resources..."
node scripts/prebuild.mjs aarch64-apple-darwin --force
mkdir -p .arm64_res
cp src-tauri/resources/clash-verge-service* .arm64_res/

echo "Downloading x86_64 resources..."
node scripts/prebuild.mjs x86_64-apple-darwin --force
mkdir -p .x86_64_res
cp src-tauri/resources/clash-verge-service* .x86_64_res/

echo "Lipo-ing clash-verge-service into universal binaries..."
lipo -create -output src-tauri/resources/clash-verge-service .arm64_res/clash-verge-service .x86_64_res/clash-verge-service
lipo -create -output src-tauri/resources/clash-verge-service-install .arm64_res/clash-verge-service-install .x86_64_res/clash-verge-service-install
lipo -create -output src-tauri/resources/clash-verge-service-uninstall .arm64_res/clash-verge-service-uninstall .x86_64_res/clash-verge-service-uninstall

echo "Done. You can now build universal."
