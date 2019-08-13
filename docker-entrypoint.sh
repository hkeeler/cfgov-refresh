#!/bin/bash --login
# NOTE: By forcing a login shell, /etc/profile is always sourced,
# unlike the non-interactive shell you get by default with `docker run`.

set -e

echo "Using '$(python --version 2>&1)' from '$(which python)'"


# Add .env to user environment
if [ ! -f "${APP_HOME}/.env" ]; then
    echo "ERROR: ${APP_HOME}/.env not found."
    exit 1
fi

cp ${APP_HOME}/.env /etc/profile.d/cfgov-env.sh
source /etc/profile


# Wait for postgres database to become available
retry_count=0
max_retries=30
wait_secs=5

echo "Checking if '${DATABASE_HOST}' database is available..."

until /usr/pgsql-10/bin/pg_isready -q -h ${DATABASE_HOST}
do
    retry_count=$((retry_count + 1))

    if [ $retry_count -eq $max_retries ]; then
        echo "'${DATABASE_HOST}' database not available after $((wait_secs * max_retries)) second max wait time."
        exit 2
    fi

    echo "'${DATABASE_HOST}' database not yet available.  Sleeping $wait_secs seconds..."
    sleep $wait_secs
done

echo "'${DATABASE_HOST}' database is available.'"


# $AUTO_INIT_DB specifies whether or not to run the initial-data.sh
if [[ ${AUTO_INIT_DB} == 'ON' ]]; then
    echo "'${DATABASE_HOST}' database auto-migration starting..."
    ${APP_HOME}/initial-data.sh
    echo "'${DATABASE_HOST}' database auto-migration complete."
elif [[ ${AUTO_INIT_DB} == 'OFF' ]]; then
    echo "'${DATABASE_HOST}' database auto-migration disabled."
else
    echo "AUTO_INIT_DB value '${AUTO_INIT_DB}' invalid.  Must be 'ON' or 'OFF'."
    exit 1
fi


# Execute the Docker CMD
exec "$@"
