# Create EC2 instance
resource "aws_instance" "main" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.sg_id]
    subnet_id = local.private_subnet_id
    
    tags = merge (
        local.common_tags,
