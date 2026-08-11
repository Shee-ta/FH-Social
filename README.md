# FH_Social

This app is a project by a student. Flaws are to be expected.

The app requires a backend running on the same device or in the same local network as the frontend device. Those instructions assume the user uses an Android phone.

Test usernames are "lily", "angel", "elise", "trish" and "sky". The password always is "123".

## 1. Creating the app

To run it on web, go to /frontend and execute

```sh
flutter run -d web-server --release
```

For Android, execute 

```sh
flutter build apk --release
```
This will build an apk-file in build/app/outputs/flutter-apk/app-release.apk. Move the file to your phone and open it to install the app. 

## 2. Backend setup

Open /backend and execute

```sh
docker builder prune -a && docker compose down -v && docker compose up -d --build
```

This will create containers for the database and backend. Docker Desktop has to be installed and running.

## 3. AI setup

Install Ollama (https://ollama.com/download), then execute 

```sh
ollama run phi4-mini
```
in a terminal to download a local model. While Ollama is running, the backend will automatically connect to the model. Ollama and the backend must run on the same device.

## 4. Connect to backend

If the client is running on another decive than the backend, find the local IPv4 address of the backend device, e.g. 192.168.0.81. 

Open the frontend, go to the /settings/backend-url route and set the backend-url to the LAN IP you found above. The listening port is 3000.
