A chart to sync multiple postgres tables using SQL Copy.

We can provide a list of input -> output table mappings and a dictionary of database
inputs and secret information and have the script sync each table periodically, based 
on a timestamp column.

Arguments to customise the job:

- `customExportStatementConfigMap`: should point to a ConfigMap that contains a file named `export.sql` with the SQL code 
to extract the records from the source database/tables.

- `createTargetTableConfigMap`: should point to a Configmap that contains a file named `create_target.sql` with the SQL code
to create the target table on the target database.
  
- `PrometheusPushGatewayURL`: URL of a Prometheus Push Gateway Server to send the metrics of the job.

