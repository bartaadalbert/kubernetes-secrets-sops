data "local_file" "sops_version" {
  depends_on = [null_resource.check_and_install_sops]
  filename = "${path.module}/sops.version"
}

output "sops_version" {
  depends_on = [null_resource.check_and_install_sops]
  description = "The sops version installed."
  value       = data.local_file.sops_version.content
}

data "local_file" "all_encrypted_secrets" {
  depends_on = [null_resource.concatenate_encrypted_secrets]
  filename = "${path.module}/all-encrypted-secrets.yaml"
}

output "all_encrypted_secrets" {
  depends_on = [null_resource.concatenate_encrypted_secrets]
  description = "All encrypted secrets data."
  value       = data.local_file.all_encrypted_secrets.content
}