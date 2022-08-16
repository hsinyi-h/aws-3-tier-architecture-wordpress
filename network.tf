#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------

resource "aws_internet_gateway" "igw"{
  vpc_id			= aws_vpc.vpc.id
  
  tags = {
	Name = "wordpress igw"
  }
}

#--------------------------------------------------------------
# NAT
#--------------------------------------------------------------

resource "aws_eip" "nat-eip"{
  count		= length(var.pub_cidr)
  depends_on	= [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "natgw"{
  count		= length(var.pub_cidr)

  allocation_id = element(aws_eip.nat-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public-subnet.*.id, count.index)
  depends_on	= [aws_internet_gateway.igw]

}

#--------------------------------------------------------------
# Public subnet
#--------------------------------------------------------------

resource "aws_subnet" "public-subnet"{
  count = length(var.pub_cidr)

  vpc_id			= aws_vpc.vpc.id
  cidr_block   			= element(var.pub_cidr, count.index)
  availability_zone		= element(var.azs, count.index)
  map_public_ip_on_launch	= true

}

resource "aws_route_table" "pub-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {                 
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
  }
}

resource "aws_route_table_association" "pub-rtb-as" {
  count = length(var.pub_cidr)
  
  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id = aws_route_table.pub-rtb.id
} 

#--------------------------------------------------------------
# Private subnet
#--------------------------------------------------------------

resource "aws_subnet" "lightsail-subnet"{
  count = length(var.lightsail_cidr)

  vpc_id			= aws_vpc.vpc.id
  cidr_block			= element(var.lightsail_cidr, count.index)
  availability_zone		= element(var.azs, count.index)
  map_public_ip_on_launch	= false
}

resource "aws_subnet" "db-subnet"{
  count = length(var.db_cidr)

  vpc_id			= aws_vpc.vpc.id
  cidr_block			= element(var.db_cidr, count.index)
  availability_zone		= element(var.azs, count.index)
  map_public_ip_on_launch	= false
}

resource "aws_route_table" "pri-rtb" {
  count = length(var.lightsail_cidr)

  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.natgw.*.id, count.index)
  }
}

resource "aws_route_table_association" "pri-lightsail-rtb-as" {
  count = length(var.lightsail_cidr)

  subnet_id      = element(aws_subnet.lightsail-subnet.*.id, count.index)
  route_table_id = element(aws_route_table.pri-rtb.*.id, count.index)
}

resource "aws_route_table_association" "pri-db-rtb-as" {
  count = length(var.db_cidr)

  subnet_id      = element(aws_subnet.db-subnet.*.id, count.index)
  route_table_id = element(aws_route_table.pri-rtb.*.id, count.index)
}

