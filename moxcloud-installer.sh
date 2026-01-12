#!/bin/bash
#
# MoxCloud Self-Extracting Installer
# This script contains the cloud-init template setup scripts embedded within.
# Run this script to extract and install the MoxCloud template tools.
#
# Usage: ./moxcloud-installer.sh [OPTIONS]
#
# OPTIONS:
#   --extract-only    Extract files to current directory without running setup
#   --install-dir DIR Install to specified directory (default: ./moxcloud)
#   --help            Show this help message
#

set -e

# --- Configuration ---
DEFAULT_INSTALL_DIR="./moxcloud"
INSTALL_DIR=""
EXTRACT_ONLY=false

# --- Parse Arguments ---
show_help() {
  cat << EOF
MoxCloud Self-Extracting Installer

Usage: $0 [OPTIONS]

OPTIONS:
  --extract-only       Extract files to current directory without running setup
  --install-dir DIR    Install to specified directory (default: $DEFAULT_INSTALL_DIR)
  --help              Show this help message

DESCRIPTION:
  This self-extracting installer will:
  1. Create the installation directory
  2. Extract template-script.sh and template-setup.sh
  3. Make scripts executable
  4. Optionally run the initial setup

After installation, you can run:
  cd $DEFAULT_INSTALL_DIR
  ./template-setup.sh    # Configure your template settings
  ./template-script.sh   # Create/update the cloud-init template

EOF
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --extract-only)
      EXTRACT_ONLY=true
      shift
      ;;
    --install-dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Set install directory
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi

# --- Functions ---
extract_files() {
  local target_dir="$1"

  echo "Creating installation directory: $target_dir"
  mkdir -p "$target_dir"

  echo "Extracting files to $target_dir..."

  # Find the line number where the archive starts
  ARCHIVE_LINE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")

  # Extract the archive
  tail -n +${ARCHIVE_LINE} "$0" | tar xzv -C "$target_dir"

  echo "Setting executable permissions..."
  chmod +x "$target_dir/template-script.sh"
  chmod +x "$target_dir/template-setup.sh"

  echo ""
  echo "✓ Installation complete!"
  echo ""
  echo "Files extracted to: $target_dir"
  echo ""
}

# --- Main Installation Logic ---
echo "=========================================="
echo "   MoxCloud Installer"
echo "=========================================="
echo ""

# Check if running on a Debian-based system
if ! command -v apt &> /dev/null; then
  echo "Warning: This script is designed for Debian/Ubuntu systems."
  echo "You may need to manually install dependencies (wget, libguestfs-tools)."
  echo ""
fi

# Extract files
extract_files "$INSTALL_DIR"

if [ "$EXTRACT_ONLY" = true ]; then
  echo "Files extracted. Use --help for next steps."
  exit 0
fi

# Offer to run setup
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Navigate to the installation directory:"
echo "   cd $INSTALL_DIR"
echo ""
echo "2. Review and customize the .env file (will be created on first run)"
echo ""
echo "3. Run the setup script:"
echo "   ./template-setup.sh"
echo ""
echo "4. Create your cloud-init template:"
echo "   ./template-script.sh"
echo ""

read -p "Would you like to run the setup now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  cd "$INSTALL_DIR"
  ./template-setup.sh

  echo ""
  echo "Setup complete! You can now run:"
  echo "  cd $INSTALL_DIR && ./template-script.sh"
else
  echo ""
  echo "You can run the setup later by executing:"
  echo "  cd $INSTALL_DIR && ./template-setup.sh"
fi

exit 0

__ARCHIVE_BELOW__
