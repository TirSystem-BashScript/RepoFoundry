#!/usr/bin/env bash
# lib.sh - tiny test helpers for the RepoFoundry tests (sourced, not run).
#
# Each test file defines functions named test_*; run-tests.sh calls them.
# The helpers run create-project.sh in separate bash processes with a private
# work directory and stub tools on PATH, so a test never touches the network,
# the real .env or the repository.
#
# Requires: bash 4.4 or later.

# shellcheck disable=SC2016,SC2034  # stub and snippet text is literal on purpose; OUT, ERR and STATUS are read by the test files
REPO_ROOT="$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)"
readonly REPO_ROOT
readonly SRC_DIR="$REPO_ROOT/src"
readonly SCRIPT="$SRC_DIR/create-project.sh"

# Distinctive fake credentials; the tests search all output for them.
readonly FAKE_GITEA_TOKEN="giteaFAKEtoken1234567890"
readonly FAKE_GITHUB_PAT="ghpFAKEtoken1234567890"

# Answers to the prompts: name, description, visibility, Gitea owner, GitHub
# yes or no, GitHub owner, directory, plan gate.
readonly ANSWERS_GITHUB=$'my-app\nA test app\n\nTirSystem\ny\nacme-org\n\nn\n'
readonly ANSWERS_GITEA_ONLY=$'my-app\n\n\nTirSystem\nn\n\nn\n'

SHARED_REMOTES=""
TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
WORK=""
OUT=""
ERR=""
STATUS=0

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf 'FAIL %s: %s\n' "$CURRENT_TEST" "$1"
}

check() {
  TESTS_RUN=$((TESTS_RUN + 1))
}

assert_eq() {
  check
  if [[ $2 != "$3" ]]; then
    fail "$1: expected '$2', got '$3'"
  fi
}

assert_status() {
  assert_eq "$1 (exit status)" "$2" "$3"
}

assert_contains() {
  check
  if [[ $2 != *"$3"* ]]; then
    fail "$1: output does not contain '$3'"
  fi
}

assert_not_contains() {
  check
  if [[ $2 == *"$3"* ]]; then
    fail "$1: output contains '$3' but must not"
  fi
}

# assert_before NAME A B: the line numbers A and B are set and A comes first.
assert_before() {
  check
  if [[ -z $2 || -z $3 ]] || ((10#$2 >= 10#$3)); then
    fail "$1: expected the step at line '$2' before the step at line '$3'"
  fi
}

assert_file_exists() {
  check
  if [[ ! -e $2 ]]; then
    fail "$1: '$2' does not exist"
  fi
}

assert_file_missing() {
  check
  if [[ -e $2 ]]; then
    fail "$1: '$2' exists but must not"
  fi
}

# new_workdir: create a private work directory with a stub bin directory.
new_workdir() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/repofoundry-test.XXXXXX")"
  mkdir -p "$WORK/bin" "$WORK/tmp"
  write_gitconfig
}

# write_gitconfig: the git configuration every test run uses instead of the
# real user's (GIT_CONFIG_GLOBAL), so no test depends on or changes it. The
# remote addresses of Gitea and the framework are redirected to local bare
# repositories (see setup_local_remotes); nothing reaches the network.
write_gitconfig() {
  cat >"$WORK/gitconfig" <<EOF
[user]
	name = Test User
	email = test@example.test
[protocol "file"]
	allow = always
[url "file://$WORK/remote/"]
	insteadOf = https://git.example.test/
[url "file://$WORK/remote/"]
	insteadOf = ssh://git@git.example.test:10022/
EOF
}

# ensure_shared_remotes: build, once per run of the suite, the local bare
# repositories that stand in for Gitea (TirSystem/my-app.git, holding the
# license commit) and for the framework (a copy of the real one).
ensure_shared_remotes() {
  if [[ -n $SHARED_REMOTES && -d $SHARED_REMOTES ]]; then
    return 0
  fi
  SHARED_REMOTES="$(mktemp -d "${TMPDIR:-/tmp}/repofoundry-remotes.XXXXXX")"
  mkdir -p "$SHARED_REMOTES/TirSystem"
  git clone -q --bare "$REPO_ROOT/framework" "$SHARED_REMOTES/TirSystem/SQA-QC-Framework.git"
  git init -q --bare "$SHARED_REMOTES/TirSystem/my-app.git"
  git init -q "$SHARED_REMOTES/seed"
  git -C "$SHARED_REMOTES/seed" symbolic-ref HEAD refs/heads/main
  printf 'GNU AFFERO GENERAL PUBLIC LICENSE (test copy)\n' >"$SHARED_REMOTES/seed/LICENSE"
  git -C "$SHARED_REMOTES/seed" add LICENSE
  git -c user.name=Seed -c user.email=seed@example.test -C "$SHARED_REMOTES/seed" commit -q -m "Initial commit"
  git -C "$SHARED_REMOTES/seed" push -q "$SHARED_REMOTES/TirSystem/my-app.git" main
  find "$SHARED_REMOTES/seed" \( -type f -o -type l \) -delete
  find "$SHARED_REMOTES/seed" -depth -type d -exec rmdir {} +
}

# remove_shared_remotes: delete the shared repositories at the end of the run.
remove_shared_remotes() {
  if [[ -n $SHARED_REMOTES && -d $SHARED_REMOTES ]]; then
    find "$SHARED_REMOTES" \( -type f -o -type l \) -delete
    find "$SHARED_REMOTES" -depth -type d -exec rmdir {} +
  fi
  SHARED_REMOTES=""
}

# setup_local_remotes: this test's own copy of the local remotes.
setup_local_remotes() {
  ensure_shared_remotes
  cp -R "$SHARED_REMOTES" "$WORK/remote"
}

# remove_workdir: delete the work directory without a recursive rm: files
# first, then the now empty directories from the bottom up.
remove_workdir() {
  if [[ -n $WORK && -d $WORK ]]; then
    find "$WORK" \( -type f -o -type p \) -delete
    find "$WORK" -depth -type d -exec rmdir {} +
  fi
  WORK=""
}

# write_fixtures: valid config.env and .env in the work directory.
write_fixtures() {
  cat >"$WORK/config.env" <<EOF
# test configuration
GITHUB_API_URL=https://api.github.com
GITHUB_WEB_URL=https://github.com
GITEA_URL=https://git.example.test/
GITEA_API_URL=https://git.example.test/api/v1
EOF
  cat >"$WORK/.env" <<EOF
GITHUB_PAT=$FAKE_GITHUB_PAT
GITHUB_USER=octo-user
GITEA_TOKEN=$FAKE_GITEA_TOKEN
EOF
}

# write_stub NAME BODY: install an executable stub tool in the work bin.
write_stub() {
  printf '#!/usr/bin/env bash\n%s\n' "$2" >"$WORK/bin/$1"
  chmod +x "$WORK/bin/$1"
}

# write_curl_stub: a curl that records every call and answers from the
# routes file in the work directory (see write_routes). Without a routes file
# it answers STUB_CURL_STATUS (default 200) with the body STUB_CURL_BODY.
# Records: curl.args (all arguments), curl.config (the private config file),
# curl.calls ("METHOD URL" per call) and curl.bodies (each request body).
write_curl_stub() {
  cat >"$WORK/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$STUB_DIR/curl.args"
out="" cfg="" data=""
while (($# > 0)); do
  case "$1" in
    --output) out="$2"; shift 2 ;;
    --config) cfg="$2"; shift 2 ;;
    --data-binary) data="${2#@}"; shift 2 ;;
    *) shift ;;
  esac
done
url="" method=""
if [[ -n $cfg ]]; then
  cat "$cfg" >>"$STUB_DIR/curl.config"
  url="$(sed -n 's/^url = "\(.*\)"$/\1/p' "$cfg")"
  method="$(sed -n 's/^request = "\(.*\)"$/\1/p' "$cfg")"
fi
printf '%s %s\n' "$method" "$url" >>"$STUB_DIR/curl.calls"
if [[ -n $data && -f $data ]]; then
  printf '%s %s\n%s\n' "$method" "$url" "$(cat "$data")" >>"$STUB_DIR/curl.bodies"
fi
status="${STUB_CURL_STATUS:-200}"
body="${STUB_CURL_BODY:-}"
if [[ -z $body ]]; then body="{\"ok\":true}"; fi
if [[ -f $STUB_DIR/routes ]]; then
  status=404
  body="{\"message\":\"Not Found\"}"
  n=0 first_unused="" last_match=""
  while IFS='|' read -r m pattern st rest; do
    n=$((n + 1))
    if [[ $m == "$method" && $url == *"$pattern" ]]; then
      last_match=$n
      if [[ -z $first_unused ]] && ! grep -qx "$n" "$STUB_DIR/routes.used" 2>/dev/null; then
        first_unused=$n
      fi
    fi
  done <"$STUB_DIR/routes"
  pick="${first_unused:-$last_match}"
  if [[ -n $pick ]]; then
    if [[ -n $first_unused ]]; then printf '%s\n' "$pick" >>"$STUB_DIR/routes.used"; fi
    IFS='|' read -r _ _ status body <<<"$(sed -n "${pick}p" "$STUB_DIR/routes")"
  fi
fi
if [[ $status == exit* ]]; then exit "${status#exit}"; fi
if [[ -n $out ]]; then printf '%s' "$body" >"$out"; fi
printf '%s' "$status"
exit "${STUB_CURL_EXIT:-0}"
STUB
  chmod +x "$WORK/bin/curl"
}

# write_ssh_stub [EXIT]: an ssh that records its arguments and, by default,
# answers like a Gitea server that accepted the key.
write_ssh_stub() {
  cat >"$WORK/bin/ssh" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$@" >>"\$STUB_DIR/ssh.args"
if [[ ${1:-0} == 0 ]]; then
  echo "Hi there, gitea-user! You've successfully authenticated, but Gitea does not provide shell access."
else
  echo "Permission denied (publickey)."
fi
exit ${1:-0}
STUB
  chmod +x "$WORK/bin/ssh"
}

# write_routes: read the routes for the stub curl from stdin. One route per
# line: METHOD|URL-SUFFIX|STATUS|BODY. A request takes the first matching
# route that was not used yet, so repeated calls can get different answers;
# when all are used, the last match answers again. STATUS "exitN" makes curl
# fail with exit code N.
write_routes() {
  cat >"$WORK/routes"
  : >"$WORK/routes.used"
}

# prepend_route LINE: answer a request before the routes already written.
prepend_route() {
  local rest
  rest="$(cat "$WORK/routes")"
  printf '%s\n%s\n' "$1" "$rest" >"$WORK/routes"
  # The lines moved, so the record of used routes no longer applies.
  : >"$WORK/routes.used"
}

# write_happy_routes: both hosts accept the tokens; Gitea owner TirSystem and
# GitHub owner acme-org are organizations; nothing exists yet.
write_happy_routes() {
  write_routes <<'ROUTES'
GET|/api/v1/user|200|{"login":"gitea-user"}
GET|/api/v1/orgs/TirSystem|200|{"username":"TirSystem"}
GET|/api/v1/users/gitea-user/orgs/TirSystem/permissions|200|{"can_create_repository":true,"is_owner":true}
GET|/api/v1/licenses|200|[{"key":"AGPL-3.0","name":"AGPL-3.0"}]
GET|/api/v1/repos/TirSystem/my-app|404|{"message":"not found"}
GET|api.github.com/user|200|{"login":"octo-user"}
GET|api.github.com/user/memberships/orgs/acme-org|200|{"state":"active","role":"member"}
GET|api.github.com/repos/acme-org/my-app|404|{"message":"Not Found"}
GET|/api/v1/repos/TirSystem/my-app/push_mirrors|200|[]
GET|/api/v1/repos/TirSystem/my-app/push_mirrors|200|[{"remote_address":"https://github.com/acme-org/my-app.git","sync_on_commit":true,"interval":"10m0s","last_error":""}]
POST|api.github.com/orgs/acme-org/repos|201|{"html_url":"https://github.com/acme-org/my-app"}
POST|/api/v1/orgs/TirSystem/repos|201|{"html_url":"https://git.example.test/TirSystem/my-app"}
POST|/api/v1/repos/TirSystem/my-app/push_mirrors|200|{"remote_address":"https://github.com/acme-org/my-app.git"}
POST|/api/v1/repos/TirSystem/my-app/push_mirrors-sync|200|{}
ROUTES
}

# setup_hosts: fixtures, stub curl and ssh, and the happy routes.
setup_hosts() {
  write_fixtures
  write_curl_stub
  write_ssh_stub 0
  write_happy_routes
  setup_local_remotes
}

# calls: the "METHOD URL" lines the stub curl received (empty if none).
calls() {
  if [[ -f $WORK/curl.calls ]]; then
    cat "$WORK/curl.calls"
  fi
}

# run_cli STDIN ARGS...: run create-project.sh with answers from STDIN (a
# string). Sets OUT, ERR and STATUS.
run_cli() {
  local input="$1"
  shift
  STATUS=0
  # Run inside the work directory: a relative project directory such as
  # ./my-app is then created there, never in the repository.
  (cd "$WORK" && PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" \
    REPOFOUNDRY_SYNC_WAIT=0 GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    "$BASH" "$SCRIPT" "$@" <<<"$input" >"$WORK/out.txt" 2>"$WORK/err.txt") ||
    STATUS=$?
  OUT="$(cat "$WORK/out.txt")"
  ERR="$(cat "$WORK/err.txt")"
}

# run_lib INPUT CODE: source create-project.sh and run CODE in a fresh bash,
# so that single functions can be tested. Sets OUT, ERR and STATUS.
run_lib() {
  local input="$1"
  STATUS=0
  {
    printf '#!/usr/bin/env bash\nsource "%s"\n' "$SCRIPT"
    printf '%s\n' "$2"
  } >"$WORK/snippet.sh"
  (cd "$WORK" && PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" \
    REPOFOUNDRY_SYNC_WAIT=0 GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    "$BASH" "$WORK/snippet.sh" <<<"$input" >"$WORK/out.txt" 2>"$WORK/err.txt") ||
    STATUS=$?
  OUT="$(cat "$WORK/out.txt")"
  ERR="$(cat "$WORK/err.txt")"
}
