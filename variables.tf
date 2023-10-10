#------------kubernetes settings-------
variable "namespace" {
  description = "The namespace in which to create the secret"
  type        = string
  default     = "demo"
}

variable "secrets" {
  description = "Map of secret names and key-value pairs"
  type        = map(map(string))
  default     = {
    secret1 = {
      key1 = "value1"
      key2 = "value2"
    }
    secret2 = {
      key1 = "value1"
      key2 = "value2"
    }
  }
}

variable "secrets_json_file" {
  description = "Path to the secrets JSON file"
  type        = string
  default     = "secrets.json"
}

variable "secret_file_list" {
  description = "List of existing secret file names"
  type        = list(string)
  default     = ["secretco-enc.yaml"]
}
#--------End kubernetes settings----------





#-------Begin GCP settings----------
variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
  default     = "devops"
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
#------------END GCP GOOGLE settings--------





#----------GPG settings--------

variable "generate_gpg_key" {
  description = "Set to false to not generate a GPG key pair."
  default     = true
}

variable "name_real" {
  description = "The GPG name"
  type        = string
  default     = "devops"
}

variable "gpg_fingerprint" {
  description = "GPG key id"
  type        = string
  default     = "my@my.local"
}

# Please specify how long the key should be valid.
#      0 = key does not expire
#   <n>  = key expires in n days
#   <n>w = key expires in n weeks
#   <n>m = key expires in n months
#   <n>y = key expires in n years
variable "expire_date" {
  description = "GPG key expire"
  type        = string
  default     = "0"
}

#---------End GPG settings--------------