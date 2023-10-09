data "local_file" "sops_version" {
  depends_on = [null_resource.check_and_install_sops]
  filename = "${path.module}/sops.version"
}

output "sops_version" {
  depends_on = [null_resource.check_and_install_sops]
  description = "The sops version installed."
  value       = data.local_file.sops_version.content
}

data "local_file" "private_key_gpg" {
  depends_on = [null_resource.generate_gpg_key]
  filename = "${path.module}/secret_key.asc"
}

output "private_key_gpg" {
  depends_on = [null_resource.generate_gpg_key]
  description = "The private key ready for gpg."
  value       = data.local_file.private_key_gpg.content
  sensitive = true
}

data "local_file" "public_key_gpg" {
  depends_on = [null_resource.generate_gpg_key]
  filename = "${path.module}/public_key.asc"
}

output "public_key_gpg" {
  depends_on = [null_resource.generate_gpg_key]
  description = "The public key ready for gpg."
  value       = data.local_file.public_key_gpg.content
}