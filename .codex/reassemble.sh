#!/usr/bin/env bash
echo "Reassembling split files..."
cat flutter-sdk.tar.gz.part.* > flutter-sdk.tar.gz
cat pub-cache.tar.gz.part.* > pub-cache.tar.gz
echo "Files reassembled successfully"
