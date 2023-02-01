package ddcompose

import (
	"dagger.io/dagger"
)

// Definition of docker-compose manifest
#Manifest: {
	// The root of manifests folder that contain **all** manifests definition
	source: dagger.#FS

	// The name of this particular manifest
	name: string
	// Relative path in the `source` that contains the manifest files
	path: string
	// When `present` is false, the manifest will be destroyed via `docker compose down`
	present: bool | *true
	// The remote host where the manifest files will be sync to and deployed
	remoteHost?: string
	// The remote path where the manifest files will be sync to
	remotePath?: string
	// Additional environment to be passed to `docker compose`
	env: [envname = string]: string | dagger.#Secret
}

// SSH Connection config
#SSH: {
	// Folder contains SSH-related files that is usually found on ~/.ssh
	config: dagger.#FS
	// the private key
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

// SOPS information
#SOPS: {
	// Folder containing ".sops.yaml"
	config?: dagger.#FS
	// 'age' encryption key used to decrypt sops-encrypted files
	age?: dagger.#Secret

	dest?: string
	if dest != _|_ {
		mounts: {
			if config != _|_ {
				"sops-config": {
					dest:     ".sops.yaml"
					contents: config
					source:   ".sops.yaml"
				}
			}
			if age != _|_ {
				"sops-age": {
					"dest":   "\(dest)/age/keys.txt"
					contents: age
				}
			}
		}
	}
}
