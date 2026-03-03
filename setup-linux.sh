#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up Yapster development environment for Linux"
echo "======================================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   exit 1
fi

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=${VERSION_ID:-"rolling"}
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
        DISTRO_VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        DISTRO_VERSION=$DISTRIB_RELEASE
    else
        DISTRO=$(uname -s)
        DISTRO_VERSION=$(uname -r)
    fi

    DISTRO=$(echo $DISTRO | tr '[:upper:]' '[:lower:]')
}

# Package manager functions
update_packages() {
    echo "📦 Updating system packages..."
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update
            ;;
        rhel|centos|fedora|almalinux|rocky)
            if command -v dnf &> /dev/null; then
                sudo dnf check-update || true
            else
                sudo yum check-update || true
            fi
            ;;
        *)
            echo "⚠️ Unsupported distribution: $DISTRO. Please install packages manually."
            ;;
    esac
}

install_packages() {
    local packages="$1"
    echo "📦 Installing required packages: $packages"
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get install -y $packages
            ;;
        rhel|centos|fedora|almalinux|rocky)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y $packages
            else
                sudo yum install -y $packages
            fi
            ;;
        *)
            echo "⚠️ Unsupported distribution: $DISTRO. Please install packages manually."
            ;;
    esac
}

# Detect distribution
detect_distro
echo "🔍 Detected distribution: $DISTRO ${DISTRO_VERSION:-"rolling"}"

# Check what's missing and needs installation
check_installation_needs() {
    NEEDS_NODE=false
    NEEDS_PYTHON=false
    NEEDS_GIT=false
    NEEDS_ROBOT=false
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        NEEDS_NODE=true
    else
        NODE_VERSION=$(node --version)
        if [ "$NODE_VERSION" != "v22.20.0" ]; then
            echo "⚠️  Node.js $NODE_VERSION found, but v22.20.0 is recommended"
        fi
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        NEEDS_PYTHON=true
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        NEEDS_GIT=true
    fi
    
    # Check Robot Framework
    if [ ! -d "atests/.venv" ] || ! atests/.venv/bin/python -m robot --version &> /dev/null; then
        NEEDS_ROBOT=true
    else
        # Check if Browser Library is installed
        if ! atests/.venv/bin/python -c 'import Browser' &> /dev/null; then
            NEEDS_ROBOT=true
        fi
    fi
}

# Function to setup Robot Framework
setup_robot_framework() {
    echo "📦 Setting up Robot Framework in project virtual environment..."
    if [ ! -d "atests" ]; then
        mkdir -p atests
    fi

    cd atests
    
    # Create or activate venv
    if [ ! -d ".venv" ]; then
        echo "📦 Creating Python venv at atests/.venv"
        python3 -m venv .venv
    else
        echo "📦 Using existing venv at atests/.venv"
    fi
    
    source .venv/bin/activate

    echo "📦 Upgrading pip..."
    pip install --quiet --upgrade pip

    echo "📦 Installing Robot Framework and Browser Library..."
    pip install --quiet -r requirements.txt
    
    echo "📦 Initializing Browser Library (installing Playwright browsers)..."
    rfbrowser init

    deactivate
    cd ..
    echo "✅ Robot Framework setup complete"
}

# Check what needs installation
check_installation_needs

# Update system packages if anything needs to be installed
if [ "$NEEDS_NODE" = true ] || [ "$NEEDS_PYTHON" = true ] || [ "$NEEDS_GIT" = true ]; then
    update_packages
fi

# Install Node.js v22.20.0 using nvm (only if needed)
if [ "$NEEDS_NODE" = true ]; then
    echo "📦 Installing Node.js v22.20.0..."

    # Check for nvm, install if not present
    if ! command -v nvm &> /dev/null; then
        echo "📦 Installing nvm first..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        # Load nvm for current session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Make sure nvm is available after install
        if ! command -v nvm &> /dev/null; then
            echo "⚠️ nvm installation not immediately available. Adding to shell profile."
            # Add to profile if not already there
            grep -q NVM_DIR "$HOME/.bashrc" || echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
            source "$HOME/.bashrc"
        fi
    fi

    # Install and use Node.js v22.20.0
    if command -v nvm &> /dev/null; then
        nvm install 22.20.0
        nvm use 22.20.0
        nvm alias default 22.20.0
        echo "✅ Node.js v22.20.0 installed via nvm"
    else
        # Fallback to NodeSource if nvm is still not available
        echo "⚠️ nvm not available, falling back to NodeSource repository"
        case $DISTRO in
            ubuntu|debian)
                # Install prerequisites
                install_packages "curl ca-certificates gnupg"
                # Add NodeSource repository for v22.x
                curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
                sudo apt-get install -y nodejs
                ;;
            rhel|centos|fedora|almalinux|rocky)
                # Install prerequisites
                install_packages "curl ca-certificates"
                # Add NodeSource repository for v22.x
                curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y nodejs
                else
                    sudo yum install -y nodejs
                fi
                ;;
        esac
    fi

    echo "✅ Node.js: $(node --version)"
    echo "✅ npm: $(npm --version)"
else
    echo "✅ Node.js already installed: $(node --version)"
fi

# Install Python 3 and pip (only if needed)
if [ "$NEEDS_PYTHON" = true ]; then
    echo "📦 Installing Python 3 and pip..."
    case $DISTRO in
        ubuntu|debian)
            install_packages "python3 python3-pip python3-venv"
            ;;
        rhel|centos|fedora|almalinux|rocky)
            install_packages "python3 python3-pip"
            ;;
    esac
    echo "✅ Python: $(python3 --version)"
else
    echo "✅ Python already installed: $(python3 --version)"
fi

# Install Node.js dependencies (check if package.json changed)
echo "📦 Checking Node.js dependencies..."
if [ -f "package.json" ]; then
    # Check if node_modules is older than package.json or doesn't exist
    if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
        echo "  📦 Installing root dependencies..."
        npm install --silent
    else
        echo "  ✅ Root dependencies up to date"
    fi

    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        if [ ! -d "frontend/node_modules" ] || [ "frontend/package.json" -nt "frontend/node_modules" ]; then
            echo "  📦 Installing frontend dependencies..."
            cd frontend && npm install --silent && cd ..
        else
            echo "  ✅ Frontend dependencies up to date"
        fi
    fi

    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        if [ ! -d "backend/node_modules" ] || [ "backend/package.json" -nt "backend/node_modules" ]; then
            echo "  📦 Installing backend dependencies..."
            cd backend && npm install --silent && cd ..
        else
            echo "  ✅ Backend dependencies up to date"
        fi
    fi
else
    echo "⚠️  No package.json found, skipping npm install"
fi

# Install Git (only if needed)
if [ "$NEEDS_GIT" = true ]; then
    echo "📦 Installing Git..."
    install_packages "git"
    echo "✅ Git: $(git --version)"
else
    echo "✅ Git already installed: $(git --version)"
fi

# Install development utilities (only if missing)
if [ "$NEEDS_NODE" = true ] || [ "$NEEDS_PYTHON" = true ] || [ "$NEEDS_GIT" = true ]; then
    echo "📦 Installing development utilities..."
    case $DISTRO in
        ubuntu|debian)
            install_packages "curl wget unzip build-essential jq tree htop vim nano"
            ;;
        rhel|centos|fedora|almalinux|rocky)
            install_packages "curl wget unzip gcc gcc-c++ make jq tree htop vim nano"
            if command -v dnf &> /dev/null; then
                sudo dnf groupinstall -y "Development Tools" 2>/dev/null || true
            else
                sudo yum groupinstall -y "Development Tools" 2>/dev/null || true
            fi
            ;;
    esac
fi

# Setup Robot Framework (only if needed)
if [ "$NEEDS_ROBOT" = true ]; then
    setup_robot_framework
else
    echo "✅ Robot Framework already installed"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo "======================================="
echo ""
echo "📋 Installed tools:"
echo "  ✅ Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
echo "  ✅ npm: $(npm --version 2>/dev/null || echo 'Not installed')"
echo "  ✅ Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "  ✅ Git: $(git --version 2>/dev/null || echo 'Not installed')"
echo "  ✅ Robot Framework: $(atests/.venv/bin/python -m robot --version 2>/dev/null || echo 'Not installed')"
echo "  ✅ Browser Library: $(atests/.venv/bin/python -c 'import Browser; print(f\"Browser {Browser.__version__}\")' 2>/dev/null || echo 'Not installed')"
echo ""
echo "🚀 Next steps:"
echo "  1. Run environment check: ./check-environment.sh"
echo "  2. Run tests: ./run-tests.sh"
echo ""
echo "🔧 Development workflow:"
echo "  - Start backend: cd backend && npm run dev"
echo "  - Start frontend: cd frontend && npm run dev (in another terminal)"
echo "  - Or run tests: ./run-tests.sh (starts both automatically)"
echo ""
echo "💡 Tip: Run this script again to update any missing components"
echo ""
