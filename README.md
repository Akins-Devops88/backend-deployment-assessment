# StartupTech — MuchTodo Backend Deployment on AWS

## 1. Project Overview

This project demonstrates the deployment of a Golang REST API using Docker, Terraform, and Amazon Web Services (AWS).

The application is MuchTodo, a task management REST API backed by MongoDB.

The deployment includes:

- AWS infrastructure provisioned using Terraform
- A custom Virtual Private Cloud (VPC)
- Public and private subnets across two Availability Zones
- A public bastion host for secure SSH access
- A private EC2 instance running the backend API
- A separate private EC2 instance running MongoDB
- An internet-facing Application Load Balancer
- Docker containerization of the Golang application
- Amazon Elastic Container Registry (ECR)
- Local development using Docker Compose
- IAM roles and AWS Systems Manager integration

## 2. Technology Stack

| Component | Technology |
|---|---|
| Backend | Golang |
| Database | MongoDB |
| Containerization | Docker |
| Local orchestration | Docker Compose |
| Infrastructure as Code | Terraform |
| Cloud platform | AWS |
| Container registry | Amazon ECR |
| Load balancing | AWS Application Load Balancer |
| Virtual machines | Amazon EC2 |
| Networking | Amazon VPC |
| Access management | AWS IAM |
| Remote management | AWS Systems Manager |

## 3. AWS Architecture

The deployed architecture is:

Internet
   |
   v
Application Load Balancer
   |
   v
Private Backend EC2
   |
   v
Dockerized MuchTodo API
   |
   v
Private MongoDB EC2
   |
   v
MongoDB Docker Container

Administrative access follows:

Administrator
   |
   v
Public Bastion EC2
   |
   +----> Private Backend EC2
   |
   +----> Private MongoDB EC2

### Networking

The infrastructure uses:

- VPC CIDR: `10.0.0.0/16`
- Public subnet A: `10.0.1.0/24`
- Public subnet B: `10.0.2.0/24`
- Private subnet A: `10.0.11.0/24`
- Private subnet B: `10.0.12.0/24`

An Internet Gateway provides internet access to public subnets.

A NAT Gateway provides outbound internet access for resources in private subnets.

Security groups restrict access between the ALB, bastion, backend, and database.

## 4. Prerequisites

Install and configure:

- Git
- Terraform
- AWS CLI
- Docker
- Docker Compose
- An AWS account with appropriate IAM permissions
- An EC2 SSH key pair

Configure AWS credentials using a named profile:

```bash
aws configure --profile assessment
```

Verify access:

```bash
aws sts get-caller-identity --profile assessment
```

Never commit AWS credentials or private SSH keys.

## 5. Terraform Infrastructure Deployment

Navigate to the Terraform directory:

```bash
cd terraform
```

Select the AWS profile:

```bash
export AWS_PROFILE=assessment
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the proposed infrastructure changes:

```bash
terraform plan
```

For a new deployment, review the plan carefully before running:

```bash
terraform apply
```

**Warning:** Do not apply changes to an existing deployment without reviewing resource replacements and deletions.

The Terraform configuration is divided into files for networking, EC2, IAM, security groups, and load balancing.

## 6. Build the Docker Image

From the project root:

```bash
docker build --progress=plain -t startuptech-muchtodo:assessment .
```

Verify the image:

```bash
docker images startuptech-muchtodo
```

The Dockerfile uses a multi-stage build to compile the Golang application and produce a runtime image.

## 7. Run the Application Locally

Create a local environment file containing the required variables.

An example configuration is provided in `.env.example`.

Do not commit the real `.env` file.

Validate Docker Compose:

```bash
docker compose config --quiet
```

Start the local services:

```bash
docker compose up -d --build
```

Verify the containers:

```bash
docker compose ps
```

The local Compose configuration includes:

- MuchTodo backend
- MongoDB
- A Docker network
- Persistent MongoDB storage
- Container health checks

## 8. Local Health Check

Test the local application:

```bash
curl -i http://localhost:8080/health
```

A successful response includes:

```json
{
  "cache": "disabled",
  "database": "ok"
}
```

The HTTP status should be `200 OK`.

## 9. AWS Backend Deployment

The deployed backend runs as a Docker container on a private EC2 instance.

The application image is stored in Amazon ECR.

The backend EC2 instance pulls and runs the container image.

MongoDB runs in a Docker container on a separate private EC2 instance.

The backend connects to MongoDB over the private VPC network.

## 10. Bastion Host Access

The bastion host provides controlled SSH access to private EC2 instances.

Example connection pattern:

```bash
ssh -i ~/.ssh/YOUR_PRIVATE_KEY \
  -o IdentitiesOnly=yes \
  -o ProxyCommand="ssh -i ~/.ssh/YOUR_PRIVATE_KEY -o IdentitiesOnly=yes -W %h:%p ubuntu@BASTION_PUBLIC_IP" \
  ubuntu@BACKEND_PRIVATE_IP
```

Replace the placeholders with your deployment values.

Restrict bastion SSH access to trusted public IP addresses.

## 11. Public Application Verification

The application is available through the Application Load Balancer.

Deployed endpoint:

http://startuptech-alb-256398167.us-east-1.elb.amazonaws.com

Health check:

```bash
curl -i http://startuptech-alb-256398167.us-east-1.elb.amazonaws.com/health
```

A successful response returns HTTP `200 OK` and confirms database connectivity.

Swagger documentation is available at:

http://startuptech-alb-256398167.us-east-1.elb.amazonaws.com/swagger/index.html

## 12. Application Functionality

The API supports:

- User registration
- User login
- JWT authentication
- Authenticated user profile retrieval
- Todo creation
- Todo retrieval
- Todo updates
- Todo deletion

The application endpoints were tested successfully through the public ALB.

## 13. Security Measures

Security controls include:

- Private subnets for backend and MongoDB
- Security-group-restricted database access
- Bastion-host-mediated SSH access
- IAM instance roles
- AWS Systems Manager integration
- Docker containerization
- Environment variables for application secrets
- Git exclusions for sensitive files

Do not upload:

- `.env`
- AWS credentials
- SSH private keys
- Live Terraform state containing sensitive values
- Real `terraform.tfvars`
- Database passwords
- JWT signing secrets

The public ALB currently serves HTTP. HTTPS with an appropriate TLS certificate is recommended for production use.

## 14. Evidence Screenshots

Assessment evidence is stored in the `evidence/` directory.

The intended screenshot set includes:

1. Terraform initialization
2. Terraform plan
3. Terraform deployment verification
4. VPC configuration
5. Public and private subnets
6. Security groups
7. Running EC2 instances
8. ALB and healthy target group
9. Docker image build
10. Local Docker Compose
11. Local backend health check
12. SSH through bastion
13. Backend EC2 Docker container
14. Public ALB health check

### Evidence Limitations

The current Terraform plan shows the state of an existing deployment rather than the original creation plan.

The original Terraform `Apply complete!` terminal output has not been recovered.

The backend EC2 instance runs the API using Docker, while MongoDB runs on a separate EC2 instance. Docker Compose is used locally but is not currently installed on the backend EC2 instance.

The deployed EC2 instances use Ubuntu rather than the Amazon Linux 2 operating system specified in the assessment.

These differences are documented rather than represented as completed requirements.

## 15. Cleanup

To stop the local Docker Compose environment:

```bash
docker compose down
```

To inspect AWS infrastructure before cleanup:

```bash
cd terraform
terraform plan -destroy
```

For an intentionally decommissioned environment, Terraform supports:

```bash
terraform destroy
```

**Warning:** Terraform destruction can permanently remove infrastructure and data. Do not execute it against an active deployment without confirming backups, dependencies, and authorization.

## 16. Project Status

Verified:

- Terraform initialization and validation
- AWS VPC and subnet provisioning
- Security group configuration
- Three running EC2 instances
- Healthy Application Load Balancer target
- Successful Docker image build
- Healthy local Docker Compose services
- Successful local backend health check
- Bastion-to-private-backend SSH access
- Healthy Dockerized backend on EC2
- Successful public API health check
- JWT authentication and Todo CRUD operations

The AWS deployment is operational. Known differences from the assignment requirements are documented above.
