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
