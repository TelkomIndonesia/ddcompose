package ddcompose

import (
	dockerDagger "universe.dagger.io/docker"
	"dagger.io/dagger"
)

_#compose: {
	manifest: #Manifest
	ssh:      #SSH
	sops:     #SOPS
	docker: {
		config?: dagger.#Secret
		socket?: dagger.#Socket
	}

	dockerDagger.#Run & {
		_input: _#image
		input:  _input.output
		workdir: {
			if manifest.remotePath != _|_ {
				manifest.remotePath
			}
			if manifest.remotePath == _|_ {
				"\(env.DDCOMPOSE_PWD)/manifests/\(manifest.path)"
			}
		}
		env: manifest.env & {
			if manifest.remoteHost != _|_ {
				"DOCKER_HOST": "ssh://\(manifest.remoteHost)"
			}
		}
		mounts: {
			(ssh & {dest: "/root/.ssh"}).mounts
			(sops & {dest: "/root/.config/sops"}).mounts
			if docker.config != _|_ {
				"config": {
					dest:     "/root/.docker/config.json"
					contents: docker.config
				}
			}
			if docker.socket != _|_ {
				"docker": {
					dest:     "/var/run/docker.sock"
					contents: docker.socket
				}
			}

			source: {
				dest:     workdir
				contents: manifest.source
				source:   manifest.path
			}
		}
		entrypoint: ["/scripts/compose-entrypoint.sh"]
	}
}

#Compose: _#compose & {
	manifest: _
	always:   true
	command: {
		name: "docker"
		if manifest.present {
			args: ["compose", "up", "-d", "--wait", "--remove-orphans"]
		}
		if !manifest.present {
			args: ["compose", "down"]
		}
	}
}
