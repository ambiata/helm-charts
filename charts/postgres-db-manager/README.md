# Postgres DB Manager

## Introduction

This chart simply manages db, users and access rights for posgresql db on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.12+
- Helm 3
- Postgres DB instance running

## Parameters

The following table lists the parameters of this chart.

| Parameter (* = required parameters)             | Description                                                                | default                    |
|:------------------------------------------------|:---------------------------------------------------------------------------|:---------------------------|
|`postgresqlAdminCredentials.initDb` *            | DB of the admin user                                                       |                            |
|`postgresqlAdminCredentials.secretName` *        | The name of the secret containing the admin credentials. By the default, the following fields need to be provided: `PGHOST`, `PGPASSWORD`, `PGUSER`, `PGPORT`. The name of the field can be override with `postgresqlAdminCredentials.secretKeys`||
|`databases`                                      | List of databases that need to be created. Every databases should have a field `name`           |            |
|`users`                                          | List of users that need to be added. Every user have the following fields: `username`, `passwordSecretName`, `passwordSecretKey` (key inside the secret containing the user password), and `accesses`. `accesses` is a list of databases that the user has access to, readonly or not. Every access has the following fields: `db` (the name of the db), `readOnly` (optional, false by default), `schemas` (optional, additional schemas that a readonly user will be able to access. It will always include `public` even if omitted), `targetUser` (optional, default to the admin user selected in this script. Used only for readonly accesses, the read only user will have access to all the future tables this user is creating in the selected schemas.)||
|`postgresqlAdminCredentials.secretKeys.host`     | Name of the secret key for the host field                                  |PGHOST                      |
|`postgresqlAdminCredentials.secretKeys.password` | Name of the secret key for admin password field                            |PGPASSWORD                  |
|`postgresqlAdminCredentials.secretKeys.user`     | Name of the secret key for admin username field                            |PGUSER                      |
|`postgresqlAdminCredentials.secretKeys.port`     | Name of the secret key for db port field                                   |PGPORT                      |
|`image.repository`                               | Repository of the postgresql image                                         |docker.io/bitnami/postgresql|
|`image.pullPolicy`                               | Kubernetes image pull policy                                               |IfNotPresent                |
|`image.tag`                                      | Tag of the postgresql image                                                |11.7.0-debian-10-r43        |
|`imagePullSecrets`                               | List of kubertnetes image pull secrets                                     |                            |
|`nameOverride`                                   | Override the name of the chart                                             |                            |
|`fullnameOverride`                               | Override the full name of the chart and component                          |                            |
    

## Local test

To generate the manifest:
```shell
helm template my-release charts/postgres-db-manager -f charts/postgres-db-manager/ci/test-values.yaml --debug
```
