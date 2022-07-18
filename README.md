# aws-prod-ready-terraform

## Plan, Apply, Destroy
```bash
# plan
terraform plan
# apply
terraform apply
# destroy
terraform destroy
```

## Overwrite ssm parameters
Execute following command to change SSM parameters

Note: Change name, type, value parameter as you target

```bash
aws ssm put-parameter --name '/db/password' --type SecureString --value 'VeryStrongPassword!' --overwrite
```