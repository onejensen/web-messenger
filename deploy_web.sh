#!/bin/bash

# Configuration
GITHUB_USER="onejensen" # Change this if needed
REPO_NAME="web-messenger"
BACKEND_URL="https://your-backend-url.onrender.com" # Change this after deploying backend

echo "🚀 Starting Web Deployment..."

# 1. Update config.dart for production
echo "📝 Updating config.dart with production URL..."
sed -i '' "s|http://localhost:3000|$BACKEND_URL|g" frontend/lib/config/config.dart

# 2. Build for Web
echo "📦 Building Flutter Web..."
cd frontend
flutter build web --release --base-href "/$REPO_NAME/"

# 3. Create a temporary folder for deployment
echo "📂 Preparing gh-pages branch..."
cd build/web

# 4. Initialize git and push to gh-pages
git init
git add .
git commit -m "Deploy to GitHub Pages"
git branch -M gh-pages
git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git
git push -f origin gh-pages

echo "✅ Web version deployed! It should be live at: https://$GITHUB_USER.github.io/$REPO_NAME/"

# 5. Revert config.dart for local development
echo "🔄 Reverting config.dart to localhost..."
cd ../../../
sed -i '' "s|$BACKEND_URL|http://localhost:3000|g" frontend/lib/config/config.dart

echo "Done!"
