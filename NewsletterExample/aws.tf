provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "test" {
  cidr_block = "${var.network_address_space}"

  tags = {
    Name = "${var.azure_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = "${aws_vpc.test.id}"

  tags = {
    Name = "${var.azure_prefix}-ig"
  }
}

resource "aws_subnet" "test1" {
  cidr_block        = "${var.subnet1_address_space}"
  vpc_id            = "${aws_vpc.test.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "${var.azure_prefix}-subnet1"
  }
}

resource "aws_subnet" "test2" {
  cidr_block        = "${var.subnet2_address_space}"
  vpc_id            = "${aws_vpc.test.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "${var.azure_prefix}-subnet2"
  }
}

resource "aws_route_table" "test" {
  vpc_id = "${aws_vpc.test.id}"
}

resource "aws_route_table_association" "test1" {
  subnet_id      = "${aws_subnet.test1.id}"
  route_table_id = "${aws_route_table.test.id}"
}

resource "aws_route_table_association" "test2" {
  subnet_id      = "${aws_subnet.test2.id}"
  route_table_id = "${aws_route_table.test.id}"
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.test1.id}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }

  tags = {
    Name = "${var.azure_prefix}-client1"
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

output "aws_public_ip" {
  value = "${aws_eip.ip.public_ip}"
}
