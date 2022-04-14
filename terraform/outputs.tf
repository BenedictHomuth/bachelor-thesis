output "load_balancer_name"{
  value = module.elb.elb_dns_name
}

output "ip_control_plane"{
  value = module.control_plane_k3s.ip
}