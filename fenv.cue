package ddcompose

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#FenvName: {
	source: dagger.#FS

	docker.#Run & {
		_input:  _#image
		input:   _input.output
		workdir: "/src"
		mounts: "source": {
			dest:     "\(workdir)/manifests"
			contents: source
		}
		entrypoint: []
		command: {
			name: "sh"
			flags: "-c": """
				set -euo pipefail
				/scripts/fenv-name.sh manifests | tee /tmp/fenv.txt
				"""
		}
		export: directories: "/tmp/fenv.txt": _
	}
}
