locals {
  config        = yamldecode(file("./environments/${terraform.workspace}.yaml"))
  global_config = local.config.global
  microservices = local.config.microservices
  vpc_id        = data.aws_vpc.dev_vpc.id
  subnets       = data.aws_subnets.dev_subnets.ids

  default_tags = {
    managed_by    = local.global_config.tags.managed_by
    env           = local.global_config.env
    repository    = local.global_config.tags.repository
    service       = "${local.global_config.cluster_name}-${local.global_config.env}"
    documentation = local.global_config.tags.documentation
  }

  policy_attachments = flatten([
    for microservice_name, microservice in local.microservices : [
      for policy in microservice.policies : {
        microservice_name = microservice_name
        policy_arn        = policy
      }
    ]
  ])
}