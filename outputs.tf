output "db_end_point" {
	value = "${aws_db_instance.wp_db.endpoint}"
}

output "instance_ips" {
	value = "${aws_instance.wp_web[0].public_ip}"
}

output "load_balancer_dns" {
	value = "${aws_elb.wp_lb.dns_name}"
}
