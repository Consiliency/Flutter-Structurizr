#!/usr/bin/env bash

echo "=== Splitting large files for GitHub ==="

cd .codex

# Split flutter-sdk.tar.gz into 95MB chunks
echo "Splitting flutter-sdk.tar.gz..."
split -b 95M flutter-sdk.tar.gz flutter-sdk.tar.gz.part.

# Split pub-cache.tar.gz into 95MB chunks  
echo "Splitting pub-cache.tar.gz..."
split -b 95M pub-cache.tar.gz pub-cache.tar.gz.part.

# Create a script to reassemble them
cat > reassemble.sh << 'EOF'
#!/usr/bin/env bash
echo "Reassembling split files..."
cat flutter-sdk.tar.gz.part.* > flutter-sdk.tar.gz
cat pub-cache.tar.gz.part.* > pub-cache.tar.gz
echo "Files reassembled successfully"
EOF

chmod +x reassemble.sh

# Remove original large files
rm flutter-sdk.tar.gz pub-cache.tar.gz

echo "Files split successfully. Use reassemble.sh to rebuild them."