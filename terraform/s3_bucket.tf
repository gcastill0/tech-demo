/**** **** **** **** **** **** **** **** **** **** **** ****
Make sure all objects are private. This provides an S3 bucket.
**** **** **** **** **** **** **** **** **** **** **** ****/
resource "aws_s3_bucket" "pg_backup" {
  bucket        = "${var.prefix}-pg-backup-${random_id.secret_postfix.hex}"
  tags          = merge({ "Name" = "${var.prefix}" }, var.tags)
  force_destroy = true
}

# Make sure all objects are public, Demo only - you can lock this down if you like
resource "aws_s3_bucket" "mirror" {
  bucket = "${var.prefix}-app-data-${random_id.secret_postfix.hex}"
  tags   = merge({ "Name" = "${var.prefix}" }, var.tags)
}

# Set ACL to public
resource "aws_s3_bucket_acl" "mirror" {
  bucket = aws_s3_bucket.mirror.id
  acl    = "public-read"
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.mirror.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "mirror" {
  bucket                  = aws_s3_bucket.mirror.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

locals {
  mirror_directory = "./app-data"
}

# Loop through the mirror directory and upload it as-is to the bucket
resource "aws_s3_object" "mirror_objects" {
  depends_on = [aws_s3_bucket_public_access_block.mirror]
  for_each   = fileset(local.mirror_directory, "**")

  bucket        = aws_s3_bucket.mirror.id
  key           = each.key
  source        = format("%s/%s", local.mirror_directory, each.value)
  force_destroy = true
  acl           = "public-read"

  # Hacky way to check for .json to set content type (JSON files MUST have this set)
  content_type = replace(each.value, ".json", "") != each.value ? "application/json" : ""

  # Set etag to pick up changes to files
  etag = filemd5(format("%s/%s", local.mirror_directory, each.value))
}

# Attach an S3 access policy to the role
resource "aws_iam_policy" "s3_backup_policy" {
  name        = "PGBackupPolicy"
  description = "Policy to allow EC2 to read/write to S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.pg_backup.arn,
          "${aws_s3_bucket.pg_backup.arn}/*"
        ]
      }
    ]
  })
}

# Attach the S3 policy to the EC2 role
resource "aws_iam_role_policy_attachment" "attach_s3_backup_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_backup_policy.arn
}

