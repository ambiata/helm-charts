#!/bin/bash
date;
set -e

export INPUT="${INPUT_DB_NAME}:${INPUT_SCHEMA}.${INPUT_TABLE}"
export OUTPUT="${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.${OUTPUT_TABLE}"

echo "Synchronize ${INPUT}";
echo "to ${OUTPUT}";

# Input DB Connection
export PGHOST=${INPUT_DB_HOST} PGDATABASE=${INPUT_DB_NAME} PGUSER=${INPUT_DB_USER} PGPASSWORD=${INPUT_DB_PASS};

# Copy all records from the input table -> CSV
export EXPORTED_RECORDS=`(psql --single-transaction \
  --set schema=${INPUT_SCHEMA} --set table=${INPUT_TABLE}  \
  -f /usr/src/pg-db-sync/export_all.sql | \
  tail -n 1 | sed 's/COPY //g')`;

echo "${EXPORTED_RECORDS} records exported from ${INPUT}";

# Output DB Connection
export PGHOST=${OUTPUT_DB_HOST} PGDATABASE=${OUTPUT_DB_NAME} PGUSER=${OUTPUT_DB_USER} PGPASSWORD=${OUTPUT_DB_PASS};

# Create target table (required) if it doesn't already exist
echo "Creating ${OUTPUT_DB_NAME}:${OUTPUT_SCHEMA}.\"${OUTPUT_TABLE}\"";
psql -e --single-transaction --set schema=${OUTPUT_SCHEMA} --set table=${OUTPUT_TABLE} --set list_column_names_data_types="${OUTPUT_LIST_COLUMN_NAMES_DATA_TYPES}" -f /usr/src/pg-db-sync/create_target.sql;

# Copy saved CSV -> Output Table Temp 2
export LOAD_TABLE=$(psql -e <<EOF
BEGIN;
delete from ${OUTPUT_SCHEMA}.${OUTPUT_TABLE};
\copy ${OUTPUT_SCHEMA}.${OUTPUT_TABLE} FROM '/tmp/pg-to-pg-sync.copy' WITH CSV;
COMMIT;
EOF
);

# (Note: not sure yet how to get the number out of the above, though it is echoed anyway)
export IMPORTED_RECORDS=`(echo $LOAD_TABLE | sed 's/COPY //g')`;
echo "${IMPORTED_RECORDS} records imported to ${OUTPUT}";

# Prometheus Push Gateway Metrics
if [[ -v PROMETHEUS_PUSHGATEWAY_URL ]]
then
  echo "Pushing Job Metrics to ${PROMETHEUS_PUSHGATEWAY_URL}";
  METRICS_KEY="source=\"${INPUT}\", target=\"${OUTPUT}\", node=\"${K8S_NODE_NAME}\", namespace=\"${K8S_POD_NAMESPACE}\", pod_ip=\"${K8S_POD_IP}\"";
  echo "Metrics Key is ${METRICS_KEY}";
  cat <<EOF | curl --data-binary @- http://${PROMETHEUS_PUSHGATEWAY_URL}/metrics/job/${CRONJOB_NAME}/instance/${K8S_POD_NAME}
# TYPE postgres_db_sync_exported_records gauge
postgres_db_sync_exported_records{${METRICS_KEY}} ${EXPORTED_RECORDS}
# TYPE postgres_db_sync_imported_records gauge
postgres_db_sync_imported_records{${METRICS_KEY}} ${IMPORTED_RECORDS}
# TYPE postgres_db_sync_since_epoch gauge
postgres_db_sync_since_epoch{${METRICS_KEY}} ${OLDEST_RECORD_EPOCH}
EOF
fi

date;
