provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_iam_role" "promo" {
  count = "${length(var.all_roles)}"
  name  = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

## 3 AWS policies 

resource "aws_iam_role_policy_attachment" "aws_managed_policy-1" {
  count      = "${length(var.all_roles)}"
  role       = aws_iam_role.promo[count.index].name
  policy_arn = var.aws_managed_policies[0]
  depends_on = ["aws_iam_role.promo"]
}
resource "aws_iam_role_policy_attachment" "aws_managed_policy-2" {
  count      = "${length(var.all_roles)}"
  role       = aws_iam_role.promo[count.index].name
  policy_arn = var.aws_managed_policies[1]
  depends_on = [aws_iam_role_policy_attachment.aws_managed_policy-1]
}
resource "aws_iam_role_policy_attachment" "aws_managed_policy-3" {
  count      = "${length(var.emr_spark_roles)}"
  role       = aws_iam_role.promo[count.index].name
  policy_arn = var.aws_managed_policies[2]
  depends_on = ["aws_iam_role_policy_attachment.aws_managed_policy-2"]
}

## 8 Managed Policies 


resource "aws_iam_role_policy_attachment" "ppv_prod_ssm_policy" {
  count      = "${length(var.all_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"
  policy_arn = var.managed_policies[0]
  depends_on = ["aws_iam_role_policy_attachment.aws_managed_policy-3"]
}
resource "aws_iam_role_policy_attachment" "ppv_policy_get_bitdefender" {
  count      = "${length(var.bit_policy_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.bit_policy_roles[count.index]}"
  policy_arn = var.managed_policies[1]
  depends_on = ["aws_iam_role_policy_attachment.ppv_prod_ssm_policy"]
}
resource "aws_iam_role_policy_attachment" "ppv_kms_copy_s3_encrypted_objects" {
  count      = "${length(var.all_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"
  policy_arn = var.managed_policies[2]
  depends_on = ["aws_iam_role_policy_attachment.ppv_policy_get_bitdefender"]
}
resource "aws_iam_role_policy_attachment" "route53_manage_private_hz" {
  count      = "${length(var.all_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"
  policy_arn = var.managed_policies[3]
  depends_on = ["aws_iam_role_policy_attachment.ppv_kms_copy_s3_encrypted_objects"]
}
resource "aws_iam_role_policy_attachment" "s3_common_ro" {
  count      = "${length(var.all_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"
  policy_arn = var.managed_policies[4]
  depends_on = ["aws_iam_role_policy_attachment.route53_manage_private_hz"]
}
resource "aws_iam_role_policy_attachment" "ppv_kms_manage_encrypted_volumes" {
  count      = "${length(var.all_roles)}"
  role       = "ppv_svcrole_con_tenant${var.tenant_number}${var.all_roles[count.index]}"
  policy_arn = var.managed_policies[5]
  depends_on = ["aws_iam_role_policy_attachment.s3_common_ro"]
}
resource "aws_iam_role_policy_attachment" "ppv-byok-kms_key_access" {
  role       = aws_iam_role.promo[8].name
  policy_arn = var.managed_policies[6]
  depends_on = ["aws_iam_role_policy_attachment.ppv_kms_manage_encrypted_volumes"]
}
resource "aws_iam_role_policy_attachment" "spark_create_tag" {
  role       = aws_iam_role.promo[8].name
  policy_arn = var.managed_policies[7]
  depends_on = ["aws_iam_role_policy_attachment.ppv-byok-kms_key_access"]
}

## 16 Inline Policies 

data "template_file" "inline_client_config_s3_read" {
   template = file("./inline_policies/client_config_s3_read.tpl")
   vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_client_config_s3_read" {
  name   = "client_config_s3_read"
  role   = aws_iam_role.promo[0].name
  policy = "${data.template_file.inline_client_config_s3_read.rendered}"
  depends_on = ["aws_iam_role_policy_attachment.spark_create_tag"]
}

data "template_file" "inline_ec2_autoscaling_access_con" {
   template = file("./inline_policies/ec2_autoscaling_access_con.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_ec2_autoscaling_access_con" {
  name   = "ec2_autoscaling_access_con"
  role   = aws_iam_role.promo[0].name
  policy = "${data.template_file.inline_ec2_autoscaling_access_con.rendered}"
}

data "template_file" "inline_sql_db_backup_s3_write_data" {
   template = file("./inline_policies/sql_db_backup_s3_write.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_sql_db_backup_s3_write_data" {
  name   = "sql_db_backup_s3_write"
  role   = aws_iam_role.promo[1].name
  policy = "${data.template_file.inline_sql_db_backup_s3_write_data.rendered}"
}

data "template_file" "inline_appdata_s3_write_jenkins" {
   template = file("./inline_policies/appdata_s3_write.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_write_jenkins" {
  name   = "appdata_s3_write"
  role   = aws_iam_role.promo[3].name
  policy = "${data.template_file.inline_appdata_s3_write_jenkins.rendered}"
}

data "template_file" "inline_ec2_autoscaling_access_con_jenkins" {
   template = file("./inline_policies/ec2_autoscaling_access_con.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_ec2_autoscaling_access_con_jenkins" {
  name   = "ec2_autoscaling_access_con"
  role   = aws_iam_role.promo[3].name
  policy = "${data.template_file.inline_ec2_autoscaling_access_con_jenkins.rendered}"
}

data "template_file" "inline_appdata_s3_get_put_con_mgmt" {
   template = file("./inline_policies/appdata_s3_get_put_con.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_get_put_con_mgmt" {
  name   = "appdata_s3_get_put_con"
  role   = aws_iam_role.promo[4].name
  policy = "${data.template_file.inline_appdata_s3_get_put_con_mgmt.rendered}"
}

data "template_file" "inline_client_config_s3_write_mgmt" {
   template = file("./inline_policies/client_config_s3_write.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_client_config_s3_write_mgmt" {
  name   = "client_config_s3_write"
  role   = aws_iam_role.promo[4].name
  policy = "${data.template_file.inline_client_config_s3_write_mgmt.rendered}"
}

data "template_file" "inline_ec2_authorize_secgrps_mgmt" {
   template = file("./inline_policies/ec2_authorize_secgrps.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_ec2_authorize_secgrps_mgmt" {
  name   = "ec2_authorize_secgrps"
  role   = aws_iam_role.promo[4].name
  policy = "${data.template_file.inline_ec2_authorize_secgrps_mgmt.rendered}"
}

data "template_file" "inline_pg_db_backup_s3_write_mgmt" {
   template = file("./inline_policies/pg_db_backup_s3_write.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_pg_db_backup_s3_write_mgmt" {
  name   = "pg_db_backup_s3_write"
  role   = aws_iam_role.promo[4].name
  policy = "${data.template_file.inline_pg_db_backup_s3_write_mgmt.rendered}"
}

data "template_file" "inline_appdata_s3_list_bucket_promo" {
   template = file("./inline_policies/appdata_s3_list_bucket.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_list_bucket_promo" {
  name   = "appdata_s3_list_bucket"
  role   = aws_iam_role.promo[5].name
  policy = "${data.template_file.inline_appdata_s3_list_bucket_promo.rendered}"
}

data "template_file" "inline_appdata_s3_write_promo" {
   template = file("./inline_policies/appdata_s3_write.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_write_promo" {
  name   = "appdata_s3_write"
  role   = aws_iam_role.promo[5].name
  policy = "${data.template_file.inline_appdata_s3_write_promo.rendered}"
}

data "template_file" "inline_appdata_s3_list_bucket_pmgmt" {
   template = file("./inline_policies/appdata_s3_list_bucket.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_list_bucket_pmgmt" {
  name   = "appdata_s3_list_bucket"
  role   = aws_iam_role.promo[6].name
  policy = "${data.template_file.inline_appdata_s3_list_bucket_pmgmt.rendered}"
}

data "template_file" "inline_appdata_s3_write_delete_pmgmt" {
   template = file("./inline_policies/appdata_s3_write_delete.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_write_delete_pmgmt" {
  name   = "appdata_s3_write_delete"
  role   = aws_iam_role.promo[6].name
  policy = "${data.template_file.inline_appdata_s3_write_delete_pmgmt.rendered}"
}

data "template_file" "inline_appdata_s3_list_bucket_spark" {
   template = file("./inline_policies/appdata_s3_list_bucket.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_list_bucket_spark" {
  name   = "appdata_s3_list_bucket"
  role   = aws_iam_role.promo[8].name
  policy = "${data.template_file.inline_appdata_s3_list_bucket_spark.rendered}"
}

data "template_file" "inline_appdata_s3_write_delete_spark" {
   template = file("./inline_policies/appdata_s3_write_delete.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_appdata_s3_write_delete_spark" {
  name   = "appdata_s3_write_delete"
  role   = aws_iam_role.promo[8].name
  policy = "${data.template_file.inline_appdata_s3_write_delete_spark.rendered}"
}

data "template_file" "inline_dynamodb_read_write_spark" {
   template = file("./inline_policies/dynamodb_read_write_tenant.tpl")
  vars = {
    tenant_number = "${var.tenant_number}"
  }
}
resource "aws_iam_role_policy" "inline_dynamodb_read_write_spark" {
  name   = "dynamodb_read_write"
  role   = aws_iam_role.promo[8].name
  policy = "${data.template_file.inline_dynamodb_read_write_spark.rendered}"
}

