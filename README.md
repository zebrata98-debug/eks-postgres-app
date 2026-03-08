# eks-postgres-app

A Node.js REST API deployed to AWS EKS (Elastic Kubernetes Service) with a 
managed PostgreSQL database on RDS. The entire infrastructure is provisioned 
with Terraform and the Docker image is built and pushed to ECR automatically 
using AWS CodeBuild — no manual Docker commands needed.

This is the cloud-native version of my local Kubernetes + PostgreSQL project, 
running on real AWS infrastructure instead of Minikube.

## Architecture
```
Internet → AWS LoadBalancer → EKS Node Group (2 nodes, t3.small)
                                      ↓
                              App Pods (2 replicas)
                                      ↓
                           RDS PostgreSQL (db.t3.micro)
```

## Infrastructure

All AWS resources are provisioned with Terraform:

- VPC with public subnets across 2 availability zones
- Internet Gateway and route tables
- EKS cluster with managed node group (2x t3.small nodes)
- RDS PostgreSQL 15 instance in a private security group
- ECR repository for storing Docker images
- CodeBuild project that builds and pushes Docker images automatically
- AWS LoadBalancer exposing the app publicly
- IAM roles for EKS cluster, worker nodes, and CodeBuild

## Project Structure
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

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check |
| GET | /users | List all users |
| POST | /users | Create a user |
| DELETE | /users/:id | Delete a user |

## How to Deploy

You need Terraform, AWS CLI, and kubectl installed and configured.
```bash
# 1. Provision infrastructure (~15 minutes)
cd terraform
terraform init
terraform apply -var="db_password=YOUR_PASSWORD"

# 2. Trigger CodeBuild to build and push Docker image
aws codebuild start-build \
  --project-name eks-postgres-cluster-build \
  --region eu-west-1

# 3. Configure kubectl
aws eks update-kubeconfig \
  --region eu-west-1 \
  --name eks-postgres-cluster

# 4. Update k8s/secret.yaml with RDS endpoint from terraform output
terraform output rds_endpoint

# 5. Update k8s/deployment.yaml with ECR URI
terraform output ecr_repository_url

# 6. Deploy to EKS
kubectl apply -f k8s/
kubectl get pods -n eks-demo -w
```

## Testing
```bash
# Get LoadBalancer URL
kubectl get service app-service -n eks-demo

# Test endpoints
curl http://YOUR_LB_DNS/health
curl http://YOUR_LB_DNS/users

# Create a user
curl -X POST http://YOUR_LB_DNS/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Stanislav", "email": "stan@example.com"}'
```

## Cleanup

Always destroy when not in use to avoid charges (~$0.05/hour):
```bash
kubectl delete namespace eks-demo
cd terraform && terraform destroy -var="db_password=YOUR_PASSWORD"
```

## What I Learned

- How EKS manages the Kubernetes control plane so you only manage worker nodes
- How RDS provides managed PostgreSQL with automated backups and patching
- How CodeBuild builds Docker images inside AWS without needing local Docker
- How VPC security groups isolate RDS from direct internet access
- How AWS LoadBalancer integrates automatically with Kubernetes services
- How ECR stores private Docker images that EKS pulls securely
- Troubleshooting CrashLoopBackOff pods by reading kubectl logs
- How Terraform manages complex multi-service AWS infrastructure
```
