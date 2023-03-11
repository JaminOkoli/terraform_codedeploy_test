output "Application_Address" {
  value = "http://${aws_lb.test-EHR-lb.dns_name}"
}
