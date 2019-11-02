{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::ndm-ppv-backups",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "postgres_backup/ppv-con-tenant${tenant_number}/"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::ndm-ppv-backups/postgres_backup/ppv-con-tenant${tenant_number}/*"
        }
    ]
}