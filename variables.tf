
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "ami_id" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "availability_zone" {}
variable "name" {
  type = string
}
variable "environment" {
  type = string
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "vpc_name" {
  type = string
}
variable "instance_count" {
  default = 2
}
variable "sub_az" {
  type    = string
  default = "us-east-1a"
}
variable "sub_auto_ip" {
  description = "Set Automatic IP Assigment for Variables Subnet"
  type        = bool
  default     = true
}
variable "gateway_name" {
  default = "stg-internet-gateway"
}
variable "nat_gateway_name" {
  default = "stg-nat-gateway"
}
variable "nat_gateway_eip_name" {
  
}
variable "public_route_table_name" {

}
variable "private_route_table_name" {

}
variable "private_subnet" {
  default = {
    /*
      add more subnets 
      "subnet-name" - number
    */
    "private-subnet-1" = 1
  }
}
variable "public_subnet" {
  default = {
    /*
      add more subnets 
      "subnet-name" - number
    */

    "public-subnet-1" = 1
    "public-subnet-2" = 2
  }
}

