resource "aws_dynamodb_table" "fead_table" {
    name           = "${var.env}-${var.product}"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "PK"
    range_key      = "SK"

    attribute {
        name = "PK"
        type = "S"
    }
    attribute {
        name = "SK"
        type = "S"
    }
    attribute {
        name = "PK1"
        type = "S"
    }
    attribute {
        name = "SK1"
        type = "S"
    }

    attribute {
        name = "PK2"
        type = "S"
    }
    attribute {
        name = "SK2"
        type = "S"
    }

    global_secondary_index {
        name               = "Inverted"
        hash_key           = "SK"
        range_key          = "PK"
        projection_type    = "ALL"
    }
    global_secondary_index {
        name               = "Gsi1"
        hash_key           = "PK1"
        range_key          = "SK1"
        projection_type    = "ALL"
    }
    global_secondary_index {
        name               = "Gsi2"
        hash_key           = "PK2"
        range_key          = "SK2"
        projection_type    = "ALL"
    }

    tags = {
        Env = "${var.env}"
    }
}
