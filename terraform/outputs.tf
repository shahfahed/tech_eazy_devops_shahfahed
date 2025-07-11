output "putobject_ec2_id" {
    description = "EC2 ID"
    value       = aws_instance.ec2[0].id 
}

output "read_only_ec2_id" {
    description = "EC2 ID"
    value       = aws_instance.ec2[1].id 
}

output "putobject_ec2_public_ip" {
    description = "EC2 public IP"
    value       = aws_instance.ec2[0].public_ip  
}

output "read_only_ec2_public_ip" {
    description = "EC2 public IP"
    value       = aws_instance.ec2[1].public_ip  
}
output "s3_bucket_name" {
    description = "EC2 logs bucket"
    value       = aws_s3_bucket.logs_bucket.bucket
}