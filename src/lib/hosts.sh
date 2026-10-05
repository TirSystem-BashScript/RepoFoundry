# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# hosts.sh - Names and links of the repositories on each host.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: is_reused, repo_owner, repo_url, gitea_host, origin_protocol, origin_url, github_remote_url, framework_url

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

# gitea_host: the host name of the Gitea server, from GITEA_URL.
gitea_host() {
  local host="${CONFIG[GITEA_URL]#https://}"
  host="${host%%/*}"
  printf '%s' "${host%%:*}"
}

# origin_protocol: SSH when the SSH test passed, otherwise HTTPS.
origin_protocol() {
  if ((${STATE[is_ssh_ok]:-0})); then
    printf 'SSH'
  else
    printf 'HTTPS'
  fi
}

# origin_url: the address of the Gitea repository for the origin remote. It
# never holds a credential: "git@" is the SSH user name, not a secret.
origin_url() {
  if [[ $(origin_protocol) == SSH ]]; then
    printf 'ssh://git@%s:%s/%s/%s.git' "$(gitea_host)" "${CONFIG[GITEA_SSH_PORT]}" \
      "${PROJECT[gitea_owner]}" "${PROJECT[name]}"
  else
    printf '%s/%s/%s.git' "${CONFIG[GITEA_URL]}" "${PROJECT[gitea_owner]}" "${PROJECT[name]}"
  fi
}

github_remote_url() {
  printf '%s/%s/%s.git' "${CONFIG[GITHUB_WEB_URL]}" "${PROJECT[github_owner]}" "${PROJECT[name]}"
}

# framework_url: where the framework submodule comes from (always SSH).
framework_url() {
  printf 'ssh://git@%s:%s/%s.git' "$(gitea_host)" "${CONFIG[GITEA_SSH_PORT]}" \
    "${CONFIG[FRAMEWORK_REPO]}"
}
