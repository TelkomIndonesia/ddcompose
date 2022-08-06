package ddcompose

import (
	"universe.dagger.io/docker"
)

_#compose: {
	manifest: #Manifest
	ssh:      #SSH
	sops:     #SOPS

	docker.#Run & {
		_input:  _#image
		input:   _input.output
		workdir: manifest.remotePath
		env: {
			manifest.env
			"DOCKER_HOST": "ssh://\(manifest.remoteHost)"
		}
		mounts: {
			(ssh & {dest: "/root/.ssh"}).mounts
			(sops & {dest: "/root/.config/sops"}).mounts

			source: {
				dest:     workdir
				contents: manifest.source
				source:   manifest.path
			}
		}
	}
}

#Compose: _#compose & {
	manifest: _, ssh: _, sops: _

	_config: _#compose & {
		"manifest": manifest, "ssh": ssh, "sops": sops

		always: true
		command: {
			name: "/bin/bash"
			flags: "-c": """
				set -euo pipefail

				docker compose config | md5sum | tee /tmp/config
				"""
		}
		export: directories: "/tmp/config": _
	}

	env: COMPOSE_SKIP_RSYNC: "true"
	mounts: config: {
		dest:     "/tmp/config"
		contents: _config.export.directories."/tmp/config"
	}
	command: {
		name: "docker"
		if manifest.present {
			args: ["compose", "up", "-d"]
		}
		if !manifest.present {
			args: ["compose", "down"]
		}
	}
}
