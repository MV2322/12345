provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "mycluster1" {
  name = "my-ecs-cluster1"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "my-tdef" {
  family = "my-task1"
  container_definitions = jsonencode([
    {
     name      = "my-container1"
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
resource "aws_lb" "my-loadbalancer1" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0d7ebec7909508cc2"]
  subnets            = [
    "subnet-01476685f9318d9a9",  # Replace with your first subnet ID in a different AZ
    "subnet-0a2ea30bc96e7e090"   # Replace with your second subnet ID in a different AZ
  ]
}


# Target Group
resource "aws_lb_target_group" "my-tg1" {
  name     = "my-target-group1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0ea0b66401c8aba3b"  # Replace with your VPC ID
  target_type = "instance"
}

# Load Balancer Listener
resource "aws_lb_listener" "my-listener" {
  load_balancer_arn = aws_lb.my-loadbalancer1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-tg1.arn
  }
}

# ECS Service
resource "aws_ecs_service" "my-svc" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.mycluster1.id
  task_definition = aws_ecs_task_definition.my-tdef.arn
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-01476685f9318d9a9", "subnet-0a2ea30bc96e7e090"]
    security_groups = ["sg-0d7ebec7909508cc2"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my-tg1.arn
    container_name   = "my-container1"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.my-listener
  ]
}

# Output the DNS name of the Load Balancer
output "load_balancer_dns_name" {
  value = aws_lb.my-loadbalancer1.dns_name
}

