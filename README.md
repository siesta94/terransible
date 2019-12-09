# Terraform and Ansible HA WP provisioner for AWS
Prerequisites:
Terraform & Ansible (terraform version 0.11 or 0.12 - which will report some warning error because syntax changed):

* `git clone https://github.com/siesta94/terransible` - Clone this repo.
* `cd terransible` - Change directory to terransible.
* Create terraform.tfvars file, which is used to pass parametars to variables.tf (check terraform.tfvars_sample)
* `terraform init` - Initialize terraform (download required drivers).
* `terraform validate` - Check syntax.
* `terraform plan -out example` - Create terraform example plan.
* `terraform apply example` - Apply terraform "example" plan generated in above step.

After terraform apply is finished successfully you will have to edit aws_hosts file. Delete IP addresses of servers and add one that is outputed by terraform (also safe all outputs): `instance_ips = 54.91.163.197` (example). Then you can run wpinsta.yml that is used for installing wordpress with ansible: `ansible-playbook -i aws_hosts wpinsta.yml`.

Now we can open browser and navigate to load balancer (load_balancer_dns from terraform output): `load_balancer_dns = wp-lb-206979940.us-east-1.elb.amazonaws.com` (example) and start installing wordpress. Database credentials are provided in terraform.tfvars file and RDS endpoint is in terraform output: `db_end_point = terraform-20191209152043694100000001.colzzv0sjeg0.us-east-1.rds.amazonaws.com:3306` (example).

Infrastructure:
* VPC with 6 subnets - 2x public subnets 2x private subnets 3x rds subnets that are part of rds_subnet_group. Internet gateway and 4 route tables.
* Infrastructure is consistent of load_balancer that forwards traffic to 2 (by default) web servers on port 80.
* 2 (by default) web servers that are part of same VPC.
* RDS mysql5.7.22 with 10G allocated storage.
* 3 security groups:
    * Allow_public_traffic (public_sg) - Allows traffic on port 80 and port 22 from all ips (0.0.0.0/0). This should be changed for port 22 only for your IP address.
    * wp_rds_sg - Allows port 3306 from public_sg.
    * Allow_EFS (wp_efs_security_grp) - Allows traffic on port 2049 from public_sg.
* EFS Storage which is mounted on instances under /var/www/html/.
