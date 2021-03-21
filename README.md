# Test task

## Requirements

Your aws user should have enough permissions for AWS services (S3, EC2, ELB, VPC) you need policies:

- AmazonS3FullAccess
- AmazonEC2FullAccess
- ElasticLoadBalancingFullAccess 
- AmazonVPCFullAccess

## Usage

Before running script you need export your own credential variables in some way e.g.

```sh
$ export AWS_ACCESS_KEY_ID=<YourKeyID>
$ export AWS_SECRET_ACCESS_KEY=<YourSecretAccessKey>
```

For creating a state storage use scripts in directory `state_file`.

It creates only S3 bucket for terraform state files. It doesn't creates DB for locks.

```sh
$ cd test_task/state_file
$ terraform init
$ terraform plan -var="state_region=<your region for S3>" -var="state_bucket=<your unique bucket name>"
$ terraform apply -var="state_region=<your region for S3>" -var="state_bucket=<your unique bucket name>"
```

In outputs you'll get:

```
state_bucket = "your unique bucket name"
state_region = "your region for S3"
```

Before running `test_task/web_service` you should change `bucket` and `region` in `terraform` block in `test_task/web_service/main.tf` file:

```json
terraform {
  backend "s3" {
    bucket  = "your unique bucket name" # unique bucket name from state_bucket
    key     = "terraform/terraform.tfstate"
    region  = "your region for S3" # region for state from state_region
    encrypt = true
  }
}
...
```

Use scripts in `web_service` folder for provisioning nginx web service in docker container in EC2.

```sh
$ cd test_task/web_service
$ terraform init
$ terraform plan
$ terraform apply
```

All variables are defined in test_task/web_service/variables.tf file and have default values. They can be redefined.

List of variables and types in "Variables" section of document.

After complete provisioning you'll get output lb-dns-name = "load_balancer_DNS_name"

Use URL http://<load_balancer_DNS_name> for checking.

##### NOTE: Sometimes EC2 instance needs long time for initialization. You should wait until it's finished. 

## Variables

| Variable             | Description                                                  | Type         |
| -------------------- | ------------------------------------------------------------ | ------------ |
| region               | Region for test infrastructure                               | string       |
| proj_azs             | Availability zones list. We need at least 2 availability zones for LB. | list(string) |
| proj_name            | Unique project name that uses in all service names and tags. | string       |
| proj_cidr            | CIDR for VPC.                                                | string       |
| proj_private_subnets | Used in VPC module for private subnets. We need 1 subnet.    | list(string) |
| proj_public_subnets  | Used in VPC module for public subnetes. We need at least 2 because LB. | list(string) |
