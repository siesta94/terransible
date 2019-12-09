provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

### Create VPC ###
resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wp_vpc"
  }
}

### Create IG (internet gateway) ###
resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags = {
    Name = "wp_igw"
  }
}

### Create route tables ###
resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"
  }

  tags = {
    Name = "wp_public_rt"
  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"

  tags = {
    Name = "wp_private_rt"
  }
}

### Create subnets ###
resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_private2"
  }
}

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "wp_rds1"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_rds2"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_rds3"
  }
}

### RDS Subnet Group ###

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name = "wp_rds_subnetgrou"

  subnet_ids = ["${aws_subnet.wp_rds1_subnet.id}", "${aws_subnet.wp_rds2_subnet.id}", "${aws_subnet.wp_rds3_subnet.id}"]

  tags = {
    Name = "wp_rds_sng"
  }
}

### Assosiate subnets to RT ###

resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = "${aws_subnet.wp_public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = "${aws_subnet.wp_public2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_private1_assoc" {
  subnet_id      = "${aws_subnet.wp_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}

resource "aws_route_table_association" "wp_private2_assoc" {
  subnet_id      = "${aws_subnet.wp_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}


### Security Groups ###

resource "aws_security_group" "public_sg"{
  name   = "Allow_public_traffic"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  ingress{
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "wp_rds_sg" {
	name = "wp_rds_sg"
        vpc_id = "${aws_vpc.wp_vpc.id}"
	
	ingress {
	  from_port = 3306
          to_port = 3306
          protocol = "tcp"
	  
          security_groups = ["${aws_security_group.public_sg.id}"]
	}
}

resource "aws_security_group" "wp_efs_security_grp" {
        name = "Allow_EFS"
        vpc_id = "${aws_vpc.wp_vpc.id}"

        ingress {
          security_groups = ["${aws_security_group.public_sg.id}"]
          from_port = 2049
          to_port = 2049
          protocol = "tcp"
        }

        egress {
          security_groups = ["${aws_security_group.public_sg.id}"]
          from_port = 0
          to_port = 0
          protocol = "-1"
        }
}

### EFS Create ###

resource "aws_efs_file_system" "wp_efs" {
       creation_token = "wp-efs-token"
       performance_mode = "generalPurpose"
       throughput_mode = "bursting"
       encrypted = "true"

       tags = {
         Name = "EFS"
       }
}

resource "aws_efs_mount_target" "wp_efs_mt" {
       file_system_id = "${aws_efs_file_system.wp_efs.id}"
       subnet_id = "${aws_subnet.wp_public1_subnet.id}"
       security_groups = ["${aws_security_group.wp_efs_security_grp.id}"]
}

data "template_file" "script" {
  template = "${file("script.tpl")}"
  vars = {
    efs_id = "${aws_efs_file_system.wp_efs.id}"
  }
}

### COMPUTE ###

resource "aws_key_pair" "my_key"{
	key_name = "wp_key"
	public_key = "${var.wp_key}"
}

resource "aws_instance" "wp_web"{
	count = "${var.instance_count}"
	ami           = "${var.wp_image}"
	instance_type = "${var.ec-2_type}"
	key_name = "wp_key"
	user_data = "${data.template_file.script.rendered}"

	tags = {
	  Name = "Wordpress_web_server-${count.index + 1}"
	}
	
	vpc_security_group_ids = ["${aws_security_group.public_sg.id}"]
	subnet_id	       = "${aws_subnet.wp_public1_subnet.id}"

	provisioner "local-exec" {
          command = <<EOD
cat <<EOF >> aws_hosts  
"${self.public_ip}"
EOF
EOD
	}	

	provisioner "local-exec" {
          command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --profile basic && ansible-playbook -i aws_hosts httpd.yml"
  }
#	provisioner "local-exec" {
#	  command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --profile basic && ansible-playbook -i aws_hosts wpinsta.yml"
#  } 
}

#resource "aws_db_instance" "wp_db" {
#	allocated_storage = 10
#	engine = "mysql"
#        engine_version = "5.7.22"
#        instance_class = "${var.db_instance_class}"
#	name           = "${var.dbname}"
#        username       = "${var.dbuser}"
#        password       = "${var.dbpassword}"
#        db_subnet_group_name = "${aws_db_subnet_group.wp_rds_subnetgroup.name}"
#        vpc_security_group_ids = ["${aws_security_group.wp_rds_sg.id}"]
#	skip_final_snapshot = true
#}

resource "aws_elb" "wp_lb" {
  name               = "wp-lb"
  subnets = ["${aws_subnet.wp_public1_subnet.id}", "${aws_subnet.wp_public2_subnet.id}"]
  security_groups = ["${aws_security_group.public_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = ["${aws_instance.wp_web[0].id}", "${aws_instance.wp_web[1].id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "wp-lb"
  }
}

