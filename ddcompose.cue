package ddcompose

import (
	"dagger.io/dagger"
)

#DDCompose: {
	manifests: [...#Manifest]
	sops: {
		config: bool | *true
		age:    bool | *true
	}
	builders: bool | *false

	plan: dagger.#Plan & {
		client: filesystem: {
			"manifests": read: contents: dagger.#FS
			if builders {
				"builders": read: contents: dagger.#FS
			}

			".ssh": read: {
				contents: dagger.#FS
				exclude: ["id_rsa"]
			}
			".ssh/id_rsa": read: contents: dagger.#Secret

			if sops.config {
				".": read: {
					contents: dagger.#FS
					include: [".sops.yaml"]
				}
			}
			if sops.age {
				".sops/age/keys.txt": read: contents: dagger.#Secret
			}
		}

		actions: fenvname: #FenvName & {
			source: client.filesystem."manifests".read.contents
		}

		if builders {
			actions: build: {
				write: bool | *false
				#Terraform & {
					manifests: client.filesystem."manifests".read.contents
					source:    client.filesystem."builders".read.contents
					"sops": {
						if sops.config {
							config: client.filesystem.".".read.contents
						}
						if sops.age {
							age: client.filesystem.".sops/age/keys.txt".read.contents
						}
					}
				}
			}
		}

		actions: deploy: {
			for manifest in manifests {
				(manifest.name): (manifest.remoteHost): (manifest.remotePath):
					#Compose & {
						"manifest": manifest & {
							source: client.filesystem."manifests".read.contents
						}
						ssh: {
							config:     client.filesystem.".ssh".read.contents
							privateKey: client.filesystem.".ssh/id_rsa".read.contents
						}
						if sops.age {
							sops: age: client.filesystem.".sops/age/keys.txt".read.contents
						}
					}
			}
		}

		client: filesystem: {
			"_output": write: contents: actions.fenvname.export.directories."/tmp/fenv.txt"
			if builders {
				if actions.build.write {
					"builders": write: contents:  actions.build.output.source
					"manifests": write: contents: actions.build.output.manifests
				}
			}
		}
	}
}
