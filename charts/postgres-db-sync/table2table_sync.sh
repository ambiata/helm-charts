#!/bin/bash
date;

echo "Synchronize ${INPUT_DB_HOST}:${INPUT_SCHEMA}.\"${INPUT_TABLE}\"";
echo "to ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"";

# Output DB Connection
export PGHOST=${OUTPUT_DB_HOST} PGDATABASE=${OUTPUT_DB_NAME} PGUSER=${OUTPUT_DB_USER} PGPASSWORD=${OUTPUT_DB_PASS};

# Create target table if required
if [[ -f "/usr/src/pg-db-sync/create_target.sql" ]]
then
  echo "Creating ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}";
  psql --single-transaction -f /usr/src/pg-db-sync/create_target.sql;
fi

# Truncate table if required
if [[ "$TRUNCATE_TARGET_TABLE" == "true" ]]
then
  echo "Truncating ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}";
  psql -c "TRUNCATE TABLE ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\";";
fi

# Find the oldest record in the output table so that we can export all the
# newer records than this
export OLDEST_RECORD=`(psql --tuples-only -c "\
  SELECT COALESCE(MAX(\"${TIMESTAMP_COLUMN}\"),'1900-01-01 00:00:00'::timestamp) \
  FROM ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"; \
" | xargs)`;

echo "Oldest record timestamp at target ${OLDEST_RECORD}";

# Input DB Connection
export PGHOST=${INPUT_DB_HOST} PGDATABASE=${INPUT_DB_NAME} PGUSER=${INPUT_DB_USER} PGPASSWORD=${INPUT_DB_PASS};

# Copy all newer records from the input table -> CSV
export EXPORTED_RECORDS=`(psql --single-transaction \
  --set schema=${INPUT_SCHEMA} --set table=${INPUT_TABLE}  \
  --set column=${TIMESTAMP_COLUMN} --set oldest_record="${OLDEST_RECORD}" \
  --set lag_minutes=${LAG_MINUTES} -f /usr/src/pg-db-sync/export.sql | \
  tail -n 1 | sed 's/COPY //g')`;

echo "${EXPORTED_RECORDS} records exported from ${INPUT_SCHEMA}.\"${INPUT_TABLE}\"";

# Output DB Connection
export PGHOST=${OUTPUT_DB_HOST} PGDATABASE=${OUTPUT_DB_NAME} PGUSER=${OUTPUT_DB_USER} PGPASSWORD=${OUTPUT_DB_PASS};

# Copy saved CSV -> Output Table
export IMPORTED_RECORDS=`(psql -c "\copy ${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\" FROM '/tmp/pg-to-pg-sync.copy' WITH CSV;" | sed 's/COPY //g')`;

echo "${IMPORTED_RECORDS} records imported to ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"";

# Prometheus Push Gateway Metrics
if [[ -v ${PROMETHEUS_PUSHGATEWAY_URL} ]]
then
  echo "Pushing Job Metrics to ${PROMETHEUS_PUSHGATEWAY_URL}";
  METRICS_KEY="node=\"${K8S_NODE_NAME}\", namespace=\"${K8S_POD_NAMESPACE}\", pod_ip=\"${K8S_POD_IP}\"";
  echo "Metrics Key is ${METRICS_KEY}";
  cat <<EOF | curl --data-binary @- http://${PROMETHEUS_PUSHGATEWAY_URL}/metrics/job/${CRONJOB_NAME}/instance/${K8S_POD_NAME}
# TYPE pg_db_sync_exported_records counter
postgres_db_sync_exported_records{${METRICS_KEY}} ${EXPORTED_RECORDS}
# TYPE pg_db_sync_imported_records counter
postgres_db_sync_imported_records{${METRICS_KEY}} ${IMPORTED_RECORDS}
EOF
fi

date;
