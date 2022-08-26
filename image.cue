package ddcompose

import (
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

_#image: {
	_pull: docker.#Pull & {
		source:      "docker:20.10.17-cli-alpine3.16"
		resolveMode: "forcePull"
	}
	_apk: docker.#Run & {
		input: _pull.output

		command: {
			name: "apk"
			args: ["add", "--no-cache", "openssh-client", "bash", "rsync"]
		}
	}
	_script: docker.#Copy & {
		input: _apk.output

		_source: core.#Source & {
			path: "."
			include: [
				"*.sh",
			]
		}
		contents: _source.output
		dest:     "/scripts"
	}
	_sops: docker.#Copy & {
		input: _script.output

		_source: docker.#Pull & {
			source:      "mozilla/sops:v3-alpine"
			resolveMode: "forcePull"
		}
		contents: _source.image.rootfs
		source:   "/usr/local/bin/sops"
		dest:     "/usr/local/bin/sops"
	}
	_entrypoint: docker.#Set & {
		input: _sops.output
		config: entrypoint: ["/scripts/docker-entrypoint.sh"]
	}

	output: _entrypoint.output
}
