package ddcompose

import (
	"dagger.io/dagger"
)

#DDCompose: {
	manifests: [...#Manifest]
	sops: age: bool | *true

	plan: dagger.#Plan & {
		client: filesystem: {
			"manifests": read: contents: dagger.#FS
			".ssh": read: {
				contents: dagger.#FS
				exclude: ["id_rsa"]
			}
			".ssh/id_rsa": read: contents: dagger.#Secret
			if sops.age {
				".sops/age/keys.txt": read: contents: dagger.#Secret
			}

			"_output": write: contents: actions.fenvname.export.directories."/tmp/fenv.txt"
		}

		actions: fenvname: #FenvName & {
			source: client.filesystem."manifests".read.contents
		}

		actions: deploy: {
			for manifest in manifests {
				(manifest.name): (manifest.remoteHost): (manifest.remotePath): {
					rsync: #Rsync & {
						"manifest": manifest & {
							source: client.filesystem."manifests".read.contents
						}
						ssh: {
							config:     client.filesystem.".ssh".read.contents
							privateKey: client.filesystem.".ssh/id_rsa".read.contents
						}
						excludes: ["__sops__*"]
					}
					compose: #Compose & {
						manifest: rsync.manifest
						ssh:      rsync.ssh
						if client.filesystem.".sops/age/keys.txt" != _|_ {
							sops: age: client.filesystem.".sops/age/keys.txt".read.contents
						}
						env: "_RSYNC_EXIT": "\(rsync.exit)"
					}
				}
			}
		}
	}
}
