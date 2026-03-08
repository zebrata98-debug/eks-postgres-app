eks-postgres-app

A Node.js REST API deployed to AWS EKS (Elastic Kubernetes Service) with a 
managed PostgreSQL database on RDS. The entire infrastructure is provisioned 
with Terraform and the Docker image is built and pushed to ECR automatically 
using AWS CodeBuild — no manual Docker commands needed.

Project Structure
```
eks-postgres-app/
├── app/
│   ├── index.js          # Express REST API with PostgreSQL
│   ├── package.json
│   ├── Dockerfile
│   └── buildspec.yml     # CodeBuild instructions for Docker build + ECR push
├── terraform/
│   ├── main.tf           # Provider config
│   ├── variables.tf      # Input variables
│   ├── vpc.tf            # VPC, subnets, security groups
│   ├── eks.tf            # EKS cluster and node group
│   ├── rds.tf            # RDS PostgreSQL instance
│   ├── ecr.tf            # ECR repository
│   ├── codebuild.tf      # CodeBuild project and IAM role
│   └── outputs.tf        # Cluster endpoint, RDS endpoint, ECR URI
├── k8s/
│   ├── namespace.yaml
│   ├── secret.yaml       # DB credentials
│   ├── configmap.yaml    # Non-sensitive config
│   ├── deployment.yaml   # App deployment with health probes
│   └── service.yaml      # LoadBalancer service
└── README.md
```

Deploy

cd terraform

terraform init

terraform apply -var="db_password=YOUR_PASSWORD"

aws codebuild start-build \
  --project-name eks-postgres-cluster-build \
  --region eu-west-1


aws eks update-kubeconfig \
  --region eu-west-1 \
  --name eks-postgres-cluster

terraform output rds_endpoint

terraform output ecr_repository_url

kubectl apply -f k8s/ 
kubectl get pods -n eks-demo -w

Testing

kubectl get service app-service -n eks-demo

Test endpoints
curl http://YOUR_LB_DNS/health
curl http://YOUR_LB_DNS/users

Create a user
curl -X POST http://YOUR_LB_DNS/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Stanislav", "email": "stan@example.com"}'
