package ddcompose

import (
	"dagger.io/dagger"
)

#DDCompose: {
	manifests: [...#Manifest]
	sops: {
		config: bool | *false
		age:    bool | *false
	}
	docker: config: bool | *false

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
				".sops.yaml": read: {
					contents: dagger.#FS
					path:     "."
					include: [".sops.yaml"]
				}
			}
			if sops.age {
				".sops/age/keys.txt": read: contents: dagger.#Secret
			}

			if docker.config {
				".docker/config.json": read: contents: dagger.#Secret
			}
		}
		client: env: {
			PWD:  string
			HOME: string
		}
		client: network: "unix:///var/run/docker.sock": connect: dagger.#Socket

		actions: fenvname: #FenvName & {
			"manifests": [
				for manifest in manifests {
					manifest & {
						source: client.filesystem."manifests".read.contents
					}
				},
			]
			if sops.age {
				sops: age: client.filesystem.".sops/age/keys.txt".read.contents
			}
		}

		if builders {
			actions: build: #Terraform & {
				manifests: client.filesystem."manifests".read.contents
				source:    client.filesystem."builders".read.contents
				"sops": {
					if sops.config {
						config: client.filesystem.".sops.yaml".read.contents
					}
					if sops.age {
						age: client.filesystem.".sops/age/keys.txt".read.contents
					}
				}
			}
		}

		actions: deploy: {
			_compose: {
				ssh: {
					config:     client.filesystem.".ssh".read.contents
					privateKey: client.filesystem.".ssh/id_rsa".read.contents
				}
				if sops.age {
					sops: age: client.filesystem.".sops/age/keys.txt".read.contents
				}
				if docker.config {
					docker: config: client.filesystem.".docker/config.json".read.contents
				}
				env: {
					DDCOMPOSE_PWD:  client.env.PWD
					DDCOMPOSE_HOME: client.env.HOME
				}
			}
			for manifest in manifests {
				(manifest.name): {
					if manifest.remoteHost != _|_ && manifest.remotePath != _|_ {
						(manifest.remoteHost): (manifest.remotePath): #Compose & _compose & {
							"manifest": manifest & {
								source: client.filesystem."manifests".read.contents
							}
						}
					}

					if manifest.remoteHost == _|_ || manifest.remotePath == _|_ {
						"_": "_": #Compose & _compose & {
							"manifest": manifest & {
								source: client.filesystem."manifests".read.contents
							}
							docker: socket: client.network."unix:///var/run/docker.sock".connect
						}
					}
				}
			}
		}

		client: filesystem: {
			"_output": write: contents: actions.fenvname.export.directories."/tmp/fenv.txt"
			if builders {
				"builders_output": write: {
					contents: actions.build.output.source
					path:     "builders"
				}
				"manifests_output": write: {
					contents: actions.build.output.manifests
					path:     "manifests"
				}
			}
		}
	}
}
