#!/bin/sh

echo "--- 📚 Swift DocC Documentation Generation Started ---"

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
DOCS_DIR="${PROJECT_DIR}/docs"
BUILD_DIR="${PROJECT_DIR}/.build"

mkdir -p "${DOCS_DIR}"
mkdir -p "${BUILD_DIR}"

echo "- Cleaning previous documentation -"
rm -rf "${DOCS_DIR}"/*

WORKSPACE=$(find "${PROJECT_DIR}" -name "*.xcworkspace" -maxdepth 1 | head -n 1)

if [ -z "$WORKSPACE" ]; then
    echo "Error: No .xcworkspace file found in ${PROJECT_DIR}"
    exit 1
fi

WORKSPACE_NAME=$(basename "$WORKSPACE" .xcworkspace)
echo "- Found workspace: ${WORKSPACE_NAME} -"

echo "- Generating documentation for Fusion framework -"

SCHEME="Fusion"
DESTINATION="generic/platform=iOS"

echo "- Building documentation archive for ${SCHEME} -"
xcodebuild docbuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -allowProvisioningUpdates \
    2>&1 | grep -E "(error|warning|Building|Generating|Archive)" || true

echo "- Searching for generated documentation archives -"
ARCHIVE_PATH=$(find "${BUILD_DIR}/DerivedData" -name "*.doccarchive" -type d 2>/dev/null | head -n 1)

if [ -z "$ARCHIVE_PATH" ]; then
    DERIVED_DATA_BASE="${HOME}/Library/Developer/Xcode/DerivedData"
    ARCHIVE_PATH=$(find "${DERIVED_DATA_BASE}" -name "*.doccarchive" -type d -path "*${WORKSPACE_NAME}*" 2>/dev/null | head -n 1)
fi

if [ -z "$ARCHIVE_PATH" ] || [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Warning: No documentation archive found in build directories"
    echo "- Trying Swift Package Manager as fallback -"
    
    if command -v swift >/dev/null 2>&1; then
        cd "${PROJECT_DIR}"
        swift package clean 2>/dev/null || true
        
        swift package generate-documentation \
            --target Fusion \
            --output-path "${BUILD_DIR}/Fusion.doccarchive" 2>&1 | grep -E "(error|warning|Building|Generating)" || true
        
        ARCHIVE_PATH="${BUILD_DIR}/Fusion.doccarchive"
    fi
fi

if [ -n "$ARCHIVE_PATH" ] && [ -d "$ARCHIVE_PATH" ]; then
    echo "- Found documentation archive: ${ARCHIVE_PATH} -"
    
    ARCHIVE_NAME=$(basename "$ARCHIVE_PATH")
    cp -R "${ARCHIVE_PATH}" "${DOCS_DIR}/${ARCHIVE_NAME}"
    
    echo "- Extracting HTML from documentation archive -"
    
    DOCC=$(xcrun --find docc 2>/dev/null || echo "")
    
    if [ -n "$DOCC" ] && [ -f "$DOCC" ]; then
        echo "- Processing ${ARCHIVE_NAME} -"
        "${DOCC}" process-archive \
            transform-for-static-hosting "${DOCS_DIR}/${ARCHIVE_NAME}" \
            --output-path "${DOCS_DIR}/html" \
            --hosting-base-path "/fusion" 2>&1 | grep -E "(error|warning|Processing)" || true
        
        if [ -d "${DOCS_DIR}/html" ]; then
            echo "- HTML documentation available in: ${DOCS_DIR}/html"
            echo "- Verifying HTML output..."
            if [ -f "${DOCS_DIR}/html/index.html" ]; then
                echo "✓ index.html found"
            else
                echo "⚠ Warning: index.html not found, checking for data directory..."
                ls -la "${DOCS_DIR}/html/" | head -10
            fi
        fi
    else
        echo "- DocC tool not found, skipping HTML extraction -"
        echo "- Documentation archive available at: ${DOCS_DIR}/${ARCHIVE_NAME}"
    fi
    
    echo "- Documentation generation completed -"
    echo ""
    echo "📦 Documentation Archive:"
    echo "   Location: ${DOCS_DIR}/${ARCHIVE_NAME}"
    echo "   Usage: Double-click to install in Xcode, or import via Xcode > Settings > Locations > Documentation"
    echo ""
    if [ -d "${DOCS_DIR}/html" ]; then
        echo "🌐 HTML Documentation:"
        echo "   Location: ${DOCS_DIR}/html"
        echo "   Usage: Deploy to GitHub Pages or any static web server"
        echo ""
    fi
    echo "💡 Tip: Press ⇧⌘0 in Xcode to open the documentation viewer after installing the archive"
else
    echo "Error: No documentation archive found. Please check build logs for errors."
    echo "- Searched in: ${BUILD_DIR}/DerivedData"
    echo "- Also searched in: ${HOME}/Library/Developer/Xcode/DerivedData"
    exit 1
fi

echo "--- ✅ Documentation Generation Complete ---"
