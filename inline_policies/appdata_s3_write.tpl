{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::ndm-ppv-appdata/ppv-con-tenant${tenant_number}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::ndm-ppv-appdata",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "ppv-con-tenant${tenant_number}/promo/*"
                }
            }
        }
    ]
}