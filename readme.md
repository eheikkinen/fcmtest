# send.sh

Simple Bash script to send Firebase Cloud Messaging (FCM) notifications using a Google service account.

## Requirements

* **Service account key** (`google-services-account.json`) with `project_id`, `client_email`, and `private_key`.
* **Message payload** (`message.json`) containing the FCM message and device token.
* Installed tools: `bash`, `jq`, `openssl`, `curl`.

## Getting the Service Account Key

1. In the Google Cloud Console, navigate to **IAM & Admin > Service Accounts**.
2. Select or create a service account with the **Firebase Cloud Messaging API** role.
3. Under **Keys**, click **Add Key > Create new key**, choose **JSON**, and download the file.
4. Rename it to `google-services-account.json` and place it alongside `send.sh`.

## Usage

1. Make the script executable:

   ```bash
   chmod +x send.sh
   ```
2. Run:

   ```bash
   ./send.sh
   ```

## Workflow

1. Validates `google-services-account.json` and `message.json`.
2. Builds and signs a JWT for OAuth2.
3. Exchanges the JWT for an access token.
4. Sends the FCM message and prints the JSON response.

## Example `message.json`

```json
{
  "message": {
    "token": "DEVICE_TOKEN",
    "notification": {
      "title": "Hello",
      "body": "Test notification"
    }
  }
}
```

## Reference

* FCM message format and fields: [https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Message](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Message)
* Sending messages guide: [https://firebase.google.com/docs/cloud-messaging/send-message](https://firebase.google.com/docs/cloud-messaging/send-message)
