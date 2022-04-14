output "web"{
    value = aws_security_group.web_traffic.id
}

output "kubernetes"{
    value = aws_security_group.kubernetes.id
}

output "ssh"{
    value = aws_security_group.ssh.id
}

output "outbound_traffic"{
    value = aws_security_group.outbound_traffic.id
}