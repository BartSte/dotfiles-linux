# Open files and URLs

`bin/open` opens one file or URL with a configured program.
It accepts an argument or reads the input from standard input.
An argument takes precedence over standard input.

```sh
open notes.txt
open 'notes.txt:12:8'
printf '%s\n' 'notes.txt:12:8' | open
open 'https://example.com/?a=1&b=2'
open -- -notes.txt
```

Line and column numbers start at 1.
An existing filename takes precedence over a location suffix.
For example, an existing file named `report:2026` opens at line 1.

## Programs

| Input | Program |
| --- | --- |
| URL or HTML file | `WSLBROWSER` under WSL, otherwise `LINBROWSER` |
| Image | `imv` |
| PDF | `zathura` |
| SC spreadsheet | `sc-im` |
| Text, JSON, XML, YAML, TOML, or empty file | `nvim`, or `key2pane` in tmux |

Each browser variable names one executable without additional arguments.
Use a wrapper script for browser arguments.
If `WSLBROWSER` is unset under WSL, `open` uses `LINBROWSER`.

Symbolic links use the type of their target file.
Missing files, directories, and unsupported binary files produce an error.
Programs run in the foreground, and `open` returns their exit status.
Inside tmux, editor requests return after tmux accepts the command.
A browser can hand its request to an existing process and exit immediately.
Its exit status reports the result of that handoff.

## WSL paths

Use `--linpath` for Windows paths from terminal output:

```sh
open --linpath 'C:\Users\Bart\notes.txt:12:8'
```

Drive letters and UNC paths survive location parsing.
One pair of surrounding quotes is removed from copied WSL paths.
Quotes inside filenames remain unchanged.

Linux programs receive Linux paths.
Local HTML files sent to `WSLBROWSER` automatically use Windows paths.
Use `--winpath` to request Windows paths for local HTML files sent to `LINBROWSER` under WSL.
The two conversion options cannot be combined.
Outside WSL, each conversion option has no effect.

## Tmux

For text files, `open` searches for a Neovim or Vim pane in the current session.
The source pane takes precedence if it already runs an editor.
Otherwise, the first editor pane receives the file through `key2pane`.
Tmux selects that window and pane.
If no editor exists, `open` starts Neovim in a new pane of the source window.
The source process stays intact.
Relative paths become absolute paths before this step.

Prefix + u opens a file and URL picker for the source pane's last 5000 history lines.
It includes existing files, line and column suffixes, and Python traceback paths.
Relative paths use the source pane's working directory.
Paths with spaces must appear inside quotes.
URLs remain available, and duplicate results appear once, with recent results first.
The preview shows the surrounding pane history and highlights the selected result's latest occurrence.
The picker requires Python 3 and `fzf-tmux`.

The selection goes through `open`, so images, PDFs, and HTML use their respective programs.
Escape cancels the picker without opening anything.
If the pane contains no files or URLs, tmux shows a message.

The [key2pane configuration](../key2pane/config.json) accepts five arguments from `open`:

1. The literal filename, for Codex paste actions.
2. The line number.
3. The column number.
4. The filename with shell escaping, for Bash and Zsh actions.
5. The filename as a quoted Vim expression, for Vim and Neovim actions.

Shell and editor actions use separate escaping to preserve filenames with command characters.

## Logging

```sh
open --verbose notes.txt
open --log ~/.local/state/open.log notes.txt
open --quiet notes.txt
```

`--verbose` shows debug messages on standard error.
`--log FILE` appends debug messages and errors to a file and creates its parent directories.
`--quiet` suppresses terminal output from `open` and its programs.
An explicit log file still receives messages in quiet mode.
`OPEN_LOG_FILE` and `OPEN_LOG_LEVEL` provide defaults for these options.

## Checks

```sh
bash -n bin/open tests/scripts/test_open.sh
bash tests/scripts/test_open.sh
bash tests/tmux/test_open_integration.sh
python3 -B -m unittest discover -s tests/scripts -p test_tmux_open_picker.py
shellcheck bin/open tests/scripts/test_open.sh
```

The regression suite uses mock programs for desktop applications and WSL conversion.
If Neovim and key2pane are available, the suite also checks their actual argument handling.
