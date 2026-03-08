variable "aws_region"    { default = "eu-west-1" }
variable "cluster_name"  { default = "eks-postgres-cluster" }
variable "db_name"       { default = "appdb" }
variable "db_username"   { default = "appuser" }
variable "github_owner"  { default = "zebrata98-debug" }
variable "github_repo"   { default = "eks-postgres-app" }
variable "db_password" {
  description = "RDS master password"
  sensitive   = true
}