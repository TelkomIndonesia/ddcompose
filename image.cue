package ddcompose

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

_#image: docker.#Build & {
	steps: [
		docker.#Pull & {
			source:      "docker:20.10.17-cli-alpine3.16"
			resolveMode: "forcePull"
		},
		docker.#Run & {
			command: {
				name: "apk"
				args: ["add", "--no-cache", "openssh-client", "bash", "rsync"]
			}
		},
		docker.#Copy & {
			_source: core.#Source & {
				path: "."
				include: [
					"*.sh",
				]
			}
			contents: _source.output
			dest:     "/scripts"
		},
		docker.#Copy & {
			_source: docker.#Pull & {
				source:      "mozilla/sops:v3-alpine"
				resolveMode: "forcePull"
			}
			contents: _source.image.rootfs
			source:   "/usr/local/bin/sops"
			dest:     "/usr/local/bin/sops"
		},
		docker.#Set & {
			config: entrypoint: ["/scripts/docker-entrypoint.sh"]
		},
	]
}
