output "cluster_endpoint"      { value = aws_eks_cluster.main.endpoint }
output "cluster_name"          { value = aws_eks_cluster.main.name }
output "rds_endpoint"          { value = aws_db_instance.postgres.endpoint }
output "codebuild_project_name" { value = aws_codebuild_project.app.name }