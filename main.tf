provider "aws" {
  access_key = "${var.ACCESS_KEY}"
  secret_key = "${var.SECRET_KEY}"
  region     = "eu-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "kubes-box" {
  # ami           = "ami-941e04f0"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  count         = "2"

  vpc_security_group_ids = "${var.security_group_ids}"

  root_block_device = {
    delete_on_termination = true
    volume_size           = 10
  }

  tags {
    Name = "kubes-box-${count.index}"
  }
}

# resource "aws_ebs_volume" "ian-storage" {
#   availability_zone = "us-west-2a"
#   size              = 10
# }

# resource "aws_volume_attachment" "ebs_att" {
#   device_name = "/dev/sdh"
#   volume_id   = "${aws_ebs_volume.ian-storage.id}"
#   instance_id = "${aws_instance.ian-box.id}"
# }

output "ip" {
  value = ["${aws_instance.kubes-box.*.public_ip}"]
}
