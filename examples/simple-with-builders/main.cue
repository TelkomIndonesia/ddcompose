package main

import (
	"dagger.io/dagger"

	"github.com/telkomindonesia/ddcompose"
)

dagger.#Plan & (ddcompose.#DDCompose & {
	sops: {
		config: true
		age:    true
	}
	builders: true
	docker: config: true
	manifests: [
		{
			name:       "awesome-service"
			path:       "service"
			remoteHost: "host1.example.test"
			remotePath: "/opt/docker/awesome-service"
		},
		{
			name:       "awesome-service"
			path:       "service"
			remoteHost: "host1.example.test"
			remotePath: "/opt/docker/awesome-service"
		},
		{
			name: "awesome-service"
			path: "service"
		},
	]}).plan
