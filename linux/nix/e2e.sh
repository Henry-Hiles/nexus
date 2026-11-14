# shellcheck shell=bash

files=()
flutter_args=()
for arg in "$@"; do
    if [[ "$arg" == *.dart ]]; then files+=("$arg"); else flutter_args+=("$arg"); fi
done
if [[ ${#files[@]} -eq 0 ]]; then files=(integration_test/*_test.dart); fi

homeserver="http://localhost:8448"

if curl -s -o /dev/null "$homeserver"; then
    echo "Something is already using port 8448, like another e2e run." >&2
    exit 1
fi

work="$(mktemp -d)"
# shellcheck disable=SC2329 # Run by the trap
cleanup() {
    [[ -n "${server_pid:-}" ]] && kill "$server_pid" 2>/dev/null && wait "$server_pid" 2>/dev/null
    rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/db"
cat > "$work/continuwuity.toml" <<EOF
[global]
server_name = "localhost"
database_path = "$work/db"
address = ["127.0.0.1", "::1"]
port = 8448

[global.well_known]
client = "$homeserver"
EOF

users=(alice bob carol dave)
create_users=()
for user in "${users[@]}"; do
    create_users+=(--execute "users create-user $user ${user}pass")
done

echo "Starting Continuwuity (log: $work/continuwuity.log)..."
conduwuit -c "$work/continuwuity.toml" "${create_users[@]}" \
    > "$work/continuwuity.log" 2>&1 &
server_pid=$!

all_can_log_in() {
    for user in "${users[@]}"; do
        curl -sf -XPOST "$homeserver/_matrix/client/v3/login" \
            -d "{\"type\":\"m.login.password\",\"identifier\":{\"type\":\"m.id.user\",\"user\":\"$user\"},\"password\":\"${user}pass\"}" \
            > /dev/null || return 1
    done
}

# Wait until login succeeds, otherwise you might try to log in before the account is created
attempts=60
until all_can_log_in; do
    kill -0 "$server_pid" 2>/dev/null || { cat "$work/continuwuity.log"; exit 1; }
    (( --attempts )) || { echo "Test users weren't created" >&2; exit 1; }
    sleep 0.5
done

GOCACHE="$(go env GOCACHE)"
export GOCACHE

# shellcheck disable=SC2329
run_flutter_test() {
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS%%;*}"
    flutter test "$@" -d linux
}
export -f run_flutter_test

status=0
for file in "${files[@]}"; do
    name="$(basename "$file" .dart)"
    mkdir -p "$work/$name/data" "$work/$name/cache"

    XDG_DATA_HOME="$work/$name/data" XDG_CACHE_HOME="$work/$name/cache" \
        dbus-run-session --config-file="$DBUS_SESSION_CONFIG" -- \
        bash -c 'run_flutter_test "$@"' -- "$file" \
        --dart-define="NEXUS_E2E_HOMESERVER=$homeserver" "${flutter_args[@]}" ||
        status=$?
done
exit "$status"