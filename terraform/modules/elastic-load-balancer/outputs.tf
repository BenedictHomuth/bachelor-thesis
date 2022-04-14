output "loadbalancer_id" {
  value =  aws_elb.loadbalancer.id
}

output "elb_dns_name" {
  value = aws_elb.loadbalancer.dns_name
}
