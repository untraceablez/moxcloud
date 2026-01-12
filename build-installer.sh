#!/bin/bash
#
# Build script for MoxCloud self-extracting installer
# This script creates a single self-extracting installer containing
# all necessary cloud-init template scripts.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="moxcloud-install.sh"
INSTALLER_BASE="moxcloud-installer.sh"
TEMP_DIR=$(mktemp -d)

echo "=========================================="
echo "   Building MoxCloud Installer"
echo "=========================================="
echo ""

# Check for required files
if [ ! -f "$SCRIPT_DIR/cloudinit/template-script.sh" ]; then
  echo "Error: cloudinit/template-script.sh not found"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/cloudinit/template-setup.sh" ]; then
  echo "Error: cloudinit/template-setup.sh not found"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/$INSTALLER_BASE" ]; then
  echo "Error: $INSTALLER_BASE not found"
  exit 1
fi

echo "Creating temporary directory: $TEMP_DIR"

# Copy scripts to temp directory
echo "Copying scripts..."
cp "$SCRIPT_DIR/cloudinit/template-script.sh" "$TEMP_DIR/"
cp "$SCRIPT_DIR/cloudinit/template-setup.sh" "$TEMP_DIR/"

# Create tar archive
echo "Creating archive..."
cd "$TEMP_DIR"
tar czf archive.tar.gz template-script.sh template-setup.sh

# Combine installer base with archive
echo "Building self-extracting installer..."
cd "$SCRIPT_DIR"
cat "$INSTALLER_BASE" "$TEMP_DIR/archive.tar.gz" > "$OUTPUT_FILE"
chmod +x "$OUTPUT_FILE"

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

# Get file size
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo ""
echo "=========================================="
echo "✓ Build complete!"
echo "=========================================="
echo ""
echo "Output file: $OUTPUT_FILE"
echo "Size: $FILE_SIZE"
echo ""
echo "You can now distribute this single file to users."
echo ""
echo "Users can run it with:"
echo "  bash $OUTPUT_FILE"
echo ""
echo "Or make it executable and run:"
echo "  chmod +x $OUTPUT_FILE"
echo "  ./$OUTPUT_FILE"
echo ""
