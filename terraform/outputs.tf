output "load_balancer_worker_asg"{
  value = module.worker-asg-pool-with-loadbalancer.elb_dns_name
}

output "ip_control_plane"{
  value = module.control_plane_k3s.ip
}