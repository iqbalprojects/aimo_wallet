#!/bin/bash

# Production Release Build Script
# 
# This script builds the app for production with all security features enabled.
# 
# Usage:
#   ./build_release.sh android
#   ./build_release.sh ios
#   ./build_release.sh all

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Aimo Wallet"
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building $APP_NAME v$VERSION${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if environment variables are set
check_env_vars() {
    echo -e "${YELLOW}Checking environment variables...${NC}"
    
    if [ -z "$ETHEREUM_RPC_URL" ]; then
        echo -e "${RED}ERROR: ETHEREUM_RPC_URL not set${NC}"
        echo "Set it with: export ETHEREUM_RPC_URL=https://..."
        exit 1
    fi
    
    if [ -z "$SEPOLIA_RPC_URL" ]; then
        echo -e "${RED}ERROR: SEPOLIA_RPC_URL not set${NC}"
        echo "Set it with: export SEPOLIA_RPC_URL=https://..."
        exit 1
    fi
    
    echo -e "${GREEN}✓ Environment variables OK${NC}"
    echo ""
}

# Clean build artifacts
clean_build() {
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    flutter clean
    flutter pub get
    echo -e "${GREEN}✓ Clean complete${NC}"
    echo ""
}

# Run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"
    flutter test
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Tests failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All tests passed${NC}"
    echo ""
}

# Build Android
build_android() {
    echo -e "${YELLOW}Building Android release...${NC}"
    
    # Build APK with obfuscation
    flutter build apk \
        --release \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols \
        --dart-define=ETHEREUM_RPC_URL=$ETHEREUM_RPC_URL \
        --dart-define=SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL
    
    # Build App Bundle with obfuscation
    flutter build appbundle \
        --release \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols \
        --dart-define=ETHEREUM_RPC_URL=$ETHEREUM_RPC_URL \
        --dart-define=SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL
    
    echo -e "${GREEN}✓ Android build complete${NC}"
    echo ""
    echo "APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "AAB: build/app/outputs/bundle/release/app-release.aab"
    echo "Symbols: build/app/outputs/symbols"
    echo ""
}

# Build iOS
build_ios() {
    echo -e "${YELLOW}Building iOS release...${NC}"
    
    flutter build ios \
        --release \
        --obfuscate \
        --split-debug-info=build/ios/outputs/symbols \
        --dart-define=ETHEREUM_RPC_URL=$ETHEREUM_RPC_URL \
        --dart-define=SEPOLIA_RPC_URL=$SEPOLIA_RPC_URL
    
    echo -e "${GREEN}✓ iOS build complete${NC}"
    echo ""
    echo "IPA: build/ios/iphoneos/Runner.app"
    echo "Symbols: build/ios/outputs/symbols"
    echo ""
    echo "Next steps:"
    echo "1. Open ios/Runner.xcworkspace in Xcode"
    echo "2. Archive the app (Product > Archive)"
    echo "3. Upload to App Store Connect"
    echo ""
}

# Main script
main() {
    local platform=$1
    
    if [ -z "$platform" ]; then
        echo "Usage: $0 [android|ios|all]"
        exit 1
    fi
    
    # Check environment variables
    check_env_vars
    
    # Clean build
    clean_build
    
    # Run tests
    run_tests
    
    # Build based on platform
    case $platform in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        all)
            build_android
            build_ios
            ;;
        *)
            echo -e "${RED}ERROR: Invalid platform '$platform'${NC}"
            echo "Usage: $0 [android|ios|all]"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "IMPORTANT: Store symbol files for crash reporting"
    echo "  Android: build/app/outputs/symbols"
    echo "  iOS: build/ios/outputs/symbols"
    echo ""
}

# Run main script
main "$@"
