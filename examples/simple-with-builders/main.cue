package main

import (
	"dagger.io/dagger"

	"github.com/telkomindonesia/ddcompose"
)

dagger.#Plan & (ddcompose.#DDCompose & {
	builders: true
	manifests: [
		{
			name:       "awesome-service"
			path:       "service"
			remoteHost: "host1.example.test"
			remotePath: "/opt/docker/awesome-service"
		},
	]}).plan
