# Terraform Multi-Server Web Application with ALB

## Overview
This project demonstrates how to use Terraform to deploy a scalable multi-server web application on AWS. It provisions:
- **EC2 Instances**: A configurable number of servers running a simple web application.
- **Application Load Balancer (ALB)**: Distributes traffic across the EC2 instances with automatic failover.

The project is designed to be reusable, with clear instructions for customization.

---

## Features
1. **Scalability**: Adjust the number of servers by modifying a single variable.
2. **Failover Support**: ALB automatically reroutes traffic to healthy servers if one goes down.
3. **Customizable Setup**: Easily replace the sample application with your own code.

---

## Prerequisites
1. **Terraform Installed**: Version 1.0+ ([Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
2. **AWS Account**: Ensure you have an AWS account with access keys configured.

---

## Usage Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

---

### 2. Configurable Parts
#### **1. Number of Servers**
Modify the `number_of_servers` variable in the `main.tf` file to set the desired number of EC2 instances:
```hcl
variable "number_of_servers" {
  default = 3  # Change this to the number of servers you need
}
```

#### **2. Application Code**
The EC2 instances use a `user_data` script to install and start a simple web application. Replace the `user_data` script in `main.tf` with your own setup commands:
```hcl
# Replace the commands below with your application's setup instructions
user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install -y httpd
            sudo systemctl start httpd
            sudo systemctl enable httpd
            echo "Welcome to Prod ${count.index + 1}" > /var/www/html/index.html
            EOF
```

---

### 3. Initialize Terraform
Run the following commands to initialize Terraform:
```bash
terraform init
```

---

### 4. Plan and Apply
1. **Plan the Deployment**:
   ```bash
   terraform plan
   ```
   - This will show the resources that will be created.

2. **Apply the Deployment**:
   ```bash
   terraform apply
   ```
   - Type `yes` to confirm.

---

### 5. Access the Application
1. Once the deployment is complete, Terraform will output the ALB DNS name:
   ```bash
   alb_dns_name = "your-load-balancer-dns.amazonaws.com"
   ```
2. Open the DNS name in your browser to access the application.
3. Test failover by stopping one of the EC2 instances in the AWS Console. The ALB will reroute traffic to the remaining healthy instances.

---

## Files Included
- **`main.tf`**: Terraform configuration file containing the entire setup.
- **`.gitignore`**: Ensures Terraform state files and provider binaries are not tracked.

---

## Customization Guide
- Replace the `user_data` script to deploy your own application.
- Adjust the `instance_type` in `main.tf` to use a different EC2 instance type:
  ```hcl
  instance_type = "t2.micro"  # Change this to your preferred instance type
  ```

---

## Troubleshooting
- **ALB Not Routing Traffic**:
  - Ensure the instances are healthy in the ALB Target Group in the AWS Console.
- **Terraform Apply Fails**:
  - Check that your AWS credentials are correctly configured.
  - Ensure no existing resources conflict with the current setup.

---

## License
This project is open source under the MIT License.
