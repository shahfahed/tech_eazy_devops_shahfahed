output "ec2_id" {
    description = "EC2 ID"
    value       = aws_instance.ec2.id 
}

output "public_ip" {
    description = "EC2 public IP"
    value       = aws_instance.ec2.public_ip  
}