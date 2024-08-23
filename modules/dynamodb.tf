# resource "aws_dynamodb_table" "dynamodb_table" {
#     name           = "${var.env}-users"
#     billing_mode   = "PROVISIONED"
#     read_capacity  = 5
#     write_capacity = 5

#     attribute {
#         name = "id"
#         type = "S"
#     }
#     attribute {
#         name = "name"
#         type = "S"
#     }
#     attribute {
#         name = "username"
#         type = "S"
#     }
#     attribute {
#         name = "email"
#         type = "S"
#     }
#     attribute {
#         name = "phone_number"
#         type = "S"
#     }
#     attribute {
#         name = "province"
#         type = "S"
#     }

#     key {
#         name = "id"
#         type = "HASH"
#     }
# }