# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# hosts.sh - Names and links of the repositories on each host.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: is_reused, repo_owner, repo_url

# is_reused HOST: succeed if the existing repository on HOST will be reused.
is_reused() {
  [[ ${STATE[reuse_$1]:-0} == 1 ]]
}

repo_owner() {
  if [[ $1 == gitea ]]; then
    printf '%s' "${PROJECT[gitea_owner]}"
  else
    printf '%s' "${PROJECT[github_owner]}"
  fi
}

repo_url() {
  if [[ $1 == gitea ]]; then
    printf '%s/%s/%s' "${CONFIG[GITEA_URL]}" "${PROJECT[gitea_owner]}" "${PROJECT[name]}"
  else
    printf '%s/%s/%s' "${CONFIG[GITHUB_WEB_URL]}" "${PROJECT[github_owner]}" "${PROJECT[name]}"
  fi
}
