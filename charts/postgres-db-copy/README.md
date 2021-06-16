# Postgres DB copy

A chart to copy multiple postgres tables from one database to another one using pg_dump and pg_restore.
The chart creates the table and syncs the data.
It will truncate and then load the new data in a single transaction.

## Parameters for this job   

- Define the source db
```yaml
sourceDB:
  host: ""
  name: "postgres"
  user: "postgres"
  port: 5432
  secret: ""
  passwordKey: "PGPASSWORD"
```

- Define the target db
```yaml
targetDB:
  host: ""
  name: "postgres"
  user: "postgres"
  port: 5432
  secret: ""
  passwordKey: "PGPASSWORD"
```

- List the tables to copy
```yaml
tables: []
```

- Define when do you want to copy the tables
```yaml
cronjob:
  schedule: "@daily"
```
