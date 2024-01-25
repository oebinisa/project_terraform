# Build AWS Infrastructure with Terraform

## File Structure Tree

- The Directory layout below provides separation of implementation
- The aws-backend-state-locking section is optional but needed in a collaborative environment
- The .modules section enables code reuse

       .
       ├── aws-backend-state-locking
       │   └── main.tf
       │
       ├── .modules
       │   ├── compute-module
       │   │   ├── main.tf
       │   │   └── variables.tf
       │   └── networking-module
       │       ├── main.tf
       │       └── variables.tf
       │
       ├── dev
       │   ├── compute
       │   │   ├── main.tf
       │   │   └── terraform.tfvars
       │   └── networking
       │       ├── main.tf
       │       └── terraform.tfvars
       │
       ├── production
       │   ├── compute
       │   │   ├── main.tf
       │   │   └── terraform.tfvars
       │   └── networking
       │       ├── main.tf
       │       └── terraform.tfvars
       │
       └── staging
           ├── compute
           │   ├── main.tf
           │   └── terraform.tfvars
           └── networking
               ├── main.tf
               └── terraform.tfvars
