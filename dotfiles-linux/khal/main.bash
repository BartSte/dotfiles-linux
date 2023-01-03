. ~/dotfiles-linux/khal/helpers.bash

directory=~/clones/khal
clone $directory 2> /dev/null
cd $directory
sudo ./setup.py build
sudo ./setup.py install

