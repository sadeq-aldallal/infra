resource "aws_dynamodb_table" "users_table" {
    name           = "${var.env}-${var.prodect}-users"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "id"

    attribute {
        name = "id"
        type = "S"
    }

    attribute {
        name = "username"
        type = "S"
    }

    global_secondary_index {
        name               = "username-index"
        hash_key           = "username"
        projection_type    = "ALL"
    }

    tags = {
        Env = "${var.env}"
    }
}
