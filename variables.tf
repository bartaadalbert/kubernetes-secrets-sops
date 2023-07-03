variable "name" {
  description = "The name of the secret"
  type        = string
  default     = "kbot"
}

variable "namespace" {
  description = "The namespace in which to create the secret"
  type        = string
  default     = "demo"
}

variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "kms_key_ring" {
  description = "The name of the KMS key ring"
  type        = string
  default     = "sops-flux-1"
}

variable "kms_crypto_key" {
  description = "The name of the KMS crypto key"
  type        = string
  default     = "sops-key-flux-1"
}

variable "secrets" {
  description = "Map of secret names and key-value pairs"
  type        = map(map(string))
  default     = {}
}

variable "sops_version" {
  description = "The version of SOPS to download"
  type        = string
  default     = "v3.7.3"
}

variable "sops_os" {
  description = "The target operating system for SOPS"
  type        = string
  default     = "linux"
}

variable "sops_arch" {
  description = "The target architecture for SOPS"
  type        = string
  default     = "amd64"
}