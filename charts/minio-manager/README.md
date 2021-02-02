# Minio Manager

## Introduction

This chart manages buckets, users and access rights for [Minio](https://min.io/) on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.
This chart only handles the creation of these resources. It does not manage their deletions.

## Prerequisites

- Kubernetes 1.12+
- Helm 3
- Minio instance running

## Parameters

The following table lists the parameters of this chart.

| Parameter (* = required parameters)             | Description                                                                | default                    |
|:------------------------------------------------|:---------------------------------------------------------------------------|:---------------------------|
|`minioAdminCredentials.secretName` *             | The name of the secret containing the admin credentials. By the default, the following fields need to be provided: `MINIO_ENDPOINT_URL`, `MINIO_SECRET_KEY`, `MINIO_ACCESS_KEY`, `MINIO_USE_SSL`. The name of the field can be override with `minioAdminCredentials.secretKeys`||
|`users`                                          | List of users that need to be added.)                                      |[]                         |
|`users[i].userCredentialsSecret` *               | Name of the secret containing the user credentials                         |                            |
|`users[i].usernameSecretKey`                     | Key in the secret containing the user's username                           |username                    |
|`users[i].passwordSecretKey`                     | Key in the secret containing the user's password                           |password                    |
|`users[i].policy`                                | Name of the policy to use. Can be a policy from the created one. Minio has `readonly`, `writeonly` and `readwrite` default policies applied for all buckets) |"readonly" |
|`policies`                                       | List of minio policies to create. Every policy have the following fields: `name`, `readOnly` (boolean selecting if the policy is read only or readwrite. Default to `true`), `buckets` (non empty list of buckets on which the policy apply). ||
|`minioAdminCredentials.secretKeys.endpointUrl`   | Name of the secret key for the endpoint field                              |MINIO_ENDPOINT_URL          |
|`minioAdminCredentials.secretKeys.secretKey`     | Name of the secret key for admin secret key field                          |MINIO_SECRET_KEY            |
|`minioAdminCredentials.secretKeys.accessKey`     | Name of the secret key for admin access key field                          |MINIO_ACCESS_KEY            |
|`minioAdminCredentials.secretKeys.useSsl`        | Name of the secret key for use ssl field                                   |MINIO_USE_SSL               |
|`image.repository`                               | Repository of the minio image                                              |minio/mc                    |
|`image.pullPolicy`                               | Kubernetes image pull policy                                               |IfNotPresent                |
|`image.tag`                                      | Tag of the minio image                                                     |RELEASE.2021-01-05T05-03-58Z|
|`imagePullSecrets`                               | List of kubertnetes image pull secrets                                     |                            |
|`nameOverride`                                   | Override the name of the chart                                             |                            |
|`fullnameOverride`                               | Override the full name of the chart and component                          |                            |
|`buckets`                                        | List of buckets to create (list of strings)                                |[]                          |


## Local test

To generate the manifest:
```shell
helm template my-release charts/minio-manager -f charts/minio-manager/ci/test-values.yaml --debug
```
