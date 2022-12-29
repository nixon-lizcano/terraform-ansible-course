output "jenkins-main-node-public-ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins-worker-node-public-ip" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}

output "LB-DNS-NAME" {
  value = aws_lb.application_lb.dns_name
}