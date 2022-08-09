variable "manifests_dir" {
  type        = string
  description = "directory that contains all manifests files"
}

variable "temporary_dir" {
  type        = string
  description = "temporary directory that will be deleted after dagger execution"
}

resource "local_file" "foo" {
  content  = yamlencode({ "foo" : "bar" })
  filename = "${var.manifests_dir}/service/config.yml"
}
