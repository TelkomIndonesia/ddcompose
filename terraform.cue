package ddcompose

import (
	"path"
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#Terraform: {
	source:    dagger.#FS
	manifests: dagger.#FS
	sops:      #SOPS

	_sourceDir:    "/src"
	_manifestsDir: "/manifests"
	_build:        docker.#Build & {
		steps: [
			docker.#Pull & {
				source:      "hashicorp/terraform"
				resolveMode: "forcePull"
			},
			docker.#Copy & {
				_source: docker.#Pull & {
					source:      "mozilla/sops:v3-alpine"
					resolveMode: "forcePull"
				}
				contents: _source.image.rootfs
				source:   "/usr/local/bin/sops"
				dest:     "/usr/local/bin/sops"
			},
			docker.#Run & {
				entrypoint: []
				command: {
					name: "apk"
					args: ["add", "--no-cache", "bash"]
				}
			},

			docker.#Copy & {
				dest:     _sourceDir
				contents: source
			},
			docker.#Copy & {
				dest:     _manifestsDir
				contents: manifests
			},

			docker.#Run & {
				workdir: _sourceDir
				mounts: {
					(sops & {dest: "/root/.config/sops"}).mounts

					"terraform.sh": {
						_script: core.#Source & {
							path: "."
							include: ["terraform.sh"]
						}
						dest:     "/terraform.sh"
						contents: _script.output
						source:   "/terraform.sh"
					}
					".terraform": {
						dest:     path.Resolve(workdir, ".terraform")
						contents: core.#CacheDir & {
							id: ".terraform"
						}
					}
					"tmp": {
						dest:     "/tmp"
						contents: core.#TempDir
					}
				}
				env: "TF_VAR_manifests_dir": _manifestsDir
				entrypoint: []
				command: name: mounts."terraform.sh".dest
			},
		]
	}

	_source: core.#Subdir & {
		input: _build.output.rootfs
		path:  _sourceDir
	}
	_manifests: core.#Subdir & {
		input: _build.output.rootfs
		path:  _manifestsDir
	}
	output: {
		source:    _source.output
		manifests: _manifests.output
	}
}
