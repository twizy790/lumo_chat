# LumoChat

Flutter messenger MVP for coursework.

## Features

- registration and login
- profile editing with avatar and bio
- search users by name
- direct and group dialogs
- text and image messages
- read receipts
- dark and light themes
- local persistence so chats survive re-login

## Run

```bash
flutter pub get
flutter run
```

## Notes

- Passwords are stored as a hash, not plain text.
- Images are saved as base64 data in local storage for the demo build.
- The app is structured so it can be swapped to Firebase or a REST backend later.
