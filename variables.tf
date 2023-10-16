#------------kubernetes settings-------
variable "namespace" {
  description = "The namespace in which to create the secret"
  type        = string
  default     = "demo"
}

variable "default_secret_type" {
  description = "Default type to use if not specified in secrets"
  type        = string
  default     = "Opaque"
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


#----------AWS settinggs-----------------
variable "aws_account_id" {
  description = "The aws account ID"
  type        = string
}

variable "aws_region" {
  description = "The aws region"
  type        = string
  default     = "eu-central-1"
}

variable "aws_key_id" {
  description = "The AWS key id"
  type        = string
  default     = "1234abcd-12ab-34cd-56ef-1234567890ab"
}

#-------------END AWS settings-------------

# aws kms create-key \
#    --key-spec RSA_4096 \
#    --key-usage ENCRYPT_DECRYPT

# {
#     "KeyMetadata": {
#         "Arn": "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab",
#         "AWSAccountId": "111122223333",
#         "CreationDate": "2021-04-05T14:04:55-07:00",
#         "CustomerMasterKeySpec": "RSA_4096",
#         "Description": "",
#         "Enabled": true,
#         "EncryptionAlgorithms": [
#             "RSAES_OAEP_SHA_1",
#             "RSAES_OAEP_SHA_256"
#         ],
#         "KeyId": "1234abcd-12ab-34cd-56ef-1234567890ab",
#         "KeyManager": "CUSTOMER",
#         "KeySpec": "RSA_4096",
#         "KeyState": "Enabled",
#         "KeyUsage": "ENCRYPT_DECRYPT",
#         "MultiRegion": false,
#         "Origin": "AWS_KMS"
#     }
# }