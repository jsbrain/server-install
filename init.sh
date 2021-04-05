# Flag to determine if docker-compose should be installed
INSTALL_COMPOSE=0
# Flag to determine if lazygit and lazydocker
INSTALL_LAZY=0

# Print arguments help
helpFunction()
{
   echo ""
   echo "Usage: $0 --flagA --flagB ... | --help"
   echo "\t--with-compose Include Docker-Compose"
   echo "\t--with-lazy Include lazygit and lazydocker"
   echo "\t--help Show usage help"
   exit 1 # Exit script after printing help
}

# idiomatic parameter and option handling
while test $# -gt 0
do
  case "$1" in
    --with-compose) INSTALL_COMPOSE=1
        ;;
    --with-lazy) INSTALL_LAZY=1
        ;;
    --help) helpFunction
        ;;
    --*) echo "bad option $1"
        ;;
  esac
  shift
done

# add repositories
# NOTE: yes is actually a command and streams a "y"
# to EVERY promt of the piped command. If you want to
# use "no" or something else, give yes that as param
# eg. "yes no". You can also just do "echo <term> | <command>"
# for one time usage
yes | add-apt-repository ppa:lazygit-team/release

# set libssl to restart without asking (gui promt)
# for all packages use wildcard eg '* libraries/restart-...'
echo 'libssl1.1 libraries/restart-without-asking boolean true' | debconf-set-selections
# install necessary packages in noninteractive mode
yes | DEBIAN_FRONTEND=noninteractive apt-get update && apt install vim git curl iputils-ping open-iscsi lazygit zsh -y 

echo "\n********************************\n********************************\n"
echo ">>> ALL DEFAULT PACKAGES INSTALLED"
echo "\n********************************\n********************************\n"


# make zsh default shell
chsh -s $(which zsh)

# install oh-my-zsh and skip promtps without setting zsh default (CHSH=no)
yes | curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | CHSH=no sh

# add theme
sed -i 's/robbyrussell/pygmalion/g' .zshrc | sh
sed -zi 's/\n\s*git\s/git extract zsh z docker kubectl/g' .zshrc | sh
# write server scripts dir to path
echo "path+=('/root/scripts/server')\n$(cat .zshrc)" > .zshrc | sh
# add aliases
echo "alias lg=lazygit\n$(cat .zshrc)" > .zshrc | sh
echo "alias lzd=lazydocker\n$(cat .zshrc)" > .zshrc | sh


echo "\n********************************\n********************************\n"
echo ">>> ZSH INITIALIZED"
echo "\n********************************\n********************************\n"


installLazy() {
  # install lazygit
  yes | lazygit
  # install lazydocker
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh > lzd_install.sh
  sed -i 's/sudo//g' lzd_install.sh
  bash lzd_install.sh
  rm lzd_install.sh
  echo "\n********************************\n********************************\n"
  echo ">>> LAZYGIT AND LAZYDOCKER INSTALLED"
  echo "\n********************************\n********************************\n"
}

if [ $INSTALL_COMPOSE -eq 1 ]
then installLazy
fi


# install docker with rancher install script
yes | curl https://releases.rancher.com/install-docker/20.10.sh | sh

echo "\n********************************\n********************************\n"
echo ">>> DOCKER INSTALLED"
echo "\n********************************\n********************************\n"


installCompose() {
  # install compose
  curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  # apply permissions
  chmod +x /usr/local/bin/docker-compose

  echo "\n********************************\n********************************\n"
  echo ">>> DOCKER-COMPOSE INSTALLED"
  echo "\n********************************\n********************************\n"
}


if [ $INSTALL_COMPOSE -eq 1 ]
then installCompose
fi


echo "***** Script Done! *****"
exit 1
