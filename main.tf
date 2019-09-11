provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "vpc" {
  tags {
    Name = "${var.vpc_name}"
  }
}

locals = {
  num_data_tags       = "${length(keys(var.data_access_security_group_tags))}"
  num_webapp_tags     = "${length(keys(var.webapp_access_security_group_tags))}"
  num_management_tags = "${length(keys(var.management_security_group_tags))}"
}

data "aws_security_groups" "source_data_access" {
  count = "${local.num_data_tags > 0 ? 1 : 0}" 
  tags  = "${merge(var.data_access_security_group_tags,map("Env", "${var.project_env}"))}"

  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc.id}"]
  }
}

locals = {
  source_data_access_ids   = "${flatten(coalescelist(data.aws_security_groups.source_data_access.*.ids,list()))}"
  source_data_access_names = "${flatten(coalescelist(data.aws_security_group.source_data_access.*.name,list()))}"
}

data "aws_security_group" "source_data_access" {
  count = "${local.num_data_tags > 0 ? length(local.source_data_access_ids) : 0}"
  id    = "${element(local.source_data_access_ids,count.index)}"
}

data "aws_security_groups" "source_webapp_access" {
  count = "${local.num_webapp_tags > 0 ? 1 : 0}" 
  tags  = "${merge(var.webapp_access_security_group_tags,map("Env", "${var.project_env}"))}"

  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.vpc.id}"]
  }
}

locals = {
  source_webapp_access_ids   = "${flatten(coalescelist(data.aws_security_groups.source_webapp_access.*.ids,list()))}"
  source_webapp_access_names = "${flatten(coalescelist(data.aws_security_group.source_webapp_access.*.name,list()))}"
}

data "aws_security_group" "source_webapp_access" {
  count = "${local.num_data_tags > 0 ? length(local.source_webapp_access_ids) : 0}"
  id    = "${element(local.source_webapp_access_ids,count.index)}"
}

data "aws_security_group" "source_management" {
  count  = "${local.num_management_tags > 0 ? 1 : 0}" 
  tags   = "${merge(var.management_security_group_tags,map("Env", "${var.project_env}"))}"
  vpc_id = "${data.aws_vpc.vpc.id}"
}

resource "null_resource" "ingress_with_source_sgs_data_access" {
  count = "${length(local.source_data_access_ids)}"

  triggers {
    rule                     = "${var.data_port}"
    description              = "${element(local.source_data_access_names, count.index)}"
    source_security_group_id = "${element(local.source_data_access_ids, count.index)}"
  }
}

resource "null_resource" "ingress_with_source_sg_management" {
  count = "${local.num_management_tags > 0 ? length(var.management_rules) : 0}"

  triggers {
    rule                     = "${var.management_rules[count.index]}"
    description              = "${data.aws_security_group.source_management.name} - ${element(var.rules[var.management_rules[count.index]], 3)}"
    source_security_group_id = "${data.aws_security_group.source_management.id}"
  }
}

resource "null_resource" "ingress_with_source_sgs_webapp_access" {
  count = "${length(local.source_webapp_access_ids)}"

  triggers {
    rule                     = "${var.webapp_port}"
    description              = "${element(local.source_webapp_access_names, count.index)}"
    source_security_group_id = "${element(local.source_webapp_access_ids, count.index)}"
  }
}

locals {
  name = "${var.namespace == "" ? "" : "${var.namespace}-"}${lower(var.project_env_short)}-${lower(var.name)}"
  ingress_with_source_security_group_ids = "${concat(null_resource.ingress_with_source_sgs_data_access.*.triggers,null_resource.ingress_with_source_sg_management.*.triggers,null_resource.ingress_with_source_sgs_webapp_access.*.triggers)}"
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.17.0"

  use_name_prefix = false
  name            = "${local.name}"
  description     = "${var.description}"
  vpc_id          = "${data.aws_vpc.vpc.id}"

  rules                         = "${var.rules}"
  ingress_with_self             = "${var.ingress_with_self}"

  ingress_rules                 = "${var.ingress_rules}"
  ingress_cidr_blocks           = "${var.ingress_cidr_blocks}"
  ingress_ipv6_cidr_blocks      = "${var.ingress_ipv6_cidr_blocks}"

  ingress_with_cidr_blocks      = "${var.ingress_with_cidr_blocks}"
  ingress_with_ipv6_cidr_blocks = "${var.ingress_with_ipv6_cidr_blocks}"

  ingress_with_source_security_group_id = "${local.ingress_with_source_security_group_ids}"

  egress_cidr_blocks            = "${var.egress_cidr_blocks}"
  egress_ipv6_cidr_blocks       = "${var.egress_ipv6_cidr_blocks}"
  egress_rules                  = "${var.egress_rules}"
  egress_with_cidr_blocks       = "${var.egress_with_cidr_blocks}"
  egress_with_ipv6_cidr_blocks  = "${var.egress_with_ipv6_cidr_blocks}"

  tags = "${merge(var.tags, map("Env", "${var.project_env}", "namespace", "${var.namespace}"))}"
}
