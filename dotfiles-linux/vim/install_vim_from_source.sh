sudo apt-get remove --purge vim vim-runtime vim-gnome vim-tiny vim-gui-common
sudo apt-get install checkinstall liblua5.1-dev luajit libluajit-5.1 python2-dev python3-dev ruby-dev libperl-dev libncurses5-dev libatk1.0-dev libx11-dev libxpm-dev libxt-dev

sudo rm -rf /usr/local/share/vim /usr/bin/vim

cd ~
git clone https://github.com/vim/vim
cd vim
git pull && git fetch
cd src
make distclean
cd ..

 ./configure \
 --enable-multibyte \
 --enable-perlinterp=dynamic \
 --enable-rubyinterp=dynamic \
 --with-ruby-command=/usr/bin/ruby \
 --enable-pythoninterp=dynamic \
 --with-python-config-dir=/usr/lib/python2.7/plat-x86_64-linux-gnu \
 --enable-python3interp \
 --with-python3-config-dir=/usr/lib/python3.10/config-3.10-x86_64-linux-gnu \
 --enable-luainterp \
 --with-luajit \
 --enable-cscope \
 --enable-gui=auto \
 --with-features=huge \
 --with-x \
 --enable-fontset \
 --enable-largefile \
 --disable-netbeans \
 --with-compiledby="barts" \
 --enable-fail-if-missing

make && sudo make install
