variable "table_name" {}
variable "primary_region" {}
variable "replica_region" {}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

resource "aws_dynamodb_table" "movie_id" {
  provider = aws.primary

  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "title"

  attribute {
    name = "title"
    type = "S"
  }

  replica {
    region_name = var.replica_region
  }
}
