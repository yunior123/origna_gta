#!/bin/bash

# Deploy script for Origna Ventures to Firebase Hosting
# This script builds the Flutter web app and deploys it to Firebase

set -e

echo "🚀 Starting deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠ Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi

echo -e "${GREEN}✓ Firebase CLI ready${NC}"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build failed. build/web directory not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

# Deploy to Firebase
echo "🌐 Deploying to Firebase Hosting..."

firebase deploy --only hosting

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo -e "${GREEN}Your site is live at: https://orignaventures.ca${NC}"
