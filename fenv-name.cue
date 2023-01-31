package ddcompose

import (
	"strings"
	"universe.dagger.io/docker"
)

#FenvName: {
	manifests: [...#Manifest]
	sops: #SOPS

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
			(sops & {dest: "/root/.config/sops"}).mounts
		}
		entrypoint: ["/scripts/fenv-name-entrypoint.sh"]
		export: directories: "/tmp/fenv.txt": _
	}
}
