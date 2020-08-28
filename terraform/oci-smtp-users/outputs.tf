output "SMTP_Credentials" {
  value = <<-EOT
    %{for i in oci_identity_smtp_credential.smtp.*}
    desc: ${i.description}
    user: ${i.username}
    pass: ${i.password}

    %{endfor}
  EOT
}
