variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "namespace" { default = "" }
variable "name" { default = "security-group" }
variable "customized_name" { default = "" }
variable "description" { default = "This is a security group" }
variable "vpc_name" { default = "default" }

variable "data_access_security_group_tags" { default = {} }
variable "data_port" { default = "mysql-tcp" }
variable "webapp_access_security_group_tags" { default = {} }
variable "webapp_port" { default = "http-80-tcp" }
variable "management_security_group_tags" { default = {} }
variable "management_rules" { default = ["ssh-tcp"] }

variable "ingress_rules" { default = [] }
variable "ingress_cidr_blocks" { default = [] }
variable "ingress_ipv6_cidr_blocks" { default = [] }
variable "ingress_with_cidr_blocks" { default = [] }
variable "ingress_with_ipv6_cidr_blocks" { default = [] }
variable "ingress_with_self" { 
default = [
  {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "-1"
    description = "Itself"
  }
  ]
}

variable "egress_cidr_blocks" { default = ["0.0.0.0/0"] }
variable "egress_ipv6_cidr_blocks" { default = ["::/0"] }
variable "egress_rules" { default = ["all-all"] }
variable "egress_with_cidr_blocks" { default = [] }
variable "egress_with_ipv6_cidr_blocks" { default = [] }

variable "tags" {
  default = {}
}
