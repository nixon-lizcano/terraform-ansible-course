# Create and bootstrap EC2 in master
resource "aws_instance" "jenkins_master" {
  provider                    = aws.region_master
  ami                         = data.aws_ssm_parameter.linux_AMI_master.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key_master.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.subnets_master[0].id

  tags = {
    Name = "jenkins_master_tf"
  }

  depends_on = [
    aws_main_route_table_association.set_master_default_rt_assoc
  ]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_master} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ./../ansible/jenkins-master.yml
EOF
  }
}

# Create EC2 in worker
resource "aws_instance" "jenkins_worker" {
  provider                    = aws.region_worker
  count                       = var.worker_count
  ami                         = data.aws_ssm_parameter.linux_AMI_worker.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key_worker.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_oregon.id]
  subnet_id                   = aws_subnet.subnet_worker.id

  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }

  depends_on = [
    aws_main_route_table_association.set_worker_default_rt_assoc,
    aws_instance.jenkins_master
  ]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_worker} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ./../ansible/jenkins-worker.yml
EOF
  }
}