# make zsh default shell
chsh -s $(which zsh)

# install oh-my-zsh and skip promtps with --unattended
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh) --skip-chsh"

echo "\n********************************\n********************************\n"
echo ">>> ZSH INITIALIZED"
echo "\n********************************\n********************************\n"

# add theme
sed -i 's/robbyrussell/pygmalion/g' .zshrc
sed -zi 's/\n\s*git\s/git extract zsh z docker kubectl/g' .zshrc
# write server scripts dir to path
echo "path+=('/root/scripts/server')\n$(cat .zshrc)" > .zshrc
# add aliases
echo "alias lg=lazygit\n$(cat .zshrc)" > .zshrc
echo "alias lzd=lazydocker\n$(cat .zshrc)" > .zshrc

