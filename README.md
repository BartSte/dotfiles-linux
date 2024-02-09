﻿# Dotfiles BartSte

This readme is relevant for the following dotfiles repositories:

- BartSte/dotfiles
- BartSte/dotfiles-linux
- BartSte/doffiles-windows

Please read the following sections to get started with this repository. The
examples below are writing in bash and powershell.

## Dotfiles (cross-platform)

- No initialization needed. It only contains static dotfiles. Typically, you
  will not clone this repository by yourself, instead it will be cloned for you
  by the `dotfiles-linux` or the `dotfiles-windows` repositories, as they depend
  on it.

### Neovim (`dotfiles/nvim`)

Some directories of the neovim configuration could use some explanation:

- `dotfiles/nvim/lua`:
  - `helpers`: helper functions that are used in the other lua files.
  - `plugins`: plugins that are loaded by lazy.nvim
  - `config`: plugin configuration files.
- `dotfiles/nvim/vim`: plugin configuration files in vimscript.
- `dotfiles/nvim/plugin`: non-plugin configuration files that must be sourced
  before `after/plugin`.
- `dotfiles/nvim/after/plugin`: non-plugin configuration files.
- `dotfiles/nvim/after/ftplugin`: configuration files that are loaded after the
  filetype is detected.

## Dotfiles-linux (Arch linux)

### Installation

- To initialize the repository run the following line in a bash shell:

```bash
curl -O https://raw.githubusercontent.com/BartSte/dotfiles-linux/master/dotfiles-linux/initialize && bash ./initialize; rm ./initialize
```

- Complete the environment variables in `~/.dotfiles_config.sh`.
- Run the script: `~/dotfiles-linux/main`
- Afterwards, authenticate for:
  - Dropbox
  - Git crypt
  - Mutt
  - Khal & khalorg

### Authenticate dropbox

After installing dropbox, you need to authenticate it with your account. At the
moment of writing, the only way was to do this through a tray icon. Waybar did
not work from me so I did the following:

- Run xwayland
- Intall the program `trayer`
- Run trayer.
- Run dropbox.
- Dropbox will apear in the tray icon.
- Press `sign in` and follow the instructions.

After dropbox is working, re-run the following scripts as they rely on files
(containing personal data) that are synced by dropbox:

```bash
dotfiles-linux/qutebrowser/main
dotfiles-linux/wakatime/main
```

### Git crypt

The `dotfiles` repository contains some files that are encrypted using
`git-crypt`. To be able to read the encrypted files, the
`dotfiles-linux\crypt\main` script is used is executed when running het main
file.

#### get-rbw-base64-keys

The function `get-rbw-base64-keys` will convert the output of \`base crypt
export-key\` to a base64 string. This sting can be stored in the password
manager. In the \`main\` script this key is decoced and piped to \`base crypt
unlock\`. The `get-rbw-base64-keys` is only needed when you want to update the
keys in `rbw` and does not have to run when you are initializing your dotfiles.

### Mutt

I have two email accounts: personal and work. On all my devices, I only use one
of the two accounts. I have 1 muttrc file for both accounts. The differences in
configuration are handled by calling my password manager (rbw). The following
fields may be handled differently for each account:

- password: this is the password of the email account
- username: this is the username of the email account
- domain: this is the domain of the email account
- name: this is my real name
- calendar: this is the calendar that is used by khal
- contacts: this is the contacts that are used by khard
- MuttImapAuth: this is the imap auth method
- MuttClientId: this is the client id of the oauth2 script
- MuttSmtpAuth: this is the smtp auth method
- MuttPassword: this is the app password generated by Microsoft
- Signature (is added to the notes section of rbw)

Which account I am using, is determined by setting the environment variable
`MICROSOFTACCOUNT` to `MicrosoftPersonal` or `MicrosoftWork`. This variable is
set in the `.dotfiles_config.sh` file that is created when initializing the
`dotfiles-linux` repository.

The next sections explain the following:

- Authentication: how to authenticate the email accounts.
- Synchronization: how to sync the email accounts using IMAP and `mbsync`.
- Sending: how to send emails using SMTP and `mutt_oauth2`.
- Search: how to search through emails using `notmuch`.
- Mailsync: 1 command to sync and index all emails.

#### Authentication

Authentication can be done in three ways: using an app password (generated by
the email provider), using `davmail`, or using the `mutt_oauth2` script. The
app password is the easiest way but is not supported by all email providers
anymore. The oauth2 method is more complicated but is supported by most email
providers. Davmail is hard to setup, and it is difficult to debug when things
go wrong, so I use it as a last resort.

##### App password

For my personal email account, I use an app password. This password can be
generated by the email provider. Once it is obtained, it is added to the
password manager, at the field `MuttPassword`, which is supplied to the
`imap_pass` and `smtp_pass` fields in the `.muttrc` file. Furthermore, the
`MuttImapAuth` and `MuttSmtpAuth` fields are set to `login`.

##### Davmail

Davmail is a gateway that can be used to connect to exchange servers. It can be
used to connect to the exchange server using, among others, IMAP.

In the past, I used davmail to connect to the exchange server. Now I use
`mutt_oauth2`, but it is good to keep `davmail` as a backup option.
Furthermore, davmail was also needed for khalorg and khard, so I had to
set it up anyway. Initializing davmail can be done as follows:

- The davmail configuration is located in the `dotfiles-linux/davmail` file. By
  running the `main` script in this folder, the davmail configuration is copied
  to the `~/.config/davmail` folder. Copying is needed because the davmail
  stores tokens in the config file so we do not want to put this on git.

- Next, run the following commands to start davmail:

  ```bash
  davmail ~/.config/davmail/davmail.properties
  ```

- Open another shell and run the following command:

  ```bash
  mbsync -a
  ```

- Head back to shell 1 and follow the instructions. If you are prompted with a
  message that states that "interactive" mode is not supported, you can change
  the davmail.properties setting `davmail.mode=O365Interactive` to
  `davmail.mode=O365Manual`.

- Once this step is succeeded, `mbsync` will start doing its work. The refresh
  token is stored in the `~/.config/davmail/davmail.properties` file. If this
  file is removed, the authentication process has to be repeated.

##### Oauth2

For my work email account, I use oauth2 for synchronizing my mailbox (IMAP) and
sending emails (SMTP) because the app password is not supported anymore.

The following steps are needed to get oauth2 working:

- Checkout the `dotfiles-linux/bin/mutt_oauth2` script. This script is used
  to initialize and refresh the oauth2 token.
- I got the script working by registering an application at Azure as described
  in the README at `dotfiles-linux/mutt/README.md`. I used the client_id from
  the `overview` page. I added the client_id and my email address to the
  password manager at the `MuttClientId` field. Next, I called the password
  manager from the `mutt_oauth2` scrip.
- I created 1 bash script that does the initialization for you:
  `dotfiles-linux/mutt/init_mutt_oauth2`. This script can be called once to
  initialize the `mutt_oauth2` script.
- I also created 1 bash script that uses the correct token:
  `dotfiles-linux/mutt/mutt_oauth2_with_token`.
- The `mutt_oauth2_with_token` script is added to the `mbsync` config file to
  enable imap authentication. See the section
  [Synchronization](#synchronization).
- The `mutt_oauth2_with_token` was also added `smtp_oauth_refresh_command` in
  my `.muttrc` file, to enable smtp authentication. See the section
  [Sending](#sending).

#### Synchronization

For IMAP synchronization, there are basically two options: use the built-in
IMAP synchronization of neomutt or use an external tool. When using the
former, the emails are not downloaded to your local machine. Instead, the
emails are downloaded on the fly when you open a folder. This is not ideal
when you want to search through your emails fast. Therefore, I use an external
tool: `mbsync` (part of the `isync` package). This tool operates next to
neomutt and downloads the emails to your local machine in `Maildir` format. I
have two config files for `mbsync`: `personal` and `work`. Based on the value
of the environment variable `MICROSOFTACCOUNT`, the correct config file is
used. The config files are located in `~/dotfiles-linux/isync`.

For my personal email account, I use an app password for authentication. For
my work email account, I use `mutt_oauth2` for authentication. To enable
XOAUTH2 for `mbsync`, I added the following package from the AUR:
`cyrus-sasl-xoauth2-git`.

#### Sending

For sending emails, I use the built-in SMTP functionality of neomutt. The smtp
url is set in the `.muttrc` file and is dependent on the value of the
`username` field in the password manager. Authentication is done using the
`mutt_oauth2` script. The `mutt_oauth2` script is called by the
`smtp_oauth_refresh_command` field in the `.muttrc` file. This field is set to
the `mutt_oauth2_with_token` script.

#### Search

For searching through emails, I use `notmuch`. Neomutt has built-in support for
`notmuch`, so it can be configured in the `.muttrc` file together with the
`.notmuch-config` file. I added a keybinding to a global search to my `.muttrc`
file. This keybinding calls the `notmuch search` command and is bound to the
`alt+A` key. The notmuch database can be updated by calling the `notmuch new`
command.

#### Mailsync

`davmail`, `mbsync` and `notmuch` are combined into 1 command: `mailsync`.
This makes updating the emails easier. Note that no davmail is needed when
using an app password or `mutt_oauth2`, so it is only activated when a davmail
config is presented as an argument.

### khal & khalorg

I use my work office calendar for all devices such that I have 1 calendar for
all meetings. The calendar is synchronized with a local directory using
`vdirsyncer`. This directory is then used by `khal` to interact with the
calendar. Since I like to use `org-mode`, I build an interface between `khal`
and `org-mode` called `khalorg`.

`vdirsyncer` can communicate with the exchange server using davmail. To initialize
davmail, see the [Davmail](#davmail) section. Once davmail is initialized, run
the following command to synchronize the calendar:

```bash
~/dotfiles-linux/khal/main
~/dotfiles-linux/khalorg/main
vdirsyncer discover
mycalsync
```

here, `mycalsync` is a script that combines `davmail`, `vdirsyncer`, `khalorg`.
As a results, it synchronizes my office calendar with a local org file that
holds all my meetings as text.

### khard

`khard` is a contact manager that can be used to interact with the exchange
server when it is used in combination with `davmail` and `vdirsyncer`. Once you
have setup `davmail` and `vdirsyncer` as described in the sections above, `khard`
will also be synced when het `mycalsync` script is called. You can check if
`khard` is working by running the following command:

```bash
khard list
```

#### Setting up OpenVino + GPU

I had some issue making OpenVino detect my GPU (Intel UHD Graphics 620). The
following solved the issue:

```bash
sudo pacman -S level-zero-headers level-zero-loader intel-graphics-compiler
yay -S ocl-icd intel-opencl
```

### Dotfiles-windows (Windows 10 & 11)

- To initialize the repository copy the following line into powershell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force;
[bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544");
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/BartSte/dotfiles-windows/master/dotfiles-windows/initialize.ps1'))
```

- Complete the configuration file in `$HOME/dotfiles-windows/config.ps1`.
- Run the script: `$HOME/dotfiles-windows/main.ps1`
- All the subfolders of `$HOME/dotfiles-windows` are executed by calling the
  `main.ps1` file, e.g., `$HOME/dotfiles-windows/powershell/main.ps1`.

#### Git crypt

The `dotfiles` repository contains some files that are encrypted using
`git-crypt`. However, using git crypt on windows is not straightforward yet.
However, there are some files, that are now encrypted, we need to access
somehow. As a solution we symlink to the files from the `dotfiles` repository
from the WLS account, instead of the windows account. For example, we symlink
the `urls` from `qutebrowser` from WSL to the windows AppData folder. This way,
we can still use the `dotfiles` repository, but we do not have to use git crypt
on windows. To facilitate linking, an environment variable `LH` is created which
hold the windows path to the WSL home directory. This variable is set when you
enter a powershell session.

## Background

The following sections explain how the 3 repositories work together.

### Bare repository

The text below was inspired on the following article of [atlassian](https://www.atlassian.com/git/tutorials/dotfiles). This article will also explain the difference between a normal repository and a bare repository.

Clone the project (dotfiles, dotfiles-linux, or dotfiles-windows) into a bare
repository. I will call the bare repository: `dotfiles.git`:

```powershell
git clone --bare <git-repo-url> $HOME/dotfiles.git
```

Add the following alias to your .bashrc:

```bash
alias base='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
```

Or to your $PSHome/profile.ps1:

```powershell
${function:base} = { git.exe --git-dir=$HOME\dotfiles.git\ --work-tree=$HOME @args }
```

where `base` can be replaced by a name you prefer, while the folder
`dotfiles.git` is the directory holding the bare repository.

Checkout the actual content from the bare repository to your $HOME:

```bash
base checkout
```

The step above might fail with a message like:

```
error: The following untracked working tree files would be overwritten by checkout:
    README.md
    .gitignore
Please move or remove them before you can switch branches.
Aborting
```

This is because your `$HOME` folder might already have some stock configuration
files which would be overwritten by git. The solution is simple: back up the
files if you care about them, remove them if you don't care, and try again.

Set the flag showUntrackedFiles to no on this specific (local) repository:

```bash
base config --local status.showUntrackedFiles no
```

You're done, from now on you can now type `base` commands to add and update
your dotfiles:

```base
base status
base add README.md
base commit -m "Add README.md"
base push
```

### Multiple layers

Using a bare repository allows you to working on multiple repositories in the
same folder. For dotfiles this is typically the `$HOME` folder. As such, the
repositories `dotfiles` `dotfiles-linux`, and `dotfiles-windows` should all be
created in a bare repository in the `$HOME` folder. I call them
`<repo-name>.git`. Here, the repository `dotfiles.git` can be interpreted as
the base layer, containing dotfiles that are cross-platform. On top of that, a
linux layer can be added, i.e., the `dotfiles-linux.git` bare repository. As an
example, the following code adds a file `.foo` to the `dotfiles` repository
(using the alias `base`), and a file `.bar` to the `dotfiles-linux` repostory
(using the alias `lin`):

```bash
base add .foo
lin add .bar
base commit -m "Add .foo"
lin commit -m "Add .bar"
base push
lin push
```

You will always need the base layer `dotfiles`. On top of that you can add an
OS specific repostory: `dotfiles-linux` or `dotfiles-windows`.

## References

This repos are inspired on the following projects:

- [dotfiles for windows](https://github.com/jayharris/dotfiles-windows)
- [polybar-connection](https://github.com/BartSte/polybar-collection)
- [polybar-bluetooth](https://github.com/msaitz/polybar-bluetooth)
- [mutt-oauth2](https://github.com/muttmua/mutt/blob/master/contrib/mutt_oauth2.py)
- [tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles/)
