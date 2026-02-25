variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}




  variable "ami_filter" {
    description = "Name of the filter and owner for AMI"
    type = object ({
       name   = string
       values = string
  })

  default =  {
    name   = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owner = "979382823631" # Bitnami
  }
}




variable "Environment" {
  description = "Deployment Environment"
  type =object ({
    name = string
    network_prefix = string
  })
  default = {
  name = "dev"
  network_prefix= "10.0"
  }
}

variable "network_prefix"
 cidr = "10.0.0.0/16"


variable "min_size"{
  description ="Minimum number of instances for ASG"
  default =1 
}
 
  variable "max_size"{
  description ="Maximum number of instances for ASG"
  default = 2 
}

