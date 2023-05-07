# creating the vpc

resource "aws_vpc" "dev-app" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.envname
  }
}

# create subnets

# Creating the publicsubnet

resource "aws_subnet" "pubsubnet" {
  count = length(var.azs)
  vpc_id     = aws_vpc.petclinic.id
  cidr_block = element(var.pubsubnet,count.index)
  availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.envname}-pubsubnet-${count.index+1}"
  }
}


# createing the appsubnets

resource "aws_subnet" "privatesubnet" {
  count = length(var.azs)
  vpc_id     = aws_vpc.petclinic.id
  cidr_block = element(var.privatesubnet,count.index)
  availability_zone = element(var.azs,count.index)
  

  tags = {
    Name = "${var.envname}-privatesub-${count.index+1}"
  }
}


# createing the datasubnets

resource "aws_subnet" "datasubnet" {
  count = length(var.azs)
  vpc_id     = aws_vpc.petclinic.id
  cidr_block = element(var.datasubnet,count.index)
  availability_zone = element(var.azs,count.index)
  

  tags = {
    Name = "${var.envname}-datasubnet-${count.index+1}"
  }
}


# createing the internet gateway


resource "aws_internet_gateway" "dev-ig" {
  vpc_id = aws_vpc.petclinic.id

  tags = {
    Name = "${var.envname}-igw"
  }
}


# Nategatwy elasticIP

resource "aws_eip" "natip" {
  vpc      = true

   tags = {
    Name = "${var.envname}-Elaip"
   }
}


# create natgateway in public subnet attach associated  elasticIP

resource "aws_nat_gateway" "Nategatway" {
  allocation_id = aws_eip.natip.id
  subnet_id     = aws_subnet.pubsubnet[0].id

  tags = {
    Name = "${var.envname}-Natgw" 
  }
}


#  public Route Table
resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.petclinic.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-ig.id
  }
  
   tags = {
    Name = "${var.envname}-public_route"
  }
}


#Private route Table

resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.petclinic.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id =aws_nat_gateway.Nategatway.id
  }
  
   tags = {
    Name = "${var.envname}-private_route"
  }
}


# Data route table


resource "aws_route_table" "dataroute" {
  vpc_id = aws_vpc.petclinic.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id =aws_nat_gateway.Nategatway.id
  }
  
   tags = {
    Name = "${var.envname}-data_route"
  }
}



# route table association


resource "aws_route_table_association" "pubsubassociation" {
  count = length(var.pubsubnet)
  subnet_id      =element(aws_subnet.pubsubnet.*.id, count.index)
  route_table_id = aws_route_table.publicroute.id
}

resource "aws_route_table_association" "privatesubassociation" {
  count = length(var.privatesubnet)
  subnet_id      =element(aws_subnet.privatesubnet.*.id, count.index)
  route_table_id = aws_route_table.privateroute.id
}

resource "aws_route_table_association" "datasubassociation" {
  count = length(var.datasubnet)
  subnet_id      =element(aws_subnet.datasubnet.*.id, count.index)
  route_table_id = aws_route_table.dataroute.id
}
