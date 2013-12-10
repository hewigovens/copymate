#!/bin/sh

openssl aes-256-cbc -k "$ENCRYPTION_SECRET" -in scripts/certs/developer_id.cer.enc -d -a -out scripts/certs/developer_id.cer
openssl aes-256-cbc -k "$ENCRYPTION_SECRET" -in scripts/certs/developer_id.p12.enc -d -a -out scripts/certs/developer_id.p12

security create-keychain -p travis travis-build.keychain

security import ./scripts/certs/apple.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
security import ./scripts/certs/dist.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
security import ./scripts/certs/dist.p12 -k ~/Library/Keychains/ios-build.keychain -P $KEY_PASSWORD -T /usr/bin/codesign