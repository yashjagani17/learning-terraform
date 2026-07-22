output "db_address" {
  value = aws_db_instance.example.address
  description = "Endpoint for the AWS MySQL database"
}

output "db_port" {
  value = aws_db_instance.example.port
  description = "Port for the AWS MySQL database"
}