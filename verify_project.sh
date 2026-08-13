#!/bin/bash
# Emergency Mesh - Build Verification Script
# Checks project structure and validates all required files

echo "═══════════════════════════════════════════════════════"
echo "  Emergency Mesh - Build Verification"
echo "═══════════════════════════════════════════════════════"
echo ""

PROJECT_ROOT="/home/rohan/Desktop/flame-courses/imp/EmergencyMesh"
cd "$PROJECT_ROOT" || exit 1

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track status
ERRORS=0
WARNINGS=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        ((ERRORS++))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ - MISSING"
        ((ERRORS++))
        return 1
    fi
}

echo "1. Checking Project Configuration Files..."
echo "─────────────────────────────────────────"
check_file "build.gradle"
check_file "settings.gradle"
check_file "gradle.properties"
check_file "gradle/wrapper/gradle-wrapper.properties"
check_file "app/build.gradle"
check_file "app/proguard-rules.pro"
echo ""

echo "2. Checking Android Manifest..."
echo "─────────────────────────────────────────"
check_file "app/src/main/AndroidManifest.xml"
echo ""

echo "3. Checking Core Application Files..."
echo "─────────────────────────────────────────"
check_file "app/src/main/java/com/emergency/mesh/MainActivity.kt"
echo ""

echo "4. Checking Model Classes..."
echo "─────────────────────────────────────────"
check_file "app/src/main/java/com/emergency/mesh/models/MeshMessage.kt"
check_file "app/src/main/java/com/emergency/mesh/models/MeshPeer.kt"
check_file "app/src/main/java/com/emergency/mesh/models/UserRole.kt"
echo ""

echo "5. Checking Network Layer..."
echo "─────────────────────────────────────────"
check_file "app/src/main/java/com/emergency/mesh/network/BLEManager.kt"
check_file "app/src/main/java/com/emergency/mesh/network/WiFiDirectManager.kt"
check_file "app/src/main/java/com/emergency/mesh/network/ConnectionManager.kt"
echo ""

echo "6. Checking Handler Layer..."
echo "─────────────────────────────────────────"
check_file "app/src/main/java/com/emergency/mesh/handlers/MessageHandler.kt"
check_file "app/src/main/java/com/emergency/mesh/handlers/VoiceHandler.kt"
echo ""

echo "7. Checking Services..."
echo "─────────────────────────────────────────"
check_file "app/src/main/java/com/emergency/mesh/services/MeshService.kt"
echo ""

echo "8. Checking Resources..."
echo "─────────────────────────────────────────"
check_file "app/src/main/res/layout/activity_main.xml"
check_file "app/src/main/res/values/strings.xml"
check_file "app/src/main/res/values/themes.xml"
echo ""

echo "9. Checking Documentation..."
echo "─────────────────────────────────────────"
check_file "README.md"
check_file "ARCHITECTURE.md"
check_file "QUICKSTART.md"
check_file "PROJECT_SUMMARY.md"
check_file "COMPARISON.md"
check_file "ICONS.md"
echo ""

echo "10. Checking for Common Issues..."
echo "─────────────────────────────────────────"

# Check for R.id references in MainActivity
if grep -q "R\.id\." app/src/main/java/com/emergency/mesh/MainActivity.kt 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MainActivity references UI components"
else
    echo -e "${YELLOW}⚠${NC} MainActivity might be missing UI references"
    ((WARNINGS++))
fi

# Count Kotlin files
KOTLIN_FILES=$(find app/src/main/java -name "*.kt" 2>/dev/null | wc -l)
echo -e "${GREEN}✓${NC} Found $KOTLIN_FILES Kotlin source files"

# Count XML files
XML_FILES=$(find app/src/main/res -name "*.xml" 2>/dev/null | wc -l)
echo -e "${GREEN}✓${NC} Found $XML_FILES XML resource files"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Verification Summary"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All required files present!${NC}"
else
    echo -e "${RED}✗ Found $ERRORS missing file(s)${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s)${NC}"
fi

echo ""
echo "Project Statistics:"
echo "  - Kotlin files: $KOTLIN_FILES"
echo "  - XML files: $XML_FILES"
echo "  - Documentation files: 6"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "Next Steps:"
    echo "  1. Open project in Android Studio"
    echo "  2. Wait for Gradle sync to complete"
    echo "  3. Build project: ./gradlew build"
    echo "  4. Install on device: ./gradlew installDebug"
    echo ""
    echo "See QUICKSTART.md for detailed instructions."
    exit 0
else
    echo "Please fix missing files before building."
    exit 1
fi
