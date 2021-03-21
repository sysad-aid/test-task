output "lb-dns-name" {
  value = aws_lb.test-task-lb.dns_name
  description = "LB's DNS name. Check port TCP/80"
}