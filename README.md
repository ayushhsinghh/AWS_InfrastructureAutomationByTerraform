#WebserverAutomationByTerraform

#My Aim for This Project :
To Create an Infrastructure as Code to Start an AWS instance and Run apache server. Allow access to HTTP and SSH. The Images of Website should be stored in AWS S3 bucket with AWS CloudFront and The Files of Website should be Shored in Another EBS Storage that works as Backup. All with Terraform.

#Context
1.Add Provider to Terraform
2.Add Keys And Security Group that allow HTTP and SSH
3.To Create Instance In EC2 and install Required Software in it. i.e. httpd, git, PHP
4.To Create an EBS Storage as Backup and Mount it to /var/www/html
5.Create an S3 Bucket and store the Images
6.Make a CloudFront URL for that Images

For Complete Article Visit Here : https://www.linkedin.com/pulse/aws-infrastructure-automation-terraform-ayush-kumar-singh
