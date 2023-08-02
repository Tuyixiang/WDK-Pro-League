#!/bin/sh
flutter build web --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/

rm -rf ../backend/static

mkdir ../backend/static

cp -r build/web/* ../backend/static
