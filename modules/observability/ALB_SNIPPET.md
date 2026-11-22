# Agregar a tu modulo `alb` (aws_lb)

```hcl
access_logs {
  bucket  = var.alb_logs_bucket   # output alb_logs_bucket de observability
  prefix  = "alb"
  enabled = true
}
```
- El bucket y su policy deben existir antes que el ALB (depends_on o pasar el bucket por output).
- Exponer en el modulo alb los outputs `arn_suffix` del LB y del target group.
