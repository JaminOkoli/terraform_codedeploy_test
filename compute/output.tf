output "ip_address" {
  value = "${aws_instance.test_EHR_EC2.public_ip}:3000"
}