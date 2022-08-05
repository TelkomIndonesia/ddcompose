package ddcompose

import (
	"universe.dagger.io/docker"
)

#Rsync: {
	manifest: #Manifest
	ssh:      #SSH
	excludes: [...string]

	docker.#Run & {
		_input:  _#image
		input:   _input.output
		workdir: "/src"
		mounts: {
			"source": {
				dest:     workdir
				contents: manifest.source
			}

			(ssh & {dest: "/root/.ssh"}).mounts
		}

		always: true
		entrypoint: []
		command: {
			name: "rsync"
			flags: {
				for exclude in excludes {
					"--exclude": exclude
				}
				for exclude in manifest.excludes {
					"--exclude": exclude
				}
			}
			args: [
				"-av",
				"./\(manifest.path)/",
				"\(manifest.remoteHost):\(manifest.remotePath)",
			]
		}
	}
}
