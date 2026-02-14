# Three-tier app

Minimal Node.js app for the 3-tier stack.

- **GET /** – Hello JSON
- **GET /health** – ALB health check (returns 200)
- **GET /db** – Reads DB secret from Secrets Manager (needs env `DB_SECRET_ARN` or `DB_SECRET_NAME`; app role has permission)

Get the secret ARN from Terraform: `terraform output db_secret_arn`. When running the container, set `DB_SECRET_ARN` to that value so `/db` returns `{ db: "reachable" }`.

## Build and push to ECR

```bash
# From repo root; set your ECR URL (from Terraform output or AWS console)
ECR_URI=123456789012.dkr.ecr.ap-south-1.amazonaws.com/three-tier-app

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${ECR_URI%/*}
docker build -t three-tier-app ./app
docker tag three-tier-app:latest $ECR_URI:latest
docker push $ECR_URI:latest
```

Then run an instance refresh on the blue ASG (or update launch template and let new instances pick the image).
