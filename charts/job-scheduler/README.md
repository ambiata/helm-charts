# Job-Scheduler

This is a thin wrapper chart for generating Kubernetes `cronjob`s.

Values file contains a top-level map named `jobs` that must be populated with nested maps of job definitions.

The following values attributes are required:
* `job.namespace`
* `job.command`
* `job.image.repo`
* `job.schedule`

## Attributes
```
jobs:
  my_cronjob_1:
    namespace: <namespace> (required)
    schedule: <cron format scheduling spec or shortcuts> (required) e.g. "@hourly", "17 * * * *" etc
    command: <list of command segments> (required) e.g. [ "/bin/sh", "-c" ]
    args: <list of arguments to the command>. This can be used to define whole scripts via usage of `;` and multiline strings
    secretRefs: <list of secrets to export into the container environment>, e.g. [ secret1, secret2 ]
    image:
      repo: <image repository> (required)
      tag: <image tag> default: 'latest'
      pullSecrets: <list of image pull secrets> e.g. - name: my-ecr-secret
    volumes:
      - name: nfs-volume
        nfs:
          server: 192.168.1.43
          path: /source_dir_on_nfs
    volumeMounts:
    - name: nfs-volume
      mountPath: /mnt
  ...
    ...
```
