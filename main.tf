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

resource "local_file" "secret_enc_file" {
  depends_on = [null_resource.generate_gpg_key]
  for_each = var.secrets

  filename = "${each.key}-enc.yaml"
  content  = <<-CONTENT
apiVersion: v1
kind: Secret
metadata:
  name: ${each.key}
  namespace: ${var.namespace}
type: Opaque
data:
${join("\n", [
    for k, v in each.value :
    "  ${k}: ${base64encode(v)}"
  ])}
CONTENT

}

resource "null_resource" "encrypt_secrets_gpg" {
  depends_on = [null_resource.check_and_install_sops,local_file.secret_enc_file]
  for_each = var.secrets

  provisioner "local-exec" {
    command = <<-EOT
      sops --encrypt --in-place --encrypted-regex '^(${join("|", [for k, v in each.value : k])})$' \
      --pgp `gpg --fingerprint ${var.gpg_fingerprint} | grep pub -A 1 | grep -v pub | sed s/\ //g` ${local_file.secret_enc_file[each.key].filename}
    EOT
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/*enc.yaml"
  }
  
}


