# shellcheck shell=bash
# constants.sh - Constants and the shared state of a run.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# The state variables are read and written by the other library files; this
# is the one place that declares them.
# shellcheck disable=SC2034  # read and written by the other library files

readonly PROJECT_NAME="${REPOFOUNDRY_NAME:-RepoFoundry}"
readonly VERSION="0.3.0"
readonly EXIT_FAILURE=1
readonly EXIT_USAGE=2
readonly MAX_VALUE_LENGTH=2048
readonly MAX_DESCRIPTION_LENGTH=350
readonly HTTP_TIMEOUT_SECONDS=30
readonly DEFAULT_MIRROR_INTERVAL="10m0s"
readonly DEFAULT_SSH_PORT=10022
readonly DEFAULT_FRAMEWORK_REPO="TirSystem/SQA-QC-Framework"
readonly AGPL_LICENSE_KEY="AGPL-3.0"
readonly NO_LICENSE_WORD="none"
readonly DEFAULT_BRANCH="main"
# What the prompts and the preset keys in config.env both tell the Maintainer
# when a value is refused.
readonly HINT_REPO_NAME="use letters, digits, '.', '_' or '-' (at most 100), not ending in .git"
readonly HINT_DESCRIPTION="at most $MAX_DESCRIPTION_LENGTH characters and no control characters"
readonly HINT_GITEA_OWNER="use letters, digits, '.', '_' or '-' (at most 39)"
readonly HINT_GITHUB_OWNER="use letters, digits or '-' (at most 39)"
readonly HINT_LICENSE="use a Gitea license key (letters, digits, '.', '+' or '-', at most 64), such as AGPL-3.0 or MIT, or none"
readonly HINT_DIRECTORY="must not be empty, start with '-' or contain control characters"
readonly HINT_TOKEN="8 to 255 letters, digits or _ . ~ + / = -"
readonly ENV_FILE_NAME=".env"
readonly PLAN_STEPS=("GitHub repository" "Gitea repository" "Push mirror"
  "Local project" "Framework" "Skills and hooks" "Templates" "Project .env")
# shellcheck disable=SC2034  # read through namerefs (parse_env_file)
readonly CONFIG_KEYS=(GITHUB_API_URL GITHUB_WEB_URL GITEA_URL GITEA_API_URL
  GITEA_SSH_PORT MIRROR_INTERVAL FRAMEWORK_REPO
  PROJECT_NAME PROJECT_DESCRIPTION PROJECT_VISIBILITY GITEA_OWNER USE_GITHUB
  GITHUB_OWNER PROJECT_DIRECTORY ENABLE_PLAN_GATE PROJECT_LICENSE)
readonly CREDENTIAL_KEYS=(GITHUB_PAT GITHUB_USER GITEA_TOKEN)

# The configuration files: named by --config and --env, or chosen by
# locate_config_file. The origin is named, folder or checkout.
CONFIG_FILE=""
ENV_FILE=""
CONFIG_ORIGIN=""
ENV_ORIGIN=""
# The folder the Maintainer started the script in.
WORKING_FOLDER=""
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
# Project details that came from config.env instead of a prompt (PRESET[name]=1).
declare -A PRESET=()
# Facts found by the preflight checks (logins, owner kinds, repository state).
declare -A STATE=()
# Outcome of each step in PLAN_STEPS, for the final report.
declare -A STEP_STATUS=()
declare -A STEP_DETAIL=()
