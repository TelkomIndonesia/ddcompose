package ddcompose

import (
	"strings"
	"universe.dagger.io/docker"
)

#FenvName: {
	manifests: [...#Manifest]

	docker.#Run & {
		_input:  _#image
		input:   _input.output
		workdir: "/mnt"
		mounts: {
			for manifest in manifests {
				"\(manifest.remoteHost)--\(manifest.remotePath)": {
					dest:     "\(workdir)/" + strings.Replace("\(manifest.name)__\(manifest.remoteHost)__\(manifest.remotePath)", "/", "_", -1)
					contents: manifest.source
					source:   manifest.path
				}
			}
		}
		entrypoint: []
		command: {
			name: "bash"
			flags: "-c": """
				set -euo pipefail
				
				for DIR in */ ; do
					cd "$DIR"
					echo "=== $(basename $DIR) ===" >> /tmp/fenv.txt
					/scripts/fenv-name.sh | tee -a /tmp/fenv.txt
					echo >> /tmp/fenv.txt
					cd ..
				done
				"""
		}
		export: files: "/tmp/fenv.txt": _
	}
}
