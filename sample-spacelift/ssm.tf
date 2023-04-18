resource "aws_ssm_parameter" "spacelift_test" {
  type  = "String"
  name = "/spacelift/test"
  value = "test"
}

resource "aws_ssm_parameter" "spacelift_test2" {
  type  = "String"
  name = "/spacelift/test"
  value = "test2"
}
