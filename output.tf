output "dns" {
  value = "http://${aws_route53_record.www.name}"
}