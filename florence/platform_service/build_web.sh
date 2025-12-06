#!/bin/bash

echo "----------------------------------------------------------------"
echo "  FLORENCE WEB BUILD SCRIPT"
echo "----------------------------------------------------------------"

# 1. Install Flutter (Clone stable channel)
if [ -d "flutter" ]; then
    echo "Flutter already exists, skipping clone."
else
    echo "Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Print Version
flutter --version

# 4. Enable Web
flutter config --enable-web

# 5. Build
# We pass the Environment Variables (that you set in Vercel UI) to Dart
echo "Building Flutter Web..."
flutter build web --release \
  --dart-define=DATA_SERVICE_URL=$DATA_SERVICE_URL \
  --dart-define=LLM_CHATBOT_SERVICE_URL=$LLM_CHATBOT_SERVICE_URL

echo "Build Complete!"