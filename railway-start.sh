#!/usr/bin/env bash
# Start RSS-Bridge (nginx + PHP-FPM) on Railway.
# - listens on $PORT
# - keeps the cache and custom files on the volume at $RSSBRIDGE_DATA_DIR (/data)
# - exits non-zero if nginx or PHP-FPM stops, so Railway's ON_FAILURE policy restarts it
set -euo pipefail

export PORT="${PORT:-8080}"
DATA_DIR="${RSSBRIDGE_DATA_DIR:-/data}"

mkdir -p "$DATA_DIR/cache" "$DATA_DIR/config"
chown www-data:www-data "$DATA_DIR/cache"
# Files written by an older container may belong to root after a restore; fix only those.
find "$DATA_DIR/cache" ! -user www-data -exec chown www-data:www-data {} + 2>/dev/null || true

# Cache on the volume (file cache by default, SQLite cache if the deployer switches to it).
export RSSBRIDGE_FileCache_path="${RSSBRIDGE_FileCache_path:-$DATA_DIR/cache/}"
export RSSBRIDGE_SQLiteCache_file="${RSSBRIDGE_SQLiteCache_file:-$DATA_DIR/cache/cache.sqlite}"

# Custom files on the volume, as upstream's /config folder:
# *Bridge.php, *Format.php, config.ini.php, whitelist.txt
find "$DATA_DIR/config" -maxdepth 1 -type f -print0 2>/dev/null |
while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    case "$name" in
        *" "*) echo "Skipping custom file with a space in its name: $name" ;;
        *Bridge.php) cp -f "$file" /app/bridges/ && chown www-data:www-data "/app/bridges/$name" && echo "Custom bridge added: $name" ;;
        *Format.php) cp -f "$file" /app/formats/ && chown www-data:www-data "/app/formats/$name" && echo "Custom format added: $name" ;;
        config.ini.php|whitelist.txt) cp -f "$file" /app/ && chown www-data:www-data "/app/$name" && echo "Custom $name added" ;;
    esac
done

# nginx site: port and health-check token (rendered with PHP so no shell escaping is involved).
php -r '
$t = getenv("RSSBRIDGE_authentication_token");
$arg = ($t !== false && $t !== "") ? "&token=" . rawurlencode($t) : "";
$c = file_get_contents("/etc/rss-bridge/nginx.conf.template");
$c = str_replace(["__PORT__", "__TOKEN_ARG__"], [(string)(int)getenv("PORT"), $arg], $c);
file_put_contents("/etc/nginx/sites-available/default", $c);
'
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

nginx -t -q
php-fpm8.2 -t >/dev/null 2>&1 || php-fpm8.2 -t

mkdir -p /run/php
php-fpm8.2 --nodaemonize &
fpm_pid=$!
nginx -g 'daemon off;' &
nginx_pid=$!

stop() {
    kill -TERM "$nginx_pid" "$fpm_pid" 2>/dev/null || true
    wait || true
    exit 0
}
trap stop TERM INT

echo "RSS-Bridge listening on port ${PORT}"
set +e
wait -n "$fpm_pid" "$nginx_pid"
code=$?
echo "nginx or PHP-FPM stopped (exit ${code}); exiting so Railway restarts the service" >&2
kill -TERM "$nginx_pid" "$fpm_pid" 2>/dev/null
exit $(( code == 0 ? 1 : code ))
