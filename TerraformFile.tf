provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "credentials"
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow Only HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "newInstance" {
  ami             = "ami-09d95fab7fff3776c"
  instance_type   = "t2.micro"
  key_name        = "testkey"
  security_groups = [aws_security_group.allow_http_ssh.name]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("testkey.pem")
    host        = aws_instance.newInstance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install git -y",
      "sudo yum install httpd -y",
      "sudo yum install php -y",
      "sudo systemctl start httpd"
    ]
  }
  tags = {
    name = "TerraformOS"
  }
}

resource "aws_ebs_volume" "newEBSVolume" {
  availability_zone = aws_instance.newInstance.availability_zone
  size              = 1

  tags = {
    Name = "Backup"
  }
}
resource "aws_volume_attachment" "ebs_attach" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.newEBSVolume.id
  instance_id  = aws_instance.newInstance.id
  force_detach = true
}

resource "null_resource" "ConnectionToInstance" {

  depends_on = [
    aws_volume_attachment.ebs_attach,
  ]


  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("testkey.pem")
    host        = aws_instance.newInstance.public_ip
  }

  provisioner "remote-exec" {

    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/cybergodayush/WebsiteBasic.git /var/www/html/"

    ]
  }
}
resource "aws_s3_bucket" "newbucket1" {
  bucket        = "newbucket11223322"
  acl           = "private"
  force_destroy = true

  provisioner "local-exec" {
    command = "git clone https://github.com/cybergodayush/WebsiteBasic.git git_image"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "echo Y | rmdir /S /Q git_image"
  }
}

resource "aws_s3_bucket_object" "image-upload" {
  bucket = aws_s3_bucket.newbucket1.bucket
  key    = "banner"
  source = "git_image/images/banner.jpg"
  acl    = "public-read"
}

locals {
  s3_origin_id = aws_s3_bucket.newbucket1.id
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.newbucket1.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "No comment"
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
