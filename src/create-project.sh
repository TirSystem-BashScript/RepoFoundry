#!/usr/bin/env bash
# create-project.sh - set up a new project on Gitea (and optionally GitHub).
#
# Purpose
#   RepoFoundry creates a Gitea repository, optionally an empty GitHub
#   repository with a Gitea -> GitHub push mirror, and a local project with
#   the SQA-QC-Framework. It validates the configuration and credentials,
#   asks for the project details (those set in config.env are not asked), checks both hosts with read-only requests
#   (tokens, owners, names, license, SSH) and, with --apply, creates the
#   repositories and the mirror, then the local project: its directory, git
#   repository, remotes (no credential in any address), the framework as a
#   submodule, the framework's skills and git hooks (and the plan gate if
#   chosen) and its templates. The license of the Gitea repository is
#   PROJECT_LICENSE in config.env (none means no license); without it AGPL-3.0
#   applies only when GitHub is chosen and the project is public. After a yes
#   (default no) it also writes the new project's own .env with the credentials
#   the project needs. No commit is made in the new project.
#
# Dry run by default
#   Without --apply the script only reads from GitHub and Gitea (GET
#   requests) and prints what it would create. With --apply it prints the plan
#   and asks for a final yes before it creates anything. Nothing is ever
#   deleted: if a step fails, the script reports what exists and how to
#   continue, and a repeated run offers to reuse the empty repositories.
#
# Usage
#   create-project.sh [--apply] [--config FILE] [--env FILE]
#   create-project.sh --help | --version
#
# Options
#   --apply         create the repositories and the mirror (after a final yes)
#   --config FILE   service addresses (default: config.env in the project root)
#   --env FILE      credentials (default: .env in the project root); optional:
#                   a credential it does not provide is asked, not echoed
#   -h, --help      show this help
#   --version       show the version
#
# Files (parsed, never sourced)
#   config.env  GITHUB_API_URL, GITHUB_WEB_URL, GITEA_URL, GITEA_API_URL and
#               the optional GITEA_SSH_PORT (default 10022), MIRROR_INTERVAL
#               (default 10m0s) and FRAMEWORK_REPO (default
#               TirSystem/SQA-QC-Framework, the submodule's OWNER/NAME)
#   .env        GITHUB_PAT, GITHUB_USER, GITEA_TOKEN (all optional, each
#               asked when missing)
#
# Environment
#   REPOFOUNDRY_NAME       project name used in messages (default: RepoFoundry)
#   REPOFOUNDRY_SYNC_WAIT  seconds to wait before reading the first mirror
#                          sync result (default: 3)
#   TMPDIR                 where the private temporary directory is created
#
# Requires
#   bash 4.4 or later, git, curl, mktemp; jq and ssh are optional (jq is used
#   for JSON when present; ssh is used for the Gitea SSH test).
#   Also the base tools sed, grep, head, tr, sleep, find, cp, mkdir, chmod, env, rm,
#   rmdir and uname, and
#   stat (GNU "stat -c" or BSD "stat -f"; only used outside Windows).
#
# Implements
#   MIL-001 tasks 1 to 6, MIL-002 tasks 1 to 5 and MIL-003 tasks 1 to 4
#   (issues #3 to #13 and #15 to #18), user stories US-001.01 to US-001.03,
#   UC-001 steps 1 to 10; see docs/. Deviation from the request: its second
#   GITEA_URL key is named GITEA_API_URL.
#
# Tracing
#   set -x is switched off while the script runs, because a trace would print
#   every secret the script handles.
#
# Structure
#   This file is the entry point. The work is split by responsibility into
#   the files in lib/ next to it (one job per file, see the first lines of
#   each file): constants, output, temp, util, validate, config, tools, json,
#   http, api, prompts, credentials, project, hosts, preflight, steps, plan,
#   repositories, mirror, git, localproject, framework, envfile, apply and cli. The files are loaded
#   from this directory only.
#
# Exit codes
#   0 success (or a dry run, or a "no" at the final question), 1 a failed
#   check, bad input or a failed step, 2 a usage error.
set -Eeuo pipefail

if [[ $- == *x* ]]; then
  set +x
  printf 'warning: tracing (set -x) is disabled because it would print secrets\n' >&2
fi

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
  printf 'error: bash 4.4 or later is required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
fi

# Where this script lives; the library files and the project root are found
# from here, never from the current directory.
readonly SCRIPT_FILE="${BASH_SOURCE[0]}"
case "${BASH_SOURCE[0]}" in
  */*) script_path_dir="${BASH_SOURCE[0]%/*}" ;;
  *) script_path_dir="." ;;
esac
SCRIPT_DIR="$(cd "$script_path_dir" && pwd)"
readonly SCRIPT_DIR
unset script_path_dir
# The script lives in src/; the configuration files live one level up, in
# the project root, next to config.env.example and .env.example.
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_ROOT

# shellcheck source=lib/constants.sh
source "$SCRIPT_DIR/lib/constants.sh"
# shellcheck source=lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=lib/temp.sh
source "$SCRIPT_DIR/lib/temp.sh"
# shellcheck source=lib/util.sh
source "$SCRIPT_DIR/lib/util.sh"
# shellcheck source=lib/validate.sh
source "$SCRIPT_DIR/lib/validate.sh"
# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/tools.sh
source "$SCRIPT_DIR/lib/tools.sh"
# shellcheck source=lib/json.sh
source "$SCRIPT_DIR/lib/json.sh"
# shellcheck source=lib/http.sh
source "$SCRIPT_DIR/lib/http.sh"
# shellcheck source=lib/api.sh
source "$SCRIPT_DIR/lib/api.sh"
# shellcheck source=lib/prompts.sh
source "$SCRIPT_DIR/lib/prompts.sh"
# shellcheck source=lib/credentials.sh
source "$SCRIPT_DIR/lib/credentials.sh"
# shellcheck source=lib/project.sh
source "$SCRIPT_DIR/lib/project.sh"
# shellcheck source=lib/hosts.sh
source "$SCRIPT_DIR/lib/hosts.sh"
# shellcheck source=lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"
# shellcheck source=lib/steps.sh
source "$SCRIPT_DIR/lib/steps.sh"
# shellcheck source=lib/plan.sh
source "$SCRIPT_DIR/lib/plan.sh"
# shellcheck source=lib/repositories.sh
source "$SCRIPT_DIR/lib/repositories.sh"
# shellcheck source=lib/mirror.sh
source "$SCRIPT_DIR/lib/mirror.sh"
# shellcheck source=lib/git.sh
source "$SCRIPT_DIR/lib/git.sh"
# shellcheck source=lib/localproject.sh
source "$SCRIPT_DIR/lib/localproject.sh"
# shellcheck source=lib/framework.sh
source "$SCRIPT_DIR/lib/framework.sh"
# shellcheck source=lib/envfile.sh
source "$SCRIPT_DIR/lib/envfile.sh"
# shellcheck source=lib/apply.sh
source "$SCRIPT_DIR/lib/apply.sh"
# shellcheck source=lib/cli.sh
source "$SCRIPT_DIR/lib/cli.sh"

# finish runs on every exit: it reports what a run that started creating
# things did or did not do, then removes the temporary files. It keeps the
# exit status of the run.
finish() {
  local code=$?
  if ((IS_CREATION_STARTED)); then
    report_outcome "$code"
  fi
  cleanup
}

main() {
  trap 'on_error "$LINENO"' ERR
  trap finish EXIT
  is_valid_repo_name "$PROJECT_NAME" ||
    die "REPOFOUNDRY_NAME is not a valid project name"
  parse_args "$@"
  check_tools
  setup_temp_dir
  load_configuration
  collect_credentials GITEA_TOKEN
  collect_project_details
  if ((PROJECT[has_github])); then
    collect_credentials GITHUB_PAT GITHUB_USER
  fi
  init_steps
  print_summary
  run_preflight
  print_plan
  if ((IS_APPLY)); then
    apply_plan
  else
    say ""
    say "Dry run: nothing was created. Run again with --apply to create it."
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
