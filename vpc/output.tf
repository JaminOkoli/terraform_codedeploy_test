output "vpc_id" {
  value = aws_vpc.Drohealth_vpc.id
}

output "vpc_public_subnets" {
  value = aws_subnet.DroHealth_subnet.*.id  
}