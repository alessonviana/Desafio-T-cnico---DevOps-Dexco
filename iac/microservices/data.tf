data "aws_ssm_parameter" "http_listener_arn" {
  name = "/${local.global_config.alb}/https-listener-arn"
}

data "aws_vpc" "dev_vpc" {
  id = local.global_config.vpc_id
}

data "aws_subnets" "dev_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dev_vpc.id]
  }
}
