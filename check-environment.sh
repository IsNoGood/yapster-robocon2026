#!/usr/bin/env bash

# Yapster Training Environment Checker for Linux and macOS
# Verifies that all required tools are installed with correct versions
# and that Robot Framework with Browser library works properly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0

# Parse command line arguments
CHECK_CORE=true
CHECK_ROBOT=true

if [ $# -gt 0 ]; then
    CHECK_CORE=false
    CHECK_ROBOT=false
    
    for arg in "$@"; do
        case $arg in
            core|tools)
                CHECK_CORE=true
                ;;
            robot|rf)
                CHECK_ROBOT=true
                ;;
            all)
                CHECK_CORE=true
                CHECK_ROBOT=true
                ;;
            *)
                echo "Usage: $0 [core|tools] [robot|rf] [all]"
                echo "  core/tools: Check core development tools"
                echo "  robot/rf:   Check Robot Framework environment"
                echo "  all:        Check everything (default if no args)"
                echo "  (no args):  Check everything"
                exit 1
                ;;
        esac
    done
fi

echo -e "${BLUE}🚀 Yapster Training Environment Checker${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        printf "%b\n" "${GREEN}✅ $2${NC}"
        ((CHECKS_PASSED++))
    else
        printf "%b\n" "${RED}❌ $2${NC}"
        ((CHECKS_FAILED++))
    fi
}

# Function to compare versions
version_compare() {
    local required=$1
    local actual=$2

    IFS='.' read -r -a required_parts <<< "$required"
    IFS='.' read -r -a actual_parts <<< "$actual"

    local length=${#required_parts[@]}
    if [ ${#actual_parts[@]} -gt $length ]; then
        length=${#actual_parts[@]}
    fi

    for ((i=0; i<length; i++)); do
        local req_part=${required_parts[i]:-0}
        local act_part=${actual_parts[i]:-0}

        # Ensure numbers are compared properly even with leading zeros
        req_part=$((10#${req_part}))
        act_part=$((10#${act_part}))

        if (( act_part > req_part )); then
            return 0
        elif (( act_part < req_part )); then
            return 1
        fi
    done

    return 0
}

extract_version() {
    echo "$1" | awk 'match($0, /[0-9]+(\.[0-9]+)+/) { print substr($0, RSTART, RLENGTH); exit }'
}

# Function to check tool version
check_tool_version() {
    local tool=$1
    local required_version=$2
    local version_command=$3

    echo -n "Checking $tool... "

    if ! command -v $tool &> /dev/null; then
        print_status 1 "$tool is not installed"
        return 1
    fi

    local actual_version
    actual_version=$(eval $version_command 2>/dev/null | head -n1)
    actual_version=$(extract_version "$actual_version")

    if [ -z "$actual_version" ]; then
        print_status 1 "$tool version could not be determined"
        return 1
    fi
    
    if version_compare "$required_version" "$actual_version"; then
        print_status 0 "$tool $actual_version (>= $required_version required)"
    else
        print_status 1 "$tool $actual_version (>= $required_version required)"
        return 1
    fi
}

# Load required versions from file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/required-versions.txt"

if [ ! -f "$VERSIONS_FILE" ]; then
    printf "%b\n" "${RED}❌ Required versions file not found: $VERSIONS_FILE${NC}"
    exit 1
fi

printf "%b\n" "${YELLOW}Loading required versions from: $VERSIONS_FILE${NC}"
printf "\n"

# Parse versions file
while IFS='=' read -r tool version; do
    # Skip comments and empty lines
    [[ $tool =~ ^#.*$ ]] && continue
    [[ -z $tool ]] && continue

    tool=$(echo "$tool" | tr -d '[:space:]')
    version=$(echo "$version" | tr -d '[:space:]')

    # Only allow expected tool names to avoid surprises
    case "$tool" in
        node|npm|python|git|robot|browser)
            eval "REQUIRED_${tool}=\"$version\""
            ;;
        *)
            ;;
    esac
done < "$VERSIONS_FILE"

if [ "$CHECK_CORE" = true ]; then
    echo -e "${BLUE}📋 Checking Core Tools${NC}"
    echo "====================="

check_tool_version "node" "$REQUIRED_node" "node --version"

# Check npm
check_tool_version "npm" "$REQUIRED_npm" "npm --version"

# Check Python
check_tool_version "python3" "$REQUIRED_python" "python3 --version"

# Check Git
check_tool_version "git" "$REQUIRED_git" "git --version"

    echo ""
fi

if [ "$CHECK_ROBOT" = true ]; then
    echo -e "${BLUE}🤖 Checking Robot Framework Environment${NC}"
    echo "========================================"

# Check if Robot Framework venv exists
VENV_PATH="$SCRIPT_DIR/atests/.venv"
echo -n "Checking Robot Framework virtual environment... "
if [ -d "$VENV_PATH" ]; then
    print_status 0 "Virtual environment found at atests/.venv"
else
    print_status 1 "Virtual environment not found at atests/.venv"
fi

# Check Robot Framework installation in venv
echo -n "Checking Robot Framework installation... "
if [ -f "$VENV_PATH/bin/robot" ]; then
    rf_version=$("$VENV_PATH/bin/python" -c "import robot; print(robot.__version__)" 2>/dev/null)
    if [ -n "$rf_version" ]; then
        if version_compare "$REQUIRED_robot" "$rf_version"; then
            print_status 0 "Robot Framework $rf_version (>= $REQUIRED_robot required)"
        else
            print_status 1 "Robot Framework $rf_version (>= $REQUIRED_robot required)"
        fi
    else
        print_status 1 "Robot Framework version could not be determined"
    fi
else
    print_status 1 "Robot Framework not found in virtual environment"
fi

# Check Browser library installation
echo -n "Checking Browser library... "
if "$VENV_PATH/bin/python" -c "import Browser" 2>/dev/null; then
    browser_version=$("$VENV_PATH/bin/python" -c "import Browser; print(Browser.__version__)" 2>/dev/null)
    if [ -n "$browser_version" ]; then
        if version_compare "$REQUIRED_browser" "$browser_version"; then
            print_status 0 "Browser library $browser_version (>= $REQUIRED_browser required)"
        else
            print_status 1 "Browser library $browser_version (>= $REQUIRED_browser required)"
        fi
    else
        print_status 1 "Browser library version could not be determined"
    fi
else
    print_status 1 "Browser library not found"
fi

# Test Browser library functionality
echo -n "Testing Browser library functionality... "
if "$VENV_PATH/bin/python" -c "
from Browser import Browser
import sys
try:
    browser = Browser()
    print('Browser library test passed')
    sys.exit(0)
except Exception as e:
    print(f'Browser library test failed: {e}')
    sys.exit(1)
" 2>/dev/null; then
    print_status 0 "Browser library functionality test passed"
else
    print_status 1 "Browser library functionality test failed"
fi

    echo ""
fi
echo -e "${BLUE}📊 Summary${NC}"
echo "=========="
printf "%b\n" "${GREEN}Passed: $CHECKS_PASSED${NC}"
printf "%b\n" "${RED}Failed: $CHECKS_FAILED${NC}"
printf "\n"

if [ $CHECKS_FAILED -eq 0 ]; then
    printf "%b\n" "${GREEN}🎉 Environment check completed successfully!${NC}"
    printf "%b\n" "${GREEN}Your system is ready for Yapster training.${NC}"
    exit 0
else
    printf "%b\n" "${RED}⚠️  Environment check found issues.${NC}"
    printf "%b\n" "${YELLOW}Please fix the failed checks before starting training.${NC}"
    printf "%b\n" "${YELLOW}Run the setup script for your platform if needed:${NC}"
    printf "%b\n" "${YELLOW}  ./setup-linux.sh${NC}"
    printf "%b\n" "${YELLOW}  ./setup-macos.sh${NC}"
    exit 1
fi
