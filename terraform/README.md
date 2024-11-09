# Deploy a test EC2 Instance

This Terraform code deploys an EC2 instance of `ubuntu` and uses a bootstrap switch to install an instance of Postgres. In this scenario, we also deploy an EKS instance with one node that is ready to accept deployments.

## Terraform requirements
### Declare your AWS access credentials
Provide Cloud Identity credentials. Depending on your identification requirements, you will need `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` at a bare minimum.
```bash
export AWS_ACCESS_KEY_ID="ABCDE013FGHIJKLM4NOP"
export AWS_SECRET_ACCESS_KEY="01aBC3De23FgHiJkLM4nop5QrSTUvWxY67ZAB8c9"
```
If you do not declare your Cloud Identity credentials, you will receive a message as follows:
```bash
╷
│ Error: No valid credential sources found
│ 
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on main.tf line 10, in provider "aws":
│   10: provider "aws" {
│ 
│ Please see https://registry.terraform.io/providers/hashicorp/aws
│ for more information about providing credentials.
│ 
│ Error: failed to refresh cached credentials, no EC2 IMDS role found, operation error ec2imds:
│ GetMetadata, request canceled, context deadline exceeded
│ 
```

### Run Terraform commands
```bash
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding latest version of hashicorp/tls...

  ...
  ...

Terraform has been successfully initialized!
```

```bash
terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform planned the following actions, but then encountered a problem:

  # null_resource.main will be created
  + resource "null_resource" "main" {
      + id = (known after apply)
    }

  # tls_private_key.main will be created
  + resource "tls_private_key" "main" {
      + algorithm                     = "RSA"
      + ecdsa_curve                   = "P224"
      + id                            = (known after apply)
      + private_key_openssh           = (sensitive value)
      + private_key_pem               = (sensitive value)
      + private_key_pem_pkcs8         = (sensitive value)

...
...

Changes to Outputs:
  + instance_public_ip = (known after apply)
  + public_ip          = (known after apply)
  + ssh_access         = (sensitive value)

────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly
these actions if you run "terraform apply" now.
```

```bash
terraform apply -auto-approve
data.aws_ami.ubuntu: Reading...
data.aws_ami.ubuntu: Read complete after 1s [id=ami-01abc1d2efg3hi45j]

...
...

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

ssh_access = "ssh -i tech-ng-ssh-key.pem ubuntu@111.22.3.44"
```

## Accessing your instance

```bash
ssh -i tech-ng-ssh-key.pem ubuntu@111.22.3.44

The authenticity of host '111.22.3.44 (111.22.3.44)' can't be established.
AB12345 key fingerprint is SHA256:AB0abcdefghiCkDEl9m2FGHAnopIqrsJtKuLvMNOPQR.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```
```bash
Warning: Permanently added '111.22.3.44' (AB12345) to the list of known hosts.
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.15.0-1070-aws x86_64)

...
...

ubuntu@ip-10-0-2-242:~$ 
```