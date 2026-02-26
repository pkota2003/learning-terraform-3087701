data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner] # Bitnami

}


module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.Environment.name
  cidr = "${var.Environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["${var.Environment.network_prefix}.1.0/24", "${var.Environment.network_prefix}.2.0/24", "${var.Environment.network_prefix}.3.0/24"]
  public_subnets  = ["${var.Environment.network_prefix}.101.0/24", "${var.Environment.network_prefix}.102.0/24", "${var.Environment.network_prefix}.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.Environment.name
  }
}



module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "blog-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets =  module.blog_vpc.public_subnets

  security_groups = [module.blog_sg.security_group_id]

   listeners = {
    blog-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_arn = aws_lb_target_group.blog.arn
      }
    }
   }

 tags = {
    Environment = var.Environment.name
  }
}


resource "aws_lb_target_group" "blog" {
  name     = "blog"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id

}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"
  name    = "blog_new"
   vpc_id =  module.blog_vpc.vpc_id
  
   ingress_rules = ["http-80-tcp","https-443-tcp"]
   ingress_cidr_blocks = ["0.0.0.0/0"]
  
   egress_rules = ["all-all"]
   egress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "blog" {
  name = "blog"
  description = "Allow http and https in. Allow everthing out"

  vpc_id =  module.blog_vpc.vpc_id
}

resource "aws_security_group_rule" "blog_http_in" {
  type       = "ingress"
  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type       = "ingress"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_everything_out" {
  type       = "egress"
  from_port  =  0
  to_port    =  0
  protocol   = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.0"
  
  name ="blog"

  min_size = var.min_size
  max_size = var.max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets

  launch_template_name  = "blog"
  security_groups = [module.blog_sg.security_group_id]
  instance_type = var.instance_type
  image_id        = data.aws_ami.app_ami.id

  traffic_source_attachments ={
  blog-alb={
    traffic_source_identifier = aws_lb_target_group.blog.arn
  }
  }
}

