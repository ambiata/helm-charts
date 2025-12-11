# Postgres DB copy II

A chart to copy multiple postgres tables from one database to another one using pg_dump and pg_restore.
The chart does not create shemas or table, instead it truncates tables and syncs data.

This means any tables used here must already exist in the target database.

It will truncate all tables, and then load the new data as a single transaction.

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
