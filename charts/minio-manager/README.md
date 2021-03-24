# Minio Manager

## Introduction

This chart manages buckets, users and access rights for [Minio](https://min.io/) on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.
This chart only handles the creation of these resources. It does not manage their deletions.

To use the `versioning` option on bucket creation, the deployed minio must be [distributed](https://docs.min.io/docs/distributed-minio-quickstart-guide.html).

## Prerequisites

- Kubernetes 1.12+
- Helm 3
- Minio instance running

### Minio compatibilities

The default minio client version used in this chart has been selected to work with the minio deployment we are using.
The user of this chart must validate the compatibility of the minio deployment and the minio client used in this chart.

| Chart version  | Default minio client image                                                                                    | Expected minio deployment                                                                                          | Chart features |
|:---------------|:--------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------|---------------|
|0.2.0           |[minio/mc:RELEASE.2020-04-04T05-28-55Z](https://github.com/minio/mc/releases/tag/RELEASE.2020-04-04T05-28-55Z) |[minio/minio:RELEASE.2020-04-10T03-34-42Z](https://github.com/minio/minio/releases/tag/RELEASE.2020-04-10T03-34-42Z)| Users and policies management. Creation of buckets with policy and purge options.|
|0.3.0           |[minio/mc:RELEASE.2020-11-25T23-04-07Z](https://github.com/minio/mc/releases/tag/RELEASE.2020-11-25T23-04-07Z) |[minio/minio:RELEASE.2020-12-03T05-49-24Z](https://github.com/minio/minio/releases/tag/RELEASE.2020-12-03T05-49-24Z)| Add versioning option to bucket creation |

## Parameters

The following table lists the parameters of this chart.

| Parameter (* = required parameters)             | Description                                                                | default                    |
|:------------------------------------------------|:---------------------------------------------------------------------------|:---------------------------|
|`minioAdminCredentials.secretName` *             | The name of the secret containing the admin credentials. By the default, the following fields need to be provided: `MINIO_ENDPOINT_URL`, `MINIO_SECRET_KEY`, `MINIO_ACCESS_KEY`, `MINIO_USE_SSL`. The name of the field can be override with `minioAdminCredentials.secretKeys`||
|`users`                                          | List of users that need to be added.                                       |[]                          |
|`users[i].userCredentialsSecret` *               | Name of the secret containing the user credentials                         |                            |
|`users[i].accessKey`                             | Key in the secret containing the user's username (accesskey)               |accesskey                   |
|`users[i].secretKey`                             | Key in the secret containing the user's password (secretkey)               |secretkey                   |
|`users[i].policy`                                | Name of the policy to use. Can be a policy from the created one. Minio has `readonly`, `writeonly` and `readwrite` default policies applied for all buckets) |readonly |
|`policies`                                       | List of minio policies to create. Every policy have the following fields: `name`, `buckets` (non empty list of buckets and allowed actions on which the policy apply, see values.yaml). ||
|`minioAdminCredentials.secretKeys.endpointUrl`   | Name of the secret key for the endpoint field                              |MINIO_ENDPOINT_URL          |
|`minioAdminCredentials.secretKeys.secretKey`     | Name of the secret key for admin secret key field                          |MINIO_SECRET_KEY            |
|`minioAdminCredentials.secretKeys.accessKey`     | Name of the secret key for admin access key field                          |MINIO_ACCESS_KEY            |
|`minioAdminCredentials.secretKeys.useSsl`        | Name of the secret key for use ssl field                                   |MINIO_USE_SSL               |
|`image.repository`                               | Repository of the minio image                                              |minio/mc                    |
|`image.pullPolicy`                               | Kubernetes image pull policy                                               |IfNotPresent                |
|`image.tag`                                      | Tag of the minio image                                                     |RELEASE.2020-11-25T23-04-07Z|
|`imagePullSecrets`                               | List of kubertnetes image pull secrets                                     |                            |
|`nameOverride`                                   | Override the name of the chart                                             |                            |
|`fullnameOverride`                               | Override the full name of the chart and component                          |                            |
|`buckets`                                        | Buckets to create as a YAML object. The key is the name of the bucket      |{}                          |
|`buckets.[name].policy`                          | Policy applied on the bucket for anonymous users. Allowed policies are: [none, download, upload, public] (https://docs.min.io/docs/minio-client-complete-guide.html#policy) |none |
|`buckets.[name].purge`                           | Purge the bucket if already existent if set to true                        |false                       |
|`buckets.[name].versioning`                      | Select if the bucket should be versioned or not. If unset, the bucket versioning will be unchanged. https://docs.min.io/docs/minio-bucket-versioning-guide.html|"" |

## Local test

To generate the manifest:
```shell
helm template my-release charts/minio-manager -f charts/minio-manager/ci/test-values.yaml --debug
```
