# FH_Social

This app is a project by students. Flaws are to be expected.

The app requires a backend running in the same local network as the frontend device. Those instructions assume the user uses an Android phone.

If you already own the apk, skip paragaph 1.

## 1. Creating the app

Clone the repository and execute "flutter build apk --release" in /frontend. This will build an apk-file in build/app/outputs/flutter-apk/app-release.apk. Move the file to your phone and open it to install the app. 

## 2. Backend setup

Open /backend and execute

`docker builder prune -a && docker compose down -v && docker compose up -d --build`

This will create containers for the database and backend. Docker Desktop has to be installed and running.

## 3. Connecting server with frontend

Find the LAN IP of the device that runs the backend (for example, 192.168.1.42).

Open the app on your phone, go to the /settings/backend-url route and set the backend-url to the LAN IP you found above. The listening port is 3000

Alternatively, connect your phone with your backend machine (USB debugging has to be enabled) and execute 

```sh
flutter run -d <device-id> --dart-define=BACKEND_URL=http://<LAN IP>:3000
```

This will install the app on your phone and set the correct url value for the backend.

To run the backend and frontend on the same device, go to /frontend and execute

```sh
flutter run -d web-server
```

The app will automatically connect to the backend on localhost:3000