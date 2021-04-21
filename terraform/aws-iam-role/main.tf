module "admin_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.admin_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

module "readonly_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.readonly_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

module "security_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.security_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

module "leaddeveloper_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.leaddeveloper_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

module "frontenddeveloper_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.frontenddeveloper_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
module "backenddeveloper_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.backenddeveloper_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
module "platform_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.platform_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
module "qualityassurance_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.qualityassurance_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
module "projectteam_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.projectteam_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
module "developer_label" {
  source     = "../terraform-null-label"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.developer_name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}
#####################################################################

#####################################################################
locals {
  role_readonly_name = join("", aws_iam_role.readonly.*.name)
  role_admin_name    = join("", aws_iam_role.admin.*.name)
  role_security_name = join("", aws_iam_role.security.*.name)
  role_leaddeveloper_name = join("", aws_iam_role.leaddeveloper.*.name)
  role_frontenddeveloper_name = join("", aws_iam_role.frontenddeveloper.*.name)
  role_backenddeveloper_name = join("", aws_iam_role.backenddeveloper.*.name)
  role_platform_name = join("", aws_iam_role.platform.*.name)
  role_qualityassurance_name = join("", aws_iam_role.qualityassurance.*.name)
  role_projectteam_name = join("", aws_iam_role.projectteam.*.name)
  role_developer_name    = join("", aws_iam_role.developer.*.name)
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "role_trust" {
  count = local.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "manage_mfa" {
  count = local.enabled ? 1 : 0

  statement {
    sid = "AllowUsersToCreateEnableResyncTheirOwnVirtualMFADevice"

    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/&{aws:username}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}",
    ]
  }

  statement {
    sid = "AllowUsersToDeactivateTheirOwnVirtualMFADevice"

    actions = [
      "iam:DeactivateMFADevice",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/&{aws:username}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    sid = "AllowUsersToDeleteTheirOwnVirtualMFADevice"

    actions = [
      "iam:DeleteVirtualMFADevice",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/&{aws:username}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }

  statement {
    sid = "AllowUsersToListMFADevicesandUsersForConsole"

    actions = [
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ListUsers",
    ]

    resources = [
      "*",
    ]
  }
}
data "aws_iam_policy_document" "allow_change_password" {
  count = local.enabled ? 1 : 0

  statement {
    actions = ["iam:ChangePassword"]

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]
  }

  statement {
    actions   = ["iam:GetAccountPasswordPolicy"]
    resources = ["*"]
  }

  statement {
    actions = ["iam:GetLoginProfile"]

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "allow_key_management" {
  statement {
    actions = [
      "iam:DeleteAccessKey",
      "iam:GetAccessKeyLastUsed",
      "iam:UpdateAccessKey",
      "iam:GetUser",
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
    ]

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/&{aws:username}"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

locals {
  enabled             = var.enabled == "true" ? true : false
  admin_user_names    = length(var.admin_user_names) > 0 ? true : false
  readonly_user_names = length(var.readonly_user_names) > 0 ? true : false
  security_user_names = length(var.security_user_names) > 0 ? true : false
  leaddeveloper_user_names = length(var.leaddeveloper_user_names) > 0 ? true : false
  frontenddeveloper_user_names = length(var.frontenddeveloper_user_names) > 0 ? true : false
  backenddeveloper_user_names = length(var.backenddeveloper_user_names) > 0 ? true : false
  platform_user_names = length(var.platform_user_names) > 0 ? true : false
  qualityassurance_user_names = length(var.qualityassurance_user_names) > 0 ? true : false
  projectteam_user_names = length(var.projectteam_user_names) > 0 ? true : false
  developer_user_names    = length(var.developer_user_names) > 0 ? true : false
}

##################
#admin config
##################
resource "aws_iam_policy" "manage_mfa_admin" {
  count       = local.enabled ? 1 : 0
  name        = "${module.admin_label.id}-permit-mfa"
  description = "Allow admin users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_admin" {
  count       = local.enabled ? 1 : 0
  name        = "${module.admin_label.id}-permit-change-password"
  description = "Allow admin users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_admin" {
  name        = "${module.admin_label.id}-allow-key-management"
  description = "Allow admin users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_admin" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.admin.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_admin" {
  count       = local.enabled ? 1 : 0
  name        = "${module.admin_label.id}-permit-assume-role"
  description = "Allow assuming admin role"
  policy      = join("", data.aws_iam_policy_document.assume_role_admin.*.json)
}

resource "aws_iam_group" "admin" {
  count = local.enabled ? 1 : 0
  name  = module.admin_label.id
}

resource "aws_iam_role" "admin" {
  count              = local.enabled ? 1 : 0
  name               = module.admin_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_admin" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.admin.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_admin.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_admin" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.admin.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_admin.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_admin" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.admin.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_admin.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_admin" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.admin.*.name)
  policy_arn = aws_iam_policy.allow_key_management_admin.arn
}

resource "aws_iam_role_policy_attachment" "admin" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.admin.*.name)
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "admin" {
  count = local.enabled && local.admin_user_names ? 1 : 0
  name  = module.admin_label.id
  group = join("", aws_iam_group.admin.*.id)
  users = var.admin_user_names
}

##################
#readonly config
##################

resource "aws_iam_policy" "manage_mfa_readonly" {
  count       = local.enabled ? 1 : 0
  name        = "${module.readonly_label.id}-permit-mfa"
  description = "Allow readonly users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_readonly" {
  count       = local.enabled ? 1 : 0
  name        = "${module.readonly_label.id}-permit-change-password"
  description = "Allow readonly users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_readonly" {
  name        = "${module.readonly_label.id}-permit-manage-keys"
  description = "Allow readonly users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_readonly" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.readonly.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_readonly" {
  count       = local.enabled ? 1 : 0
  name        = "${module.readonly_label.id}-permit-assume-role"
  description = "Allow assuming readonly role"
  policy      = join("", data.aws_iam_policy_document.assume_role_readonly.*.json)
}

resource "aws_iam_group" "readonly" {
  count = local.enabled ? 1 : 0
  name  = module.readonly_label.id
}

resource "aws_iam_role" "readonly" {
  count              = local.enabled ? 1 : 0
  name               = module.readonly_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_readonly" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.readonly.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_readonly.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_readonly" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.readonly.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_readonly.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_change_password_readonly" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.readonly.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_readonly.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_readonly" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.readonly.*.name)
  policy_arn = aws_iam_policy.allow_key_management_readonly.arn
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.readonly.*.name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_membership" "readonly" {
  count = local.enabled && local.readonly_user_names ? 1 : 0
  name  = module.readonly_label.id
  group = join("", aws_iam_group.readonly.*.id)
  users = var.readonly_user_names
}

##################
#security config
##################


resource "aws_iam_policy" "manage_mfa_security" {
  count       = local.enabled ? 1 : 0
  name        = "${module.security_label.id}-permit-mfa"
  description = "Allow security users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_security" {
  count       = local.enabled ? 1 : 0
  name        = "${module.security_label.id}-permit-change-password"
  description = "Allow security users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_security" {
  name        = "${module.security_label.id}-allow-key-management"
  description = "Allow security users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_security" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.security.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_security" {
  count       = local.enabled ? 1 : 0
  name        = "${module.security_label.id}-permit-assume-role"
  description = "Allow assuming security role"
  policy      = join("", data.aws_iam_policy_document.assume_role_security.*.json)
}

resource "aws_iam_group" "security" {
  count = local.enabled ? 1 : 0
  name  = module.security_label.id
}

resource "aws_iam_role" "security" {
  count              = local.enabled ? 1 : 0
  name               = module.security_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_security" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.security.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_security.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_security" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.security.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_security.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_security" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.security.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_security.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_security" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.security.*.name)
  policy_arn = aws_iam_policy.allow_key_management_security.arn
}

resource "aws_iam_role_policy_attachment" "security" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.security.*.name)
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_group_membership" "security" {
  count = local.enabled && local.security_user_names ? 1 : 0
  name  = module.security_label.id
  group = join("", aws_iam_group.security.*.id)
  users = var.security_user_names
}

##################
#lead developer config
##################
resource "aws_iam_policy" "manage_mfa_leaddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.leaddeveloper_label.id}-permit-mfa"
  description = "Allow leaddeveloper users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_leaddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.leaddeveloper_label.id}-permit-change-password"
  description = "Allow leaddeveloper users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_leaddeveloper" {
  name        = "${module.leaddeveloper_label.id}-allow-key-management"
  description = "Allow leaddeveloper users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_leaddeveloper" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.leaddeveloper.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_leaddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.leaddeveloper_label.id}-permit-assume-role"
  description = "Allow assuming leaddeveloper role"
  policy      = join("", data.aws_iam_policy_document.assume_role_leaddeveloper.*.json)
}

resource "aws_iam_group" "leaddeveloper" {
  count = local.enabled ? 1 : 0
  name  = module.leaddeveloper_label.id
}

resource "aws_iam_role" "leaddeveloper" {
  count              = local.enabled ? 1 : 0
  name               = module.leaddeveloper_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}
resource "aws_iam_group_policy_attachment" "assume_role_leaddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.leaddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_leaddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_leaddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.leaddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_leaddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_leaddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.leaddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_leaddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_leaddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.leaddeveloper.*.name)
  policy_arn = aws_iam_policy.allow_key_management_leaddeveloper.arn
}

resource "aws_iam_role_policy_attachment" "leaddeveloper" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.leaddeveloper.*.name)
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "leaddeveloper" {
  count = local.enabled && local.leaddeveloper_user_names ? 1 : 0
  name  = module.leaddeveloper_label.id
  group = join("", aws_iam_group.leaddeveloper.*.id)
  users = var.leaddeveloper_user_names
}

##################
#Frontend developer config
##################
resource "aws_iam_policy" "manage_mfa_frontenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.frontenddeveloper_label.id}-permit-mfa"
  description = "Allow frontenddeveloper users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_frontenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.frontenddeveloper_label.id}-permit-change-password"
  description = "Allow frontenddeveloper users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_frontenddeveloper" {
  name        = "${module.frontenddeveloper_label.id}-allow-key-management"
  description = "Allow frontenddeveloper users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_frontenddeveloper" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.frontenddeveloper.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_frontenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.frontenddeveloper_label.id}-permit-assume-role"
  description = "Allow assuming frontenddeveloper role"
  policy      = join("", data.aws_iam_policy_document.assume_role_frontenddeveloper.*.json)
}

resource "aws_iam_group" "frontenddeveloper" {
  count = local.enabled ? 1 : 0
  name  = module.frontenddeveloper_label.id
}

resource "aws_iam_role" "frontenddeveloper" {
  count              = local.enabled ? 1 : 0
  name               = module.frontenddeveloper_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_frontenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.frontenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_frontenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_frontenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.frontenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_frontenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_frontenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.frontenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_frontenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_frontenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.frontenddeveloper.*.name)
  policy_arn = aws_iam_policy.allow_key_management_frontenddeveloper.arn
}

resource "aws_iam_role_policy_attachment" "frontenddeveloper" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.frontenddeveloper.*.name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_membership" "frontenddeveloper" {
  count = local.enabled && local.frontenddeveloper_user_names ? 1 : 0
  name  = module.frontenddeveloper_label.id
  group = join("", aws_iam_group.frontenddeveloper.*.id)
  users = var.frontenddeveloper_user_names
}

##################
#Backend Developer config
##################
resource "aws_iam_policy" "manage_mfa_backenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.backenddeveloper_label.id}-permit-mfa"
  description = "Allow backenddeveloper users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_backenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.backenddeveloper_label.id}-permit-change-password"
  description = "Allow backenddeveloper users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_backenddeveloper" {
  name        = "${module.backenddeveloper_label.id}-allow-key-management"
  description = "Allow backenddeveloper users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_backenddeveloper" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.backenddeveloper.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_backenddeveloper" {
  count       = local.enabled ? 1 : 0
  name        = "${module.backenddeveloper_label.id}-permit-assume-role"
  description = "Allow assuming backenddeveloper role"
  policy      = join("", data.aws_iam_policy_document.assume_role_backenddeveloper.*.json)
}

resource "aws_iam_group" "backenddeveloper" {
  count = local.enabled ? 1 : 0
  name  = module.backenddeveloper_label.id
}

resource "aws_iam_role" "backenddeveloper" {
  count              = local.enabled ? 1 : 0
  name               = module.backenddeveloper_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_backenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.backenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_backenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_backenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.backenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_backenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_backenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.backenddeveloper.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_backenddeveloper.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_backenddeveloper" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.backenddeveloper.*.name)
  policy_arn = aws_iam_policy.allow_key_management_backenddeveloper.arn
}

resource "aws_iam_role_policy_attachment" "backenddeveloper" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.backenddeveloper.*.name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_membership" "backenddeveloper" {
  count = local.enabled && local.backenddeveloper_user_names ? 1 : 0
  name  = module.backenddeveloper_label.id
  group = join("", aws_iam_group.backenddeveloper.*.id)
  users = var.backenddeveloper_user_names
}

##################
#Platform config
##################
resource "aws_iam_policy" "manage_mfa_platform" {
  count       = local.enabled ? 1 : 0
  name        = "${module.platform_label.id}-permit-mfa"
  description = "Allow platform users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_platform" {
  count       = local.enabled ? 1 : 0
  name        = "${module.platform_label.id}-permit-change-password"
  description = "Allow platform users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_platform" {
  name        = "${module.platform_label.id}-allow-key-management"
  description = "Allow platform users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_platform" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.platform.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_platform" {
  count       = local.enabled ? 1 : 0
  name        = "${module.platform_label.id}-permit-assume-role"
  description = "Allow assuming platform role"
  policy      = join("", data.aws_iam_policy_document.assume_role_platform.*.json)
}

resource "aws_iam_group" "platform" {
  count = local.enabled ? 1 : 0
  name  = module.platform_label.id
}

resource "aws_iam_role" "platform" {
  count              = local.enabled ? 1 : 0
  name               = module.platform_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_platform" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.platform.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_platform.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_platform" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.platform.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_platform.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_platform" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.platform.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_platform.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_platform" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.platform.*.name)
  policy_arn = aws_iam_policy.allow_key_management_platform.arn
}

resource "aws_iam_role_policy_attachment" "platform" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.platform.*.name)
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "platform" {
  count = local.enabled && local.platform_user_names ? 1 : 0
  name  = module.platform_label.id
  group = join("", aws_iam_group.platform.*.id)
  users = var.platform_user_names
}

##################
#Quality Assurance config
##################
resource "aws_iam_policy" "manage_mfa_qualityassurance" {
  count       = local.enabled ? 1 : 0
  name        = "${module.qualityassurance_label.id}-permit-mfa"
  description = "Allow qualityassurance users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_qualityassurance" {
  count       = local.enabled ? 1 : 0
  name        = "${module.qualityassurance_label.id}-permit-change-password"
  description = "Allow qualityassurance users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_qualityassurance" {
  name        = "${module.qualityassurance_label.id}-allow-key-management"
  description = "Allow qualityassurance users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_qualityassurance" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.qualityassurance.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_qualityassurance" {
  count       = local.enabled ? 1 : 0
  name        = "${module.qualityassurance_label.id}-permit-assume-role"
  description = "Allow assuming qualityassurance role"
  policy      = join("", data.aws_iam_policy_document.assume_role_qualityassurance.*.json)
}

resource "aws_iam_group" "qualityassurance" {
  count = local.enabled ? 1 : 0
  name  = module.qualityassurance_label.id
}

resource "aws_iam_role" "qualityassurance" {
  count              = local.enabled ? 1 : 0
  name               = module.qualityassurance_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_qualityassurance" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.qualityassurance.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_qualityassurance.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_qualityassurance" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.qualityassurance.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_qualityassurance.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_qualityassurance" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.qualityassurance.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_qualityassurance.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_qualityassurance" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.qualityassurance.*.name)
  policy_arn = aws_iam_policy.allow_key_management_qualityassurance.arn
}

resource "aws_iam_role_policy_attachment" "qualityassurance" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.qualityassurance.*.name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_membership" "qualityassurance" {
  count = local.enabled && local.qualityassurance_user_names ? 1 : 0
  name  = module.qualityassurance_label.id
  group = join("", aws_iam_group.qualityassurance.*.id)
  users = var.qualityassurance_user_names
}

##################
#projectteam config
##################
resource "aws_iam_policy" "manage_mfa_projectteam" {
  count       = local.enabled ? 1 : 0
  name        = "${module.projectteam_label.id}-permit-mfa"
  description = "Allow projectteam users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_projectteam" {
  count       = local.enabled ? 1 : 0
  name        = "${module.projectteam_label.id}-permit-change-password"
  description = "Allow projectteam users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_projectteam" {
  name        = "${module.projectteam_label.id}-allow-key-management"
  description = "Allow projectteam users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_projectteam" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.projectteam.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_projectteam" {
  count       = local.enabled ? 1 : 0
  name        = "${module.projectteam_label.id}-permit-assume-role"
  description = "Allow assuming projectteam role"
  policy      = join("", data.aws_iam_policy_document.assume_role_projectteam.*.json)
}

resource "aws_iam_group" "projectteam" {
  count = local.enabled ? 1 : 0
  name  = module.projectteam_label.id
}

resource "aws_iam_role" "projectteam" {
  count              = local.enabled ? 1 : 0
  name               = module.projectteam_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_projectteam" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.projectteam.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_projectteam.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_projectteam" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.projectteam.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_projectteam.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_projectteam" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.projectteam.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_projectteam.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_projectteam" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.projectteam.*.name)
  policy_arn = aws_iam_policy.allow_key_management_projectteam.arn
}

resource "aws_iam_role_policy_attachment" "projectteam" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.projectteam.*.name)
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "projectteam" {
  count = local.enabled && local.projectteam_user_names ? 1 : 0
  name  = module.projectteam_label.id
  group = join("", aws_iam_group.projectteam.*.id)
  users = var.projectteam_user_names
}

##################
#developer config
##################
resource "aws_iam_policy" "manage_mfa_developer" {
  count       = local.enabled ? 1 : 0
  name        = "${module.developer_label.id}-permit-mfa"
  description = "Allow developer users to manage Virtual MFA Devices"
  policy      = join("", data.aws_iam_policy_document.manage_mfa.*.json)
}

resource "aws_iam_policy" "allow_change_password_developer" {
  count       = local.enabled ? 1 : 0
  name        = "${module.developer_label.id}-permit-change-password"
  description = "Allow developer users to change password"
  policy      = join("", data.aws_iam_policy_document.allow_change_password.*.json)
}

resource "aws_iam_policy" "allow_key_management_developer" {
  name        = "${module.developer_label.id}-allow-key-management"
  description = "Allow developer users to manage their own access keys"
  policy      = data.aws_iam_policy_document.allow_key_management.json
}

data "aws_iam_policy_document" "assume_role_developer" {
  count = local.enabled ? 1 : 0

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [join("", aws_iam_role.developer.*.arn)]
  }
}

resource "aws_iam_policy" "assume_role_developer" {
  count       = local.enabled ? 1 : 0
  name        = "${module.developer_label.id}-permit-assume-role"
  description = "Allow assuming developer role"
  policy      = join("", data.aws_iam_policy_document.assume_role_developer.*.json)
}

resource "aws_iam_group" "developer" {
  count = local.enabled ? 1 : 0
  name  = module.developer_label.id
}
resource "aws_iam_role" "developer" {
  count              = local.enabled ? 1 : 0
  name               = module.developer_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.role_trust.*.json)
}

resource "aws_iam_group_policy_attachment" "assume_role_developer" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.developer.*.name)
  policy_arn = join("", aws_iam_policy.assume_role_developer.*.arn)
}

resource "aws_iam_group_policy_attachment" "manage_mfa_developer" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.developer.*.name)
  policy_arn = join("", aws_iam_policy.manage_mfa_developer.*.arn)
}

resource "aws_iam_group_policy_attachment" "allow_chage_password_developer" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.developer.*.name)
  policy_arn = join("", aws_iam_policy.allow_change_password_developer.*.arn)
}

resource "aws_iam_group_policy_attachment" "key_management_developer" {
  count      = local.enabled ? 1 : 0
  group      = join("", aws_iam_group.developer.*.name)
  policy_arn = aws_iam_policy.allow_key_management_developer.arn
}

resource "aws_iam_role_policy_attachment" "developer" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.developer.*.name)
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_membership" "developer" {
  count = local.enabled && local.developer_user_names ? 1 : 0
  name  = module.developer_label.id
  group = join("", aws_iam_group.developer.*.id)
  users = var.developer_user_names
}
