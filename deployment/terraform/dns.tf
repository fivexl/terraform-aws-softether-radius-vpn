data "aws_route53_zone" "this" {
  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = format("vpn.%s", data.aws_route53_zone.this.name)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.public_ip]
}
