# DDCompose

A [Dagger](https://dagger.io/) module for managing and deploying [Docker Compose](https://docs.docker.com/compose/) manifests through SSH connection.

## Getting Started

1. [Initiate](https://docs.dagger.io/1239/making-reusable-package#create-the-base-dagger-project) a dagger project.
1. Create `manifests` directory under root fo the project directory and puts all docker compose and all related files there. You can create as many subfolder as needed.
1. Create `.ssh` folder that _at minimum_ contains ssh private key named `id_rsa`.
1. Import and unify the [`#DDCompose.plan`](./ddcompose.cue#L15) with [`dagger.#Plan`](https://docs.dagger.io/1202/plan)
1. Fill [`#DDCompose.manifests`] with information related to all manifests in `manifests` directory. See [#Manifest](./input.cue#L8) for all avaialable fields.
1. By default, the module will load `.sops/age/keys.txt` that contains [age](https://github.com/FiloSottile/age) private key. This can be disabled by setting [`#DDCompose.sops.age`](./ddcompose.cue#L11) to `false`
1. Execute `dagger do deploy` to deploy all defined manifests.

### Example

Suppose there is an `awesome-service` with the following docker compose related files:

```bash
$ find manifests 
manifests
manifests/host1.example.test/awesome-service
manifests/host1.example.test/awesome-service/settings.conf
manifests/host1.example.test/awesome-service/docker-compose.yml
```

To deploy this manifest to `host1.example.test` and put all the manifest files inside `/opt/docker/awesome-service`, the importing cue file should look like this

```cue
package main

import (
 "dagger.io/dagger"

 "github.com/telkomindonesia/ddcompose"
)

dagger.#Plan & (ddcompose.#DDCompose & { manifests: [
        {   
            name:       "awesome-service"
            path:       "host1.example.test/awesome-service"
            remoteHost: "host1.example.test"
            remotePath: "/opt/docker/awesome-service"
        },
    ]}).plan
```

Checkout [examples](./examples/) for more sample on how to use this module.

### The `deploy` action

The `deploy` actions is composed with sub-actions structured in the following manner:

- `deploy` : `<manifest name>` : `<manifest remoteHost>` : `<manifest remotePath>` : `<manifest>`

This allow for controlling which manifest(s) to be deployed. For example:

- `dagger do deploy awesome-service` will deploy all manifest named `awesome-service`.
- `dagger do deploy awesome-service host1.example.test` will deploy all manifest named `awesome-service` only to `host1.example.test`.
- `dagger do deploy awesome-service host1.example.test /opt/docker/awesome-service` will deploy all manifest named `awesome-service` only to `host1.example.test` and only to path `/opt/docker/awesome-service`.

### The `fenvname` action

The `fenvname` action is used to generate a text file containing a list of files or folders inside `manifests` folders with their respective generated-variable name. This variable name can be included in docker compose file to force recreate of the related container when the content of the correlated file or folder changes. See [examples](./examples/simple-with-builders/manifests/service/) for more detail on how to include the [fenv](./examples/simple-with-builders/_output/fenv.txt) inside [docker compose file](./examples/simple-with-builders/manifests/service/docker-compose.yml#L6).

### SOPS encryption

By default, the module will load `.sops/age/keys.txt` that contains [age](https://github.com/FiloSottile/age) private key. This will be used when decypting file(s) with `__sops__` prefix encountered inside `manifests` dir. This can be disabled by setting [`#DDCompose.sops.age`](./ddcompose.cue#L11) to `false`.

### Manifest builders

An optional action named `build` can be enabled by setting [`#DDCompose.builders`](./ddcompose.cue#L13) to `true` which allow an execution of terraform scripts inside `builders` folder. During execution, the terraform scripts will have access to the manifests directory whose path can be accessed by defining a variable named [`manifests_dir`](./terraform.cue#L75).

If `#DDCompose.sops.config` is set to true (which require `.sops.yaml` file to be available on the root directory), then `terraform.tfstate` will be encrypted as `__sops__terraform.tfstate` after each execution and the original `terraform.tfstate` will be deleted. See [examples](./examples/simple-with-builders/builders/) for more detail.
