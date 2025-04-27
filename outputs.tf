output "myapp-server-ip" {
  value = module.myapp-server.ec2-instance.public_ip
}
