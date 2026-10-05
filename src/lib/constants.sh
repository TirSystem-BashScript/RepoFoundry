# shellcheck shell=bash
# constants.sh - Constants and the shared state of a run.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# The state variables are read and written by the other library files; this
# is the one place that declares them.
# shellcheck disable=SC2034  # read and written by the other library files

readonly PROJECT_NAME="${REPOFOUNDRY_NAME:-RepoFoundry}"
readonly VERSION="0.2.0"
readonly EXIT_FAILURE=1
readonly EXIT_USAGE=2
readonly MAX_VALUE_LENGTH=2048
readonly MAX_DESCRIPTION_LENGTH=350
readonly HTTP_TIMEOUT_SECONDS=30
readonly DEFAULT_MIRROR_INTERVAL="10m0s"
readonly DEFAULT_SSH_PORT=10022
readonly AGPL_LICENSE_KEY="AGPL-3.0"
readonly DEFAULT_BRANCH="main"
readonly PLAN_STEPS=("GitHub repository" "Gitea repository" "Push mirror")
# shellcheck disable=SC2034  # read through namerefs (parse_env_file)
readonly CONFIG_KEYS=(GITHUB_API_URL GITHUB_WEB_URL GITEA_URL GITEA_API_URL
  GITEA_SSH_PORT MIRROR_INTERVAL)
readonly CREDENTIAL_KEYS=(GITHUB_PAT GITHUB_USER GITEA_TOKEN)

CONFIG_FILE="$PROJECT_ROOT/config.env"
ENV_FILE="$PROJECT_ROOT/.env"
TMP_DIR=""
HAS_JQ=0
HTTP_STATUS=0
HTTP_BODY_FILE=""
HTTP_ERROR=""
REPLY=""
IS_APPLY=0
IS_CREATION_STARTED=0
SECRET_VALUES=()
TEMP_FILES=()
declare -A CONFIG=()
declare -A CREDENTIALS=()
declare -A PROJECT=()
# Facts found by the preflight checks (logins, owner kinds, repository state).
declare -A STATE=()
# Outcome of each step in PLAN_STEPS, for the final report.
declare -A STEP_STATUS=()
declare -A STEP_DETAIL=()
