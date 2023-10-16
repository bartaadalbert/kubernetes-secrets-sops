#------------kubernetes settings-------
variable "namespace" {
  description = "The namespace in which to create the secret"
  type        = string
  default     = "demo"
}

variable "secrets" {
  description = "Map of secret names, namespaces, types and key-value pairs"
  type        = map(object({
    namespace = string
    type      = string
    data      = map(string)
  }))
  default     = {
    secret1 = {
      namespace = "default",
      type      = "Opaque",
      data      = {
        key1 = "value1",
        key2 = "value2"
      }
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

variable "env_file_path" {
  description = "Path to the .env file"
  type        = string
  default     = ".env"
}

#--------End kubernetes settings----------


#----------GCP settinggs-----------------
variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "kms_key_ring" {
  description = "The name of the KMS key ring"
  type        = string
  default     = "sops-key-ring"
}

variable "kms_crypto_key" {
  description = "The name of the KMS crypto key"
  type        = string
  default     = "sops-crypto-key"
}

#----------END GCP settinggs-----------------

# gcloud kms keyrings create "sops-key-ring" \
#   --location=global

# gcloud kms keys create "sops-crypto-key" \
#   --location "global" \
#   --keyring "sops-key-ring" \
#   --purpose "encryption"

# gcloud kms keys list \
#   --location "global" \
#   --keyring "sops-key-ring"

# KMS_ID=$(gcloud kms keys list --location "global" --keyring "sops-key-ring" --format 'get(name)')

# Create iam service account
# gcloud iam service-accounts create gke-cluster-demo