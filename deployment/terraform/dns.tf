data "aws_route53_zone" "zone" {
  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = format("vpn.%s", data.aws_route53_zone.zone.name)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.vpn.public_ip]
}
