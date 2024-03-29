resource "null_resource" "check_and_install_sops" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v sops &> /dev/null; then
        echo "SOPS is not installed. Installing..."
        
        LATEST_SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep -Eo '"tag_name": "[^"]+"' | cut -d'"' -f4)
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)

        case "$ARCH" in
          "x86_64")
            SOPS_ARCH="amd64"
            ;;
          "aarch64")
            SOPS_ARCH="arm64"
            ;;
          *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
        esac

        case "$OS" in
          "linux")
            SOPS_OS="linux"
            ;;
          "darwin")
            SOPS_OS="darwin"
            ;;
          *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
        esac

        curl -L -o /usr/local/bin/sops \
          "https://github.com/getsops/sops/releases/download/$LATEST_SOPS_VERSION/sops-$LATEST_SOPS_VERSION.$SOPS_OS.$SOPS_ARCH" && \
        chmod +x /usr/local/bin/sops
      fi
      INSTALLED_SOPS_VERSION=$(sops --version 2>&1 | awk '{print $2}')

      # Output the installed SOPS version to a file if SOPS is installed
      if [[ ! -z "$INSTALLED_SOPS_VERSION" ]]; then
        echo $INSTALLED_SOPS_VERSION > ${path.module}/sops.version
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/sops.version"
  }
}

resource "null_resource" "generate_gpg_key" {
  count = var.generate_gpg_key ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      if ! gpg --list-keys ${var.gpg_fingerprint} &> /dev/null; then
        # Generate GPG key
        gpg --batch --generate-key <<EOF
          %no-protection
          Key-Type: default
          Subkey-Type: default
          Name-Real: ${var.name_real}
          Name-Email: ${var.gpg_fingerprint}
          Expire-Date: ${replace(var.expire_date, "\"", "")}
EOF
      else
        echo "GPG key with fingerprint ${var.gpg_fingerprint} already exists."
      fi

      # Save public and secret key to files
      gpg --armor --export ${var.gpg_fingerprint} > ${path.module}/public_key.asc
      gpg --armor --export-secret-keys ${var.gpg_fingerprint} > ${path.module}/secret_key.asc
    EOT
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/*.asc"
  }
}

resource "null_resource" "generate_secrets_json" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash

      env_file=${var.env_file_path}
      secrets_json=${var.secrets_json_file}

      if [ ! -e "$secrets_json" ] && [ -s "$env_file" ]; then
        echo "{" > "$secrets_json"
        echo '  "env_secret": {' >> "$secrets_json"
        echo '    "namespace": "${var.namespace}",' >> "$secrets_json"
        echo '    "type": "Opaque",' >> "$secrets_json"
        echo '    "data": {' >> "$secrets_json"

        # Read each line in the .env file
        while IFS= read -r line || [[ -n "$line" ]]; do
          # Split each line into key and value
          key=$(echo "$line" | cut -d= -f1)
          value=$(echo "$line" | cut -d= -f2-)

          # Add the key-value pair to the "data" object
          echo "      \"$key\": \"$value\"," >> "$secrets_json"
        done < "$env_file"

        # Remove the trailing comma from the last line in "data"
        sed -i '$ s/,$//' "$secrets_json"

        # Close the "data" object and "env_secret" object
        echo "    }" >> "$secrets_json"
        echo "  }" >> "$secrets_json"

        # Close the main JSON object
        echo "}" >> "$secrets_json"
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}


resource "null_resource" "wait_for_secrets_json" {
  # depends_on = [null_resource.check_and_install_sops]
  count = local.env_file_exists && !local.secrets_json_exists ? 1 : 0
  provisioner "local-exec" {
    command = "sleep 5"
  }
  
}


locals {
  secrets_json_exists = can(file(var.secrets_json_file))
  env_file_exists     = can(file(var.env_file_path))
  secrets_to_use = local.secrets_json_exists ? jsondecode(file(var.secrets_json_file)) : var.secrets
}

resource "local_file" "secret_enc_file" {
  depends_on = [null_resource.generate_gpg_key]
  # for_each = var.secrets
  for_each = local.secrets_to_use

  filename = "${path.module}/${each.key}-enc.yaml"
  content  = <<-CONTENT
apiVersion: v1
kind: Secret
metadata:
  name: ${each.key}
  namespace: ${each.value.namespace != "" ? each.value.namespace : var.namespace}
type: ${each.value.type != "" ? each.value.type : var.default_secret_type}
data:
${join("\n", [
    for k, v in each.value.data :
    "  ${k}: ${base64encode(v)}"
  ])}
CONTENT

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "encrypt_secrets_gpg" {
  depends_on = [null_resource.check_and_install_sops,local_file.secret_enc_file]
  # for_each = var.secrets
  for_each = local.secrets_to_use

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      sops \
      --encrypt \
      --in-place \
      --encrypted-regex '^(${join("|", [for k, v in each.value.data : k])})$' \
      --pgp `gpg --fingerprint ${var.gpg_fingerprint} | grep pub -A 1 | grep -v pub | sed s/\ //g` \
      ${local_file.secret_enc_file[each.key].filename}
    EOT
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/*enc.yaml"
  }
  
}

resource "null_resource" "encrypt_secrets_list_gpg" {
  depends_on = [null_resource.check_and_install_sops]

  triggers = {
    always_run = "${timestamp()}"
  }

  count = length(var.secret_file_list) > 0 && !can(var.secret_file_list[0]) ? length(var.secret_file_list) : 0

  provisioner "local-exec" {
    command = <<-EOT
      sops \
      --encrypt \
      --in-place \
      --pgp `gpg --fingerprint ${var.gpg_fingerprint} | grep pub -A 1 | grep -v pub | sed s/\ //g` \
      ${var.secret_file_list[count.index]}
    EOT
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "concatenate_encrypted_secrets" {
  depends_on = [null_resource.encrypt_secrets_gpg, null_resource.encrypt_secrets_list_gpg]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      first=1
      for file in ${path.module}/*-enc.yaml; do
        if [ $first -eq 1 ]; then
          cat $file >> ${path.module}/all-encrypted-secrets.yaml
          first=0
        else
          echo -e "\n---\n" >> ${path.module}/all-encrypted-secrets.yaml
          cat $file >> ${path.module}/all-encrypted-secrets.yaml
        fi
      done
    EOT
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/all-encrypted-secrets.yaml"
  }
}



