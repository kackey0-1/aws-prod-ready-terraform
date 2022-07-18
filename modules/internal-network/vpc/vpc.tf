variable "vpc_cidr" {}
variable "public_subnet_cidr_az_a_0" {}
variable "public_subnet_cidr_az_c_0" {}
variable "private_subnet_cidr_az_a_0" {}
variable "private_subnet_cidr_az_c_0" {}

#vpc
resource "aws_vpc" "hypo-driven" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "hypo-driven"
  }
}

#public subnet
resource "aws_subnet" "public_az_a_0" {
  cidr_block = var.public_subnet_cidr_az_a_0
  vpc_id = aws_vpc.hypo-driven.id
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "public_az_c_0" {
  cidr_block = var.public_subnet_cidr_az_c_0
  vpc_id = aws_vpc.hypo-driven.id
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

#internet gateway
resource "aws_internet_gateway" "hypo-driven" {
  vpc_id = aws_vpc.hypo-driven.id
}

#public routetable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hypo-driven.id
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.hypo-driven.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_az_a_0" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public_az_a_0.id
}

resource "aws_route_table_association" "public_az_c_0" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public_az_c_0.id
}

#private subnet
resource "aws_subnet" "private_az_a_0" {
  cidr_block = var.private_subnet_cidr_az_a_0
  vpc_id = aws_vpc.hypo-driven.id
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_az_c_0" {
  cidr_block = var.private_subnet_cidr_az_c_0
  vpc_id = aws_vpc.hypo-driven.id
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

#private routetable
resource "aws_route_table" "private_az_a_0" {
  vpc_id = aws_vpc.hypo-driven.id
}

resource "aws_route_table" "private_az_c_0" {
  vpc_id = aws_vpc.hypo-driven.id
}

resource "aws_route" "private_0" {
  route_table_id = aws_route_table.private_az_a_0.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id = aws_route_table.private_az_c_0.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  route_table_id = aws_route_table.private_az_a_0.id
  subnet_id = aws_subnet.private_az_a_0.id
}

resource "aws_route_table_association" "private_1" {
  route_table_id = aws_route_table.private_az_c_0.id
  subnet_id = aws_subnet.private_az_c_0.id
}

#eip
resource "aws_eip" "nat_gateway_0" {
  vpc = true
  depends_on = [aws_internet_gateway.hypo-driven]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true
  depends_on = [aws_internet_gateway.hypo-driven]
}

#natgateway
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id = aws_subnet.public_az_a_0.id
  depends_on = [aws_internet_gateway.hypo-driven]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_az_c_0.id
  depends_on = [aws_internet_gateway.hypo-driven]
}

output "vpc_id" {
  value = aws_vpc.hypo-driven.id
}

output "public_subnet_ids" {
  value = {
    public_subnet_0 = aws_subnet.public_az_a_0.id
    public_subnet_1 = aws_subnet.public_az_c_0.id
  }
}

output "private_subnet_ids" {
  value = {
    private_subnet_0 = aws_subnet.private_az_a_0.id
    private_subnet_1 = aws_subnet.private_az_c_0.id
  }
}

output "vpc_cidr" {
  value = aws_vpc.hypo-driven.cidr_block
}