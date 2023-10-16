## Kubernetes Secrets Management with SOPS and Terraform

## Prerequisites

Before you begin, make sure you have the following prerequisites installed:
- **Terraform**
- **awscli**

...

## Variables

Here are the variables that you can configure in the `variables.tf` file:

### Kubernetes Settings

- **namespace**: The namespace in which to create the secret (default: "demo").
- **secrets**: A map of secret names and key-value pairs. Modify this map to define your secrets.
- **secrets_json_file**: Path to the secrets JSON file (default: "secrets.json").
- **secret_file_list**: List of existing secret file names (default: ["secretco-enc.yaml"]).
- **env_file_path**: Path to the .env file (default: ".env").

### AWS Settings

- **aws_account_id**: AWS account id.
- **eu-central-1**: The aws region (default: "eu-central-1").
- **aws_key_id**: The aws key id (default: "1234abcd-12ab-34cd-56ef-1234567890ab").

You can modify these variables to suit your specific use case.

...

## Create Secrets

Use the secrets.json, .env file or variables secrets to define your secrets in a structured format. The .env file should contain key-value pairs, one per line.

```json
    {
      "secret-json1": {
        "namespace": "default",
        "type": "Opaque",
        "data": {
          "key_json1": "value_json1",
          "key_json2": "value_json2"
        }
      },
      "ghcrio-image-puller": {
        "namespace": "flux-system",
        "type": "kubernetes.io/dockerconfigjson",
        "data": {
          ".dockerconfigjson": "{ \"auths\": { \"ghcr.io\": { \"username\": \"bartaadalbert\", \"password\": \"ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxx\" } } }" 
        }
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
```

## Accessing Outputs

After running terraform apply, you can access the generated keys and secrets using Terraform outputs. The outputs can be found in the outputs.tf file and include:

    - sops_version: The installed SOPS version.
    - all_encrypted_secrets: All encrypted secrets, concatenate.


This Terraform module simplifies the management of Kubernetes secrets using SOPS, enabling you to securely store sensitive data.

## Usage

To use this module, create a new Terraform configuration, and include the module like this:

```hcl
module "kubernetes_secrets" {
  source = "https://github.com/bartaadalbert/kubernetes-secrets-sops.git?ref=aws"

  # Set your custom variables here
  namespace             = "demo"
  secrets               = {
    secret1 = {
      namespace = "default",
      type      = "Opaque",
      data      = {
        key1 = "value1",
        key2 = "value2"
      }
    }
  }
  aws_account_id        = var.aws_account_id
  aws_region            = var.aws_region
  aws_key_id            = var.aws_key_id
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