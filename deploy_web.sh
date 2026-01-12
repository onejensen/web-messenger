#!/bin/bash

# Configuration
GITHUB_USER="onejensen" # Change this if needed
REPO_NAME="web-messenger"
BACKEND_URL="https://web-messenger-api.onrender.com" 
echo "🚀 Starting Web Deployment..."

# 1. Update config.dart for production
echo "📝 Updating config.dart with production URL..."
# Replace whatever is in the return '...' line for kIsWeb or the default return
sed -i '' "s|return 'http.*';|return '$BACKEND_URL';|g" frontend/lib/config/config.dart

# 2. Build for Web
echo "📦 Building Flutter Web..."
cd frontend
flutter build web --release --base-href "/$REPO_NAME/" || { echo "❌ Build failed"; exit 1; }

# 3. Create a temporary folder for deployment
echo "📂 Preparing gh-pages branch..."
cd build/web

# 4. Initialize git and push to gh-pages
git init
git add .
git commit -m "Deploy to GitHub Pages"
git branch -M gh-pages
# Use the URL directly to avoid remote name conflicts
git remote add origin https://github.com/onejensen/web-messenger.git
git push -f origin gh-pages

echo "✅ Web version deployed! It should be live at: https://onejensen.github.io/web-messenger/"
echo "💡 IMPORTANT: Go to your repo Settings > Pages and set 'Source' to 'Deploy from a branch' and select 'gh-pages'."

# 5. Revert config.dart for local development
echo "🔄 Reverting config.dart to localhost..."
cd ../../../
sed -i '' "s|return '$BACKEND_URL';|return 'http://localhost:3000';|g" frontend/lib/config/config.dart

echo "Done!"
