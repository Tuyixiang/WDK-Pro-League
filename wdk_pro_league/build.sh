#!/bin/sh
flutter build web --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://cdnjs.cloudflare.com/ajax/libs/canvaskit-wasm/0.38.2/

rm -rf ../backend/static

mkdir ../backend/static

cp -r build/web/* ../backend/static
