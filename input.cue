package ddcompose

import (
	"dagger.io/dagger"
)

#Manifest: {
	source: dagger.#FS
	name:   string
	path:   string
	excludes: [...string]
	present:    bool | *true
	remoteHost: string
	remotePath: string
	env: [envname = string]: string | dagger.#Secret
}

#SSH: {
	config:     dagger.#FS
	privateKey: dagger.#Secret

	dest?: string
	if dest != _|_ {
		mounts: {
			"ssh": {
				"dest":   dest
				contents: config
			}
			"ssh-private-key": {
				"dest":   "\(dest)/id_rsa"
				contents: privateKey
			}
		}
	}
}

#SOPS: {
	age?: dagger.#Secret

	dest?: string
	if dest != _|_ {
		mounts: {
			if age != _|_ {
				"sops-age": {
					"dest":   "\(dest)/age/keys.txt"
					contents: age
				}
			}
		}
	}
}
