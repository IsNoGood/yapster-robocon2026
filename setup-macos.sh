#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up Yapster development environment for macOS"
echo "======================================================="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew already installed: $(brew --version | head -n1)"
fi

# Update Homebrew
echo "📦 Updating Homebrew..."
brew update

# Install Node.js v22.20.0 using nvm
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
        if [ -f "$HOME/.zshrc" ]; then
            grep -q NVM_DIR "$HOME/.zshrc" || echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.zshrc"
            source "$HOME/.zshrc"
        else
            grep -q NVM_DIR "$HOME/.bash_profile" || echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bash_profile"
            source "$HOME/.bash_profile"
        fi
    fi
fi

# Install and use Node.js v22.20.0
if command -v nvm &> /dev/null; then
    nvm install 22.20.0
    nvm use 22.20.0
    nvm alias default 22.20.0
    echo "✅ Node.js v22.20.0 installed via nvm"
else
    # Fallback to Homebrew if nvm is still not available
    echo "⚠️ nvm not available, falling back to Homebrew"
    brew install node@22
    echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
fi

echo "✅ Node.js: $(node --version)"
echo "✅ npm: $(npm --version)"

# Install Python 3
echo "📦 Installing Python 3..."

# Check macOS version
macos_version=$(sw_vers -productVersion | cut -d. -f1)
if [ "$macos_version" -ge 15 ] 2>/dev/null; then
    echo "ℹ️  Detected macOS $macos_version - Python 3 should be pre-installed by Apple"
    if ! command -v python3 &> /dev/null; then
        echo "❌ ERROR: python3 command not found on macOS $macos_version"
        echo "   This is unexpected as macOS 15+ should include Python 3 by default."
        echo "   Please check your Python 3 installation or contact support."
        echo "   You can try: xcode-select --install"
        exit 1
    else
        echo "✅ Python already installed: $(python3 --version)"
    fi
else
    echo "ℹ️  Detected macOS $macos_version - checking Python 3 installation"
    if ! command -v python3 &> /dev/null; then
        echo "📦 Installing Python 3 via Homebrew..."
        brew install python
    else
        echo "✅ Python already installed: $(python3 --version)"
    fi
fi

echo "✅ Python: $(python3 --version)"
echo "✅ pip: $(python3 -m pip --version)"

# Install Robot Framework in project virtual environment
echo "📦 Setting up Robot Framework in project virtual environment..."
if [ ! -d "atests" ]; then
    mkdir -p atests
fi

cd atests
echo "📦 Creating clean Python venv at atests/.venv"
# Remove any existing broken venv
rm -rf .venv 2>/dev/null || true

# Create venv without pip (to avoid copying broken system pip)
python3 -m venv .venv --without-pip
source .venv/bin/activate

echo "📦 Installing fresh pip with get-pip.py"
curl -sS https://bootstrap.pypa.io/get-pip.py | python
echo "✅ Fresh pip installed: $(python -m pip --version)"

echo "📦 Installing Robot Framework libraries in venv"
pip install --quiet -r requirements.txt

echo "📦 Initializing BrowserLibrary (downloads Playwright browsers)"
rfbrowser init

cd ..
echo "✅ Robot Framework: $(atests/.venv/bin/python -m robot --version)"

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
if [ -f "package.json" ]; then
    echo "  📦 Installing root dependencies..."
    npm install --silent
    
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        echo "  📦 Installing frontend dependencies..."
        cd frontend && npm install --silent && cd ..
    fi
    
    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        echo "  📦 Installing backend dependencies..."
        cd backend && npm install --silent && cd ..
    fi
    
    echo "✅ Node.js dependencies installed"
else
    echo "⚠️  No package.json found, skipping npm install"
fi

# Install Git (usually pre-installed on macOS, but ensure it's available)
echo "📦 Installing Git..."
if ! command -v git &> /dev/null; then
    brew install git
else
    echo "✅ Git already installed: $(git --version)"
fi

# Docker not needed for local development (using npm run dev)

# Install development utilities
echo "📦 Installing development utilities..."
brew install curl wget

echo ""
echo "🎉 Installation completed successfully!"
echo "======================================="
echo ""
echo "📋 Installed tools:"
echo "  ✅ Node.js: $(node --version)"
echo "  ✅ npm: $(npm --version)"
echo "  ✅ Python: $(python3 --version)"
echo "  ✅ Robot Framework: $(atests/.venv/bin/python -m robot --version 2>/dev/null || echo 'Installed in venv')"
echo "  ✅ Git: $(git --version)"
echo "  ✅ Homebrew: $(brew --version | head -n1)"
echo ""
echo "🚀 Next steps:"
echo "  1. Clone the repository: git clone <your-repo-url>"
echo "  2. Navigate to project: cd training-ai-aided-sw-development"
echo "  3. Install dependencies: npm install"
echo "  4. Run tests: ./run-tests.sh"
echo ""
echo "🔧 Development workflow:"
echo "  - Start backend: cd backend && npm run dev"
echo "  - Start frontend: cd frontend && npm run dev (in another terminal)"
echo "  - Or run tests: ./run-tests.sh (starts both automatically)"
echo ""
echo "💡 If this is your first time using these tools:"
echo "  - You may need to restart your terminal for PATH changes to take effect"
