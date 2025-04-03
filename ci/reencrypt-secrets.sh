#!/bin/bash

TARGET_FOLDER="quotes-flask"

find "$TARGET_FOLDER" -type f -name "*sealed*" | while read -r FILE; do
  echo "Re-encrypting: $FILE"
  
  kubeseal --re-encrypt -o yaml < "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
  
  if [ $? -eq 0 ]; then
    echo "Successfully re-encrypted: $FILE"
  else
    echo "Failed to re-encrypt: $FILE"
    rm -f "$FILE.tmp"
  fi
done