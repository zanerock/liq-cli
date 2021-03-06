# After updating this file, run './install.sh' and open a new terminal for the
# changes to take effect.

# TODO: we could generate this from the help docs... make the spec central!
_liq() {
  local GLOBAL_ACTIONS="help"
  # Using 'GROUPS' was causing errors; set by some magic.
  local ACTION_GROUPS="meta orgs projects work"

  local TOKEN COMP_FUNC CUR OPTS PREV WORK_COUNT TOKEN_COUNT
  CUR="${COMP_WORDS[COMP_CWORD]}"
  PREV="${COMP_WORDS[COMP_CWORD-1]}"
  COMP_FUNC='comp'
  WORD_COUNT=${#COMP_WORDS[@]}
  TOKEN_COUNT=0

  no-opts() {
    COMPREPLY=( $(compgen -W "" -- ${CUR}) )
  }

  std-reply() {
    COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) )
  }

  comp-liq() {
    OPTS="${GLOBAL_ACTIONS} ${ACTION_GROUPS}"; std-reply
  }

  comp-liq-help() {
    OPTS="${ACTION_GROUPS}"; std-reply
  }

  comp-func-builder() {
    local TOKEN_PATH="${1}"
    local VAR_KEY="${2}"
    local NO_SQUASH_ACTIONS="${3:-}"
    local OPT
    local ACTIONS_VAR="${VAR_KEY}_ACTIONS"
    local GROUPS_VAR="${VAR_KEY}_GROUPS"
    echo "comp-liq-${TOKEN_PATH}() { OPTS=\"${!ACTIONS_VAR:-} ${!GROUPS_VAR:-}\"; std-reply; }"
    echo "comp-liq-help-${TOKEN_PATH}() { comp-liq-${TOKEN_PATH}; }"
    for OPT in ${!ACTIONS_VAR}; do
      if [[ -z "$NO_SQUASH_ACTIONS" ]] || ! type -t comp-liq-${TOKEN_PATH}-${OPT} | grep -q 'function'; then
        echo "function comp-liq-${TOKEN_PATH}-${OPT}() { no-opts; }"
        echo "function comp-liq-help-${TOKEN_PATH}-${OPT}() { no-opts; }"
      fi
    done
  }

  # environments group
  local ENVIRONMENTS_ACTIONS="add delete deselect list select set show update"
  eval "$(comp-func-builder 'environments' 'ENVIRONMENTS')"

  # meta group
  local META_ACTIONS="bash-config init next"
  local META_GROUPS="exts"
  eval "$(comp-func-builder 'meta' 'META')"

  META_EXTS_ACTIONS="install list uninstall"
  eval "$(comp-func-builder 'meta-exts' 'META_EXTS')"
  comp-liq-meta-exts-install() {
    if [[ "${PREV}" == 'install' ]]; then
      COMPREPLY=( $(compgen -W "--local --registry" -- ${CUR}) )
    elif [[ "${PREV}" == "--local" ]]; then
      if [[ "${CUR}" != */* ]]; then
        COMPREPLY=( $(compgen -o nospace -W "$(find ~/playground -type d -maxdepth 1 -mindepth 1 -not -name ".*" | awk -F/ '{ print $NF"/" }')" -- ${CUR}) )
      else
        COMPREPLY=( $(compgen -W "$(ls -d ~/playground/liquid-labs/*-ext-* | awk -F/ '{ print $(NF - 1)"/"$NF }')" -- ${CUR}) )
      fi
    fi
    # Currently no completion for registry packages.
  }

  comp-liq-meta-exts-uninstall() {
    # TODO: this is essentially the same logic aas 'liq meta exts list'; change completion to use 'rollup-bash' and share code
    if [[ -f ${HOME}/.liquid-development/exts/exts.sh ]]; then
      COMPREPLY=( $(compgen -W "$(cat "${HOME}/.liquid-development/exts/exts.sh" | awk -F/ 'NF { print $(NF-3)"/"$(NF-2) }')" -- ${CUR}) )
    else
      return 0
    fi
  }

  local ORGS_ACTIONS="affiliate create list show select"
  local ORGS_GROUPS=""
  eval "$(comp-func-builder 'orgs' 'ORGS')"
  comp-liq-orgs-select() {
    COMPREPLY=( $(compgen -W "$(find ~/.liquid-development/orgs -maxdepth 1 -mindepth 1 -type l -exec basename {} \;)" -- ${CUR}) )
  }

  local PROJECTS_ACTIONS="build close create publish qa sync test"
  local PROJECTS_GROUPS=""
  eval "$(comp-func-builder 'projects' 'PROJECTS')"
  comp-liq-projects-create() {
    if [[ "${PREV}" == "create" ]]; then
      COMPREPLY=( $(compgen -W "--new --source" -- ${CUR}) )
    elif [[ "${PREV}" == "--new" ]] || [[ "${PREV}" == "-n" ]]; then
      COMPREPLY=( $(compgen -W "raw" -- ${CUR}) )
    fi
  }

  local WORK_ACTIONS="diff-master edit ignore-rest involve list merge qa report resume save stage start status stop submit sync"
  local WORK_GROUPS="issues links"
  eval "$(comp-func-builder 'work' 'WORK')"
  comp-liq-work-stage() {
    # TODO: 'nospace' is very unfortunately innefective (on MacOS 10.x AFAIK)
    COMPREPLY=( $(compgen -o nospace -W "$(for d in ${CUR}*; do [[ -d "$d" ]] && echo "$d/" || echo "$d"; done)" -- ${CUR}) )
  }

  local WORK_ISSUES_ACTIONS="add list remove"
  eval "$(comp-func-builder 'work-issues' 'WORK_ISSUES')"

  local WORK_LINKS_ACTIONS="add list remove"
  eval "$(comp-func-builder 'work-links' 'WORK_LINKS')"
  comp-liq-work-links-remove() {
    OPTS="$(yalc check || true)"
    # TODO: code adapated from 'work-links-list'; once we build completion, let's share
    OPTS="$(echo "$OPTS" | awk -F: '{print $2}' | tr "'" '"' | jq -r '.[]')"
    std-reply
  }

  # TODO: Should we use LIQ_EXTS_DB here? This way, we're sidestepping the need to 'build' the completion script...
  source "${HOME}/.liquid-development/exts/comps.sh"

  # Now we've registered all the local and modular completion functions. We'll analyze the token stream to figure out
  # which completion function to call:
  for TOKEN in ${COMP_WORDS[@]}; do
    if [[ "$TOKEN" != -* ]] && (( $TOKEN_COUNT + 1 < $WORD_COUNT )); then
      if [[ "$(type -t "${COMP_FUNC}-${TOKEN}")" == 'function' ]]; then
        COMP_FUNC="${COMP_FUNC}-${TOKEN}"
        TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
      fi
    else
      TOKEN_COUNT=$(( $TOKEN_COUNT + 1 ))
    fi
  done

  # Execute the compeltion function determined above:
  $COMP_FUNC
  return 0
}

complete -F _liq liq
