provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "mycluster" {
  name = "my-ecs-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "my-tdf" {
  family = "my-task"
  container_definitions = jsonencode([
    {
     name      = "my-container"
     image     = "nginx:latest"
     cpu       = 256
     memory    = 512
     essential = true,
    
    
    # This is the key change: adding a comma before "portMappings"
    portMappings = [
       {
         containerPort = 80
         hostPort      = 80
       }
     ]
    }
   ])
}

# Load Balancer
resource "aws_lb" "my-loadbalancer" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0899928ebfbbdaf82"]
  subnets            = [
    "subnet-08774b4f299c3f5ef",  # Replace with your first subnet ID in a different AZ
    "subnet-00308d31ff7843ef4"   # Replace with your second subnet ID in a different AZ
  ]
}


# Target Group
resource "aws_lb_target_group" "my-tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0c28b7caa4a8934e1"  # Replace with your VPC ID
  target_type = "instance"
}

# Load Balancer Listener
resource "aws_lb_listener" "my-listener" {
  load_balancer_arn = aws_lb.my-loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

# ECS Service
resource "aws_ecs_service" "my-svc" {
  depends_on = [aws_lb.my-load-balancer]
  name            = "my-service"
  cluster         = aws_ecs_cluster.mycluster.id
  task_definition = aws_ecs_task_definition.my-tdf.arn
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-08774b4f299c3f5ef", "subnet-00308d31ff7843ef4"]
    security_groups = ["sg-0899928ebfbbdaf82"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my-tg.arn
    container_name   = "my-container"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.my-listener
  ]
}

# Output the DNS name of the Load Balancer
output "load_balancer_dns_name" {
  value = aws_lb.my-loadbalancer.dns_name
}

