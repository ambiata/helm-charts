#!/bin/bash
date;

echo "Synchronize ${INPUT_DB_HOST}:${INPUT_SCHEMA}.\"${INPUT_TABLE}\"";
echo "to ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"";

# Output DB Connection
export PGHOST=${OUTPUT_DB_HOST} PGDATABASE=${OUTPUT_DB_NAME} PGUSER=${OUTPUT_DB_USER} PGPASSWORD=${OUTPUT_DB_PASS};

# Truncate table if required
if [[ "$TRUNCATE_TARGET_TABLE" == "true" ]]
then
  echo "Truncating ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}";
  psql  -c "TRUNCATE TABLE ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\";";
fi

# Find the oldest record in the output table so that we can export all the
# newer records than this
export OLDEST_RECORD=`(psql --tuples-only -c " \
  SELECT COALESCE(MAX(\"${TIMESTAMP_COLUMN}\"),'1900-01-01 00:00:00'::timestamp) \
  FROM ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"; \
")`;

echo "Oldest record timestamp at target ${OLDEST_RECORD}";

# Input DB Connection
export PGHOST=${INPUT_DB_HOST} PGDATABASE=${INPUT_DB_NAME} PGUSER=${INPUT_DB_USER} PGPASSWORD=${INPUT_DB_PASS};

# Copy all newer records from the input table -> CSV
export EXPORTED_RECORDS=`(psql -c "\copy  \
(SELECT * FROM ${INPUT_SCHEMA}.\"${INPUT_TABLE}\"  \
WHERE \"${TIMESTAMP_COLUMN}\" > '${OLDEST_RECORD}'::timestamp  \
	  AND \"${TIMESTAMP_COLUMN}\" < now()::timestamp - interval '${LAG_MINUTES}' minute)  \
TO '/tmp/pg-to-pg-sync.copy' WITH CSV;" | sed 's/COPY //g')`;

echo "${EXPORTED_RECORDS} records exported from ${INPUT_SCHEMA}.\"${INPUT_TABLE}\"";

# Output DB Connection
export PGHOST=${OUTPUT_DB_HOST} PGDATABASE=${OUTPUT_DB_NAME} PGUSER=${OUTPUT_DB_USER} PGPASSWORD=${OUTPUT_DB_PASS};

# Copy saved CSV -> Output Table
export IMPORTED_RECORDS=`(psql -c "\copy ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\" FROM '/tmp/pg-to-pg-sync.copy' WITH CSV;" | sed 's/COPY //g')`;

echo "${EXPORTED_RECORDS} records exported from ${INPUT_DB_HOST}:${INPUT_SCHEMA}.\"${INPUT_TABLE}\"";

# MAKE PROM METRICS
