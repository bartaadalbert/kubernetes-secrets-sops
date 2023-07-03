resource "null_resource" "encrypt_secrets" {
  for_each = var.secrets

  triggers = {
    secret_content = each.value
    file_content   = local_file.secret_enc_file[each.key].content
  }

  provisioner "local-exec" {
    command     = "sops -e --gcp-kms projects/${var.gcp_project}/locations/global/keyRings/${var.kms_key_ring}/cryptoKeys/${var.kms_crypto_key} --encrypted-regex '^(.*)$' ${local_file.secret_enc_file[each.key].filename}"
    interpreter = ["bash", "-c"]
  }
}

resource "kubernetes_secret" "secrets" {
  for_each = var.secrets

  metadata {
    name      = each.key
    namespace = var.namespace
  }

  data = each.value
}

resource "local_file" "secret_enc_file" {
  for_each = var.secrets

  filename = "${each.key}-enc.yaml"
  content  = <<CONTENT
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

  provisioner "local-exec" {
  command = <<COMMAND
  command -v sops >/dev/null 2>&1 || \
  (echo "SOPS is not installed. Installing..." && \
  curl -L -o /usr/local/bin/sops \
  https://github.com/getsops/sops/releases/download/${var.sops_version}/sops-${var.sops_version}.${var.sops_os}.${var.sops_arch} && \
  chmod +x /usr/local/bin/sops)
COMMAND
    interpreter = ["bash", "-c"]
  }
}
