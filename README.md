# Terraform Installation

**Install Terraform on Amazon Linux**

navigate to official website of hashicorp- https://developer.hashicorp.com/terraform/install#linux
 go to install-> select linux-> Amazon linux-> execute this cmds->
```bash
 $ sudo yum install -y yum-utils shadow-utils
 $ sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
 $ sudo yum -y install terraform
 ```
**Install Terraform on ubuntu**
navigate to official website of hashicorp- https://developer.hashicorp.com/terraform/install#linux
 go to install-> select linux-> Ubuntu/Debian-> execute this cmds->
```
 $ wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
 $ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
 $ sudo apt update && sudo apt install terraform
```
**Create terraform working directory**
```
 $ mkdir myterraformdir && cd myterraformdir
```
**Commands**
1. Initialize a Terraform Working Directory- ```terraform init```

2. Generate and Show an Execution Plan- ```terraform plan```
   
3. Apply the Configuration- ```terraform apply```
   
4. Destroy Infrastructure- ```terraform destroy```
   
5. Format Terraform Code- ```terraform fmt```

**configure AWS credentials**
```
 $ export AWS_ACCESS_KEY_ID="your-access-key"
 $ export AWS_SECRET_ACCESS_KEY="your-secret-key"
 $ export AWS_REGION="us-east-1"
