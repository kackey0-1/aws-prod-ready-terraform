variable "vpc_cidr" {}
variable "pub_subnet_cidr_0" {}
variable "pub_subnet_cidr_1" {}
variable "pri_subnet_cidr_0" {}
variable "pri_subnet_cidr_1" {}

#vpc
resource "aws_vpc" "example" {
  #cidr_block = "10.0.0.0/16"
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "example"
  }
}

#public subnet
resource "aws_subnet" "public_0" {
  #cidr_block = "10.0.1.0/24"
  cidr_block = var.pub_subnet_cidr_0
  vpc_id = aws_vpc.example.id
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "public_1" {
  #cidr_block = "10.0.2.0/24"
  cidr_block = var.pub_subnet_cidr_1
  vpc_id = aws_vpc.example.id
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

#internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

#public routetable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_0" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public_0.id
}

resource "aws_route_table_association" "public_1" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public_1.id
}

#private subnet
resource "aws_subnet" "private_0" {
  #cidr_block = "10.0.65.0/24"
  cidr_block = var.pri_subnet_cidr_0
  vpc_id = aws_vpc.example.id
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  #cidr_block = "10.0.66.0/24"
  cidr_block = var.pri_subnet_cidr_1
  vpc_id = aws_vpc.example.id
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

#private routetable
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route" "private_0" {
  route_table_id = aws_route_table.private_0.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id = aws_route_table.private_1.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  route_table_id = aws_route_table.private_0.id
  subnet_id = aws_subnet.private_0.id
}

resource "aws_route_table_association" "private_1" {
  route_table_id = aws_route_table.private_1.id
  subnet_id = aws_subnet.private_1.id
}

#eip
resource "aws_eip" "nat_gateway_0" {
  vpc = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true
  depends_on = [aws_internet_gateway.example]
}

#natgateway
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id = aws_subnet.public_0.id
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_1.id
  depends_on = [aws_internet_gateway.example]
}

output "vpc_id" {
  value = aws_vpc.example.id
}

output "subnet_ids" {
  value = {
    pub_subnet_0 = aws_subnet.public_0.id
    pub_subnet_1 = aws_subnet.public_1.id
    pri_subnet_0 = aws_subnet.private_0.id
    pri_subnet_1 = aws_subnet.private_1.id
  }
}