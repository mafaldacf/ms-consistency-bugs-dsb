variable "project_id" {
  type = string
  default = "rendezvous-437310"
}

variable "gcp_user" {
  type = string
  default = "leafen"
}

variable "credentials_file" {
  type = string
  default = "../../providers/gcp/credentials.json"
}
