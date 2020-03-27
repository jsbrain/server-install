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
echo ">>> ALL PACKAGES INSTALLED"
echo "\n********************************\n********************************\n"


# make zsh default shell
chsh -s $(which zsh)
# an run it
zsh

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


# install lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh > lzd_install.sh
sed -i 's/sudo//g' lzd_install.sh
bash lzd_install.sh
rm lzd_install.sh

# install rancher
yes | curl https://releases.rancher.com/install-docker/19.03.sh | sh

# install compose
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# apply permissions
chmod +x /usr/local/bin/docker-compose

echo "\n********************************\n********************************\n"
echo ">>> DOCKER(-COMPOSE) INSTALLED"
echo "\n********************************\n********************************\n"

echo "***** Script Done! *****"