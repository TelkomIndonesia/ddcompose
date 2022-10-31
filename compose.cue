package ddcompose

import (
	dockerDagger "universe.dagger.io/docker"
	"dagger.io/dagger"
)

_#compose: {
	manifest: #Manifest
	ssh:      #SSH
	sops:     #SOPS
	docker: config?: dagger.#Secret

	dockerDagger.#Run & {
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
			if docker.config != _|_ {
				"config": {
					dest:     "/root/.docker/config.json"
					contents: docker.config
				}
			}

			source: {
				dest:     workdir
				contents: manifest.source
				source:   manifest.path
			}
		}
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
