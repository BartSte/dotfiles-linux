# --- centralized projectrc loader (startup-only) ---
setopt extendedglob

# Root directory for all supplementary configs

: ${PROJECTRC_HOME:="${${(%):-%x}:A:h}/projectrc"}
: ${PROJECTRC_MAP:="$PROJECTRC_HOME/mappings.conf"}

#------------------------------------------------------------------------------
# __projectrc_from_map
# Reads $PROJECTRC_MAP (lines: "<glob> <file>") and returns snippet paths
# whose <glob> matches the current $PWD. Globs use zsh pattern syntax.
# Output: newline-separated absolute paths under $PROJECTRC_HOME/projectrc.d/
# Side effects: none
#------------------------------------------------------------------------------
__projectrc_from_map() {
  local projectrc_dir="$PROJECTRC_HOME/projectrc.d"
  [[ -r $PROJECTRC_MAP ]] || return 0

  local line pat file exp_pat matches=()
  while IFS=$' \t' read -r line; do
    [[ -z $line || ${line[1]} == "#" ]] && continue
    pat=${=${(z)line}[1]}
    file=${=${(z)line}[2]}
    [[ -z $pat || -z $file ]] && continue

    exp_pat=${~pat}            # expand ~ in patterns
    if [[ $PWD == ${~exp_pat} ]]; then
      matches+="$projectrc_dir/$file"
    fi
  done < "$PROJECTRC_MAP"

  print -r -- ${(u)matches}
}

#------------------------------------------------------------------------------
# __projectrc_from_git
# If $PWD is inside a Git repo, returns a snippet keyed by repo name:
#   $PROJECTRC_HOME/projectrc.git/<reponame>.zsh
# Output: single absolute path if readable, otherwise empty
# Side effects: none
#------------------------------------------------------------------------------
__projectrc_from_git() {
  local gitroot repo file
  gitroot=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0
  repo=${gitroot:t}
  file="$PROJECTRC_HOME/projectrc.git/${repo}.zsh"
  [[ -r $file ]] && print -r -- "$file"
}

#------------------------------------------------------------------------------
# __projectrc_is_safe
# Basic safety: ensures the candidate file is a regular, readable file
# and lives under $PROJECTRC_HOME. Returns 0 if safe.
# Side effects: none
#------------------------------------------------------------------------------
__projectrc_is_safe() {
  local f=$1
  [[ -n $f && -f $f && -r $f && $f == ${PROJECTRC_HOME}/* ]]
}

#------------------------------------------------------------------------------
# __projectrc_load_startup
# Resolves all matching snippets for the initial $PWD and sources each once.
# De-duplicates the list. No caching or chpwd hooks.
# Side effects: sources user snippets
#------------------------------------------------------------------------------
__projectrc_load_startup() {
  local files=()
  files+=($(__projectrc_from_map))
  files+=($(__projectrc_from_git))
  files=(${(u)files})  # unique

  local f
  for f in $files; do
    if __projectrc_is_safe "$f"; then
      source "$f"
    fi
  done
}

# Run once when .zshrc is sourced (initial shell PWD only)
__projectrc_load_startup

