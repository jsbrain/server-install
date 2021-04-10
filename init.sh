#!/bin/bash
#
# Perform basic Ubuntu server installation.

#######################################
# Flags including default values
# ....................
# Flag to determine if docker-compose should be installed
INSTALL_COMPOSE=0
# Flag to determine if lazygit and lazydocker should be installed
INSTALL_LAZY=0
# Flag to determine if docker should be installed
INSTALL_DOCKER=20
# Flag to determine if basic installation should be skipped
SKIP_BASIC=0
# Flag to determine if swap should be installed and which size
INSTALL_SWAP=2 # 2GB

#######################################
# Output color variables
# Usage: echo "${red}red text ${green}green text${reset}"
# ....................
black="$(tput setaf 0)"
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
blue="$(tput setaf 4)"
magenta="$(tput setaf 5)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
reset="$(tput sgr0)"             # Reset all styles
bell="$(tput bel)"               # Play a bell (beep) sound 🔔
bold="$(tput bold)"              # Select bold mode
under="$(tput smul)"             # Enable underline mode
invert="$(tput setab 7${black})" # Bg white, fg black

#######################################
# Print arguments help.
# Arguments:
#   None
#######################################
function helpFunction() {
  # Use $"..." to enable proper backslash escape handling (tab, newline, etc.)
  echo -e "\n${bold}Usage:${reset}"
  echo -e "\t$0 --flagA --flagB=0 --with-docker=19 ... | --help"
  echo -e "${bold}Synopsis:${reset}"
  echo -e "\t--with-compose\tInclude Docker-Compose, ${under}default: ${INSTALL_COMPOSE}${reset}"
  echo -e "\t--with-lazy\tInclude lazygit and lazydocker, ${under}default: ${INSTALL_LAZY}${reset}"
  echo -e "\t--with-docker\tInstall docker, can specify version e.g. --with-docker=19, ${under}default: ${INSTALL_DOCKER}${reset}"
  echo -e "\t\t\tvalues: [0 | 19 | 20]${reset}"
  echo -e "\t--with-swap\tAdd swapfile, ${under}default: ${INSTALL_SWAP}(GB)${reset}"
  echo -e "\t\t\tvalues: [0 | 1 | 2 | 4 | 6 | 8]${reset}"
  echo -e "\t--skip-basic\tUse to skip basic installation (git, zsh, utils), ${under}default: ${SKIP_BASIC}${reset}"
  echo -e "\t--only\t\tDisable all default flags, run only provided tasks. ${bold}MUST be the first argument!${reset}"
  echo -e "\t--help\t\tShow usage help"
  exit 1 # Exit script after printing help
}

#######################################
# Parses script argument flags in the format --<flag>[=<value>]. Note that the value
# assignment is optional and if not provided, flag will count as truthy (1) or be set to
# the default value $2 if provided.
# Arguments:
#   Flag argument to parse ($1), default value ($2)
# Returns:
#   Parsed value of the flag, if no flag is provided, flag is always set to default value ($2)
#   if provided, otherwise will be set to 'true' (1).
#######################################
function parseFlag() {
  local val=$(echo $1 | sed -e 's/^[^=]*=//g')
  if [[ "${val}" == "$1" ]]; then
    if [[ "$#" -eq 2 ]]; then
      val=$2
    else
      # ! Special case: Flag is defined without value and default value, we set it to true (1)
      val=1
    fi
  fi
  # Echo to stdout so return value can be assigned (e.g. func_result="$(parseFlag $1)")
  # ! NOTE: Cannot use echo at any other place before or return value will change!
  echo -e "${val}"
}

#######################################
# Validates arguments agains valid inputs.
# Arguments:
#   Value to test ($1), default value ($2), arbitrary number of valid inputs ($3 - $n).
# Returns:
#   0 if valid, throws and exits otherwise.
#######################################
function validateInput() {
  # ? NOTE: Local declaration and assignment should be on different lines (see https://google.github.io/styleguide/shellguide.html#use-local-variables)
  local val
  val="$(parseFlag $1 $2)"
  shift
  shift               # Double shift here so our testing values begin at $1
  local input_valid=0 # <- Here it's ok :)
  local valid_values="$1"

  # Test all validation parameters for equality
  while test $# -gt 0; do
    if [[ "${val}" == "$1" ]]; then
      input_valid=1
      break
    fi
    # Also create valid values message for error message
    if [[ "$2" > 0 ]]; then
      valid_values="${valid_values} | $2"
    fi
    shift
  done

  if [[ "${input_valid}" == 1 ]]; then
    return 0
  else
    echo -e "${bell}${red}ERROR: Invalid input $1, expected: ${valid_values}${reset}"
    exit 1
  fi
}

# Disable all flags so no tasks will run.
function disableAllTasks() {
  INSTALL_COMPOSE=0
  INSTALL_LAZY=0
  INSTALL_DOCKER=0
  SKIP_BASIC=1
  INSTALL_SWAP=0
}

# ════════════════════════════════════════════•°• :start: •°•════════════════════════════════════════════

# Idiomatic parameter and option handling
while test $# -gt 0; do
  case "$1" in
  --with-docker*)
    validateInput $1 $INSTALL_DOCKER 0 19 20 # value + default value + n valid values
    if (($? == 0)); then                     # For demo only, we actually don't need to check return value here.
      INSTALL_DOCKER="$(parseFlag $1)"
    fi
    ;;
  --with-compose*)
    validateInput $1 $INSTALL_COMPOSE 0 1
    INSTALL_COMPOSE="$(parseFlag $1)"
    ;;
  --with-lazy*)
    validateInput $1 $INSTALL_LAZY 0 1
    INSTALL_LAZY="$(parseFlag $1)"
    ;;
  --with-swap*)
    validateInput $1 $INSTALL_SWAP 0 1 2 4 6 8
    INSTALL_SWAP="$(parseFlag $1)"
    ;;
  --skip-basic*)
    validateInput $1 $SKIP_BASIC 0 1
    SKIP_BASIC="$(parseFlag $1)"
    ;;
  --only) disableAllTasks ;;
  --help) helpFunction ;;
  --*)
    echo -e "${red}Bad option $1${reset}"
    exit 1
    ;;
    # -id)
    #   # Use to parse args in format: -n filename
    #   shift
    #   if test $# -gt 0; then
    #     MY_VAR=$1
    #   else
    #     echo "no value specified"
    #     exit 1
    #   fi
    #   shift
    #   ;;
  esac
  shift
done

# echo "\n${red}******** STOP *********${reset}"
# exit 1

# ∘₊✧─────────────────────────────────────────────────────────────────────────────────────────────────✧₊∘

function installBasic() {
  # add repositories
  # NOTE: yes is actually a command and streams a "y"
  # to EVERY promt of the piped command. If you want to
  # use "no" or something else, give yes that as param
  # eg. "yes no". You can also just do "echo <term> | <command>"
  # for one time usage
  yes | add-apt-repository ppa:lazygit-team/release

  # set libssl to restart without asking (gui promt)
  # for all packages use wildcard eg '* libraries/restart-...'
  echo -e 'libssl1.1 libraries/restart-without-asking boolean true' | debconf-set-selections
  # install necessary packages in noninteractive mode
  yes | DEBIAN_FRONTEND=noninteractive apt-get update && apt install vim git curl iputils-ping util-linux open-iscsi lazygit zsh -y

  echo -e "\n********************************\n********************************\n"
  echo -e ">>> ALL DEFAULT PACKAGES INSTALLED"
  echo -e "\n********************************\n********************************\n"

  # make zsh default shell
  chsh -s $(which zsh)

  # install oh-my-zsh and skip promtps without setting zsh default (CHSH=no)
  yes | curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | CHSH=no sh

  # add theme
  sed -i 's/robbyrussell/pygmalion/g' .zshrc | sh
  sed -zi 's/\n\s*git\s/git extract zsh z docker kubectl/g' .zshrc | sh
  # write server scripts dir to path
  echo -e "path+=('/root/scripts/server')\n$(cat .zshrc)" >.zshrc | sh
  # add aliases
  echo -e "alias lg=lazygit\n$(cat .zshrc)" >.zshrc | sh
  echo -e "alias lzd=lazydocker\n$(cat .zshrc)" >.zshrc | sh

  echo -e "\n********************************\n********************************\n"
  echo -e ">>> ZSH INITIALIZED"
  echo -e "\n********************************\n********************************\n"
}

if [[ "${SKIP_BASIC}" -eq 0 ]]; then
  installBasic
fi

# ∘₊✧─────────────────────────────────────────────────────────────────────────────────────────────────✧₊∘

function installSwap() {
  # Disable swap if present
  swapoff -v /swapfile
  # Remove existing swapfile entries from fstab
  sed -i '/\/swapfile swap swap/c\' /etc/fstab | sh
  # Delete swapfile
  rm /swapfile
  # Now allocate new swap file size
  echo -e "fallocate -l ${INSTALL_SWAP}G /swapfile" | sh
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  # Now set new swap entry in fstab
  echo -e "/swapfile swap swap defaults 0 0" >>/etc/fstab | sh
  echo -e "\n********************************\n********************************\n"
  echo -e ">>> ${INSTALL_SWAP}GB SWAP ACTIVATED"
  echo -e "\n********************************\n********************************\n"
}

if [[ "${INSTALL_SWAP}" > 0 ]]; then
  installSwap
fi

# ∘₊✧─────────────────────────────────────────────────────────────────────────────────────────────────✧₊∘

function installLazy() {
  # install lazygit
  yes | lazygit
  # install lazydocker
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh >lzd_install.sh
  sed -i 's/sudo//g' lzd_install.sh
  bash lzd_install.sh
  rm lzd_install.sh
  echo -e "\n********************************\n********************************\n"
  echo -e ">>> LAZYGIT AND LAZYDOCKER INSTALLED"
  echo -e "\n********************************\n********************************\n"
}

if [[ "${INSTALL_LAZY}" -eq 1 ]]; then
  installLazy
fi

# ∘₊✧─────────────────────────────────────────────────────────────────────────────────────────────────✧₊∘

function installDocker() {
  # install docker with rancher install script
  local message
  if [[ "${INSTALL_DOCKER}" -eq 19 ]]; then
    yes | curl https://releases.rancher.com/install-docker/19.03.sh | sh
    message="v19.03"
  else
    yes | curl https://releases.rancher.com/install-docker/20.10.sh | sh
    message="v20.10"
  fi

  echo -e "\n********************************\n********************************\n"
  echo -e ">>> DOCKER ${message} INSTALLED"
  echo -e "\n********************************\n********************************\n"
}

if [[ "${INSTALL_DOCKER}" > 0 ]]; then
  installDocker
fi

# ∘₊✧─────────────────────────────────────────────────────────────────────────────────────────────────✧₊∘

function installCompose() {
  # install compose
  curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  # apply permissions
  chmod +x /usr/local/bin/docker-compose

  echo -e "\n********************************\n********************************\n"
  echo -e ">>> DOCKER-COMPOSE INSTALLED"
  echo -e "\n********************************\n********************************\n"
}

if [[ "${INSTALL_COMPOSE}" -eq 1 ]]; then
  installCompose
fi

# ═══════════════════════════════════════════•°• :success: •°•═══════════════════════════════════════════

echo -e "***** Script Done! *****\n"
exit 0 # Success
