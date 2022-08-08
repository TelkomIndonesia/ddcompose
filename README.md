# DDCompose

A [Dagger](https://dagger.io/) module for managing and deploying [Docker Compose](https://docs.docker.com/compose/) manifests through SSH connection.

## Getting Started

- [Initiate](https://docs.dagger.io/1239/making-reusable-package#create-the-base-dagger-project) a dagger project.
- Create `manifests` directory under root fo the project directory and puts all docker compose and all related files there. You can create as many subfolder as needed.
- Import and unify the [`#DDCompose.plan`](./ddcompose.cue#L15) with [`dagger.#Plan`](https://docs.dagger.io/1202/plan)
- Fill [`#DDCompose.manifests`] with information related to all manifests in `manifests` directory. See [#Manifest](./input.cue#L8) for all avaialable fields.

Example:

Suppose there is an `awesome-service` with the following docker compose related files:

```bash
$ find manifests 
manifests
manifests/host1.example.test/awesome-service
manifests/host1.example.test/awesome-service/settings.conf
manifests/host1.example.test/awesome-service/docker-compose.yml
```

To deploy this manifest to `host1.example.test` and put the all the files inside `/opt/docker/awesome-service`, the main cue should look like this

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
