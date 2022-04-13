resource "aws_instance" "ec2_control_plane" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = var.vpc_sg_ids
  user_data              = var.user_data

  tags = {
    Name = var.instance_name
  }
}
