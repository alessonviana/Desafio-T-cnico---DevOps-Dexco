resource "aws_ecs_task_definition" "task" {
  for_each                 = local.microservices
  family                   = "${each.value.service_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution_role[each.key].arn
  cpu                      = "256"
  memory                   = "512" 
  container_definitions = <<DEFINITION
[
  {
    "name": "${each.value.service_name}-container",
    "image": "nginx:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${each.value.port != "" ? each.value.port : 8080},
        "hostPort": ${each.value.port != "" ? each.value.port : 8080},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${each.value.service_name}-logs",
        "awslogs-region": "${local.global_config.region}",
        "awslogs-stream-prefix": "${each.value.service_name}",
        "awslogs-create-group": "true"
      }
    }
  }
]
DEFINITION
}

resource "aws_iam_role" "execution_role" {
  for_each = local.microservices
  name     = "${each.value.service_name}-execution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# resource "aws_iam_role_policy_attachment" "task_execution_role_policies" {
#   for_each = { for idx, attachment in local.policy_attachments : idx => attachment }
#   role       = aws_iam_role.execution_role[each.value.microservice_name].name
#   policy_arn = each.value.policy_arn
#   # Make sure to create the policies first.
#   depends_on = [
#     module.policies
#   ]
# }

resource "aws_ecs_service" "service" {
  for_each        = local.microservices
  name            = each.value.service_name
  cluster         = "${local.global_config.cluster_name}-${local.global_config.env}"
  task_definition = "${aws_ecs_task_definition.task[each.key].arn}"
  health_check_grace_period_seconds = each.value.health_check_grace_period_seconds != "" ? each.value.health_check_grace_period_seconds : 0
  launch_type     = "FARGATE"

  desired_count = each.value.desired_count != "" ? each.value.desired_count : 1

  network_configuration {
    subnets          = local.subnets
    security_groups  = [aws_security_group.ecs_service[each.key].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this[each.key].arn
    container_name   = "${each.value.service_name}-container"
    container_port   = each.value.port != "" ? each.value.port : 8080
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb_target_group" "this" {
  for_each    = local.microservices
  name        = each.value.service_name
  port        = each.value.port != "" ? each.value.port : 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id
  health_check {
    enabled  = true
    path     = each.value.health_check_path != "" ? each.value.health_check_path : "/"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_listener_rule" "example" {
  for_each     = local.microservices
  listener_arn = data.aws_ssm_parameter.http_listener_arn.value

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path
    }
  }
}

resource "aws_security_group" "ecs_service" {
  for_each    = local.microservices
  name        = "${each.value.service_name}-ecs-service"
  description = "Allow traffic to ECS service"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = each.value.port != "" ? each.value.port : 8080
    to_port     = each.value.port != "" ? each.value.port : 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "this" {
  for_each = local.microservices
  name     = each.value.service_name
}