## Kubernetes Secrets Management with SOPS and Terraform

## Prerequisites

Before you begin, make sure you have the following prerequisites installed:
- **Terraform**
- **GnuPG (GPG)**

...

## Variables

Here are the variables that you can configure in the `variables.tf` file:

### Kubernetes Settings

- **namespace**: The namespace in which to create the secret (default: "demo").
- **secrets**: A map of secret names and key-value pairs. Modify this map to define your secrets.
- **secrets_json_file**: Path to the secrets JSON file (default: "secrets.json").
- **secret_file_list**: List of existing secret file names (default: ["secretco-enc.yaml"]).
- **env_file_path**: Path to the .env file (default: ".env").

### GPG Settings

- **generate_gpg_key**: Set to false to skip GPG key pair generation (default: true).
- **name_real**: The GPG name (default: "devops").
- **gpg_fingerprint**: GPG key ID (default: "my@my.local").
- **expire_date**: GPG key expiration (default: "0").

You can modify these variables to suit your specific use case.

...

## Create Secrets

Use the secrets.json, .env file or variables secrets to define your secrets in a structured format. The .env file should contain key-value pairs, one per line.

```json
    {
    "secret1": {
        "key1": "value1",
        "key2": "value2"
    },
    "secret2": {
        "key1": "value1",
        "key2": "value2"
    }
    }
```
```env
    Create an .env file with your secrets:

    APP_SECRET_KEY=your_secret_key
    DATABASE_PASSWORD=your_database_password
```


```tf
Terraform variables:

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
```

## Accessing Outputs

After running terraform apply, you can access the generated keys and secrets using Terraform outputs. The outputs can be found in the outputs.tf file and include:

    - sops_version: The installed SOPS version.
    - private_key_gpg: The private GPG key.
    - public_key_gpg: The public GPG key.
    - all_encrypted_secrets: All encrypted secrets, concatenate.


This Terraform module simplifies the management of Kubernetes secrets using SOPS, enabling you to securely store sensitive data.

## Usage

To use this module, create a new Terraform configuration, and include the module like this:

```hcl
module "kubernetes_secrets" {
  source = "https://github.com/bartaadalbert/kubernetes-secrets-sops.git?ref=main"

  # Set your custom variables here
  namespace             = "demo"
  secrets               = {
    secret1 = {
      key1 = "value1"
      key2 = "value2"
    }
    secret2 = {
      key1 = "value1"
      key2 = "value2"
    }
  }
  generate_gpg_key      = true
  name_real             = "devops"
  gpg_fingerprint       = "my@my.local"
  expire_date           = "0"
  secrets_json_file     = "secrets.json"
  secret_file_list      = ["secretco-enc.yaml"]
  env_file_path         = ".env"
}
```


## Contributing

Feel free to contribute to this project by opening issues or pull requests.
License

This project is licensed under the MIT License.

Feel free to customize this usage guide to match the specifics of your project, and make sure to include any relevant contact or support information for your users.