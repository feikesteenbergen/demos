#!/bin/bash

function usage()
{
cat <<__EOT__

Usage: $0 QUERY_FILE VARIABLES_FILE OUTPUT_FILE [psql OPTIONS]

__EOT__
}

if [ $# -lt 3 ]
then
    usage
    exit 1
fi

QUERY_FILE="$1"
shift
VARIABLES_FILE="$1"
shift
OUTPUT_FILE="$1"
shift

function bind_and_execute()
{
    (cat <<__EOT__

    \i load_variables_file.sql

    \o | cat - >> "${OUTPUT_FILE}"
    COPY (
__EOT__

    perl -pe 's/;\s*$//g' < "${QUERY_FILE}"

    cat <<__EOT__
    ) TO STDOUT WITH CSV;
__EOT__
    ) | psql --file=- --set variables_source="${VARIABLES_FILE}" --set variables_target=variables "$@"
}

cp /dev/null "${OUTPUT_FILE}"
if [ -z $DDSDATABASE ]
then
    bind_and_execute "$@"
    EXITCODE=$?
else
    EXITCODE=0
    for db in $(curl -s "http://dds.zalando.net/api/zmon_databases/environment/live/name/${DDSDATABASE}/role/slave/slave_type/standby" \
                    | grep -A 16 'shards' | grep zalando | perl -pe 's/.*: "(.*)".*/\1/g')
    do
        echo "$(date +%Y%m%d%H%M) Executing on database $db"
        bind_and_execute -d "postgresql://$db" "$@"
        MYEXIT=$?
        if [ $MYEXIT -ne 0 ]
        then
            echo "Exitcode for db=$db is $MYEXIT"
            EXITCODE=$[EXITTCODE +1]
        fi
    done
fi

exit $EXITCODE
