#!/usr/bin/env bash

# send.sh - Send FCM push notifications using a Google service account
# Usage: ./send.sh
# Requires: google-services-account.json, message.json in same directory

set -euo pipefail

# Parse args
KEY_FILE="google-services-account.json"
MESSAGE_FILE="message.json"

# check files
for f in "$KEY_FILE" "$MESSAGE_FILE"; do
  [[ -f $f ]] || { echo "Missing file: $f" >&2; exit 1; }
done

# Extract project_id and client_email
PROJECT_ID=$(jq -r .project_id "$KEY_FILE")
CLIENT_EMAIL=$(jq -r .client_email "$KEY_FILE")
PRIVATE_KEY=$(jq -r .private_key "$KEY_FILE")

# OAuth2 JWT params
OAUTH_URI="https://oauth2.googleapis.com/token"
SCOPE="https://www.googleapis.com/auth/firebase.messaging"
NOW=$(date +%s)
EXP=$(($NOW + 3600))

# Build JWT header & claimset
HEADER='{"alg":"RS256","typ":"JWT"}'
CLAIMS=$(jq -n --arg iss "$CLIENT_EMAIL" \
               --arg scope "$SCOPE" \
               --arg aud "$OAUTH_URI" \
               --arg iat "$NOW" \
               --arg exp "$EXP" \
               '{iss:$iss,scope:$scope,aud:$aud,iat:(($iat|tonumber)),exp:(($exp|tonumber))}')

# Base64-URL encode
base64url() { openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }
H64=$(echo -n "$HEADER" | base64url)
C64=$(echo -n "$CLAIMS" | base64url)
UNSIGNED_JWT="$H64.$C64"

# Sign JWT
SIGNATURE=$(echo -n "$UNSIGNED_JWT" \
  | openssl dgst -sha256 -sign <(echo "$PRIVATE_KEY") \
  | base64url)

JWT="$UNSIGNED_JWT.$SIGNATURE"

# Exchange JWT for access token
ACCESS_TOKEN=$(curl -s \
  -X POST "$OAUTH_URI" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  --data-urlencode "assertion=$JWT" \
  | jq -r .access_token)

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "Failed to retrieve access token." >&2
  exit 1
fi

# Send FCM message
FCM_URL="https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send"
curl -s -X POST "$FCM_URL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @"$MESSAGE_FILE" \
  | jq .

