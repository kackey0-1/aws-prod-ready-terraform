### Terraform
```bash
# Set up SSM parameter for DB passwd
aws ssm put-parameter --name /database/password  --value mysqlpassword --type SecureString

terraform init

terraform plan

terraform apply
```

### Git Repo Setup
When you face a problem while setting up, please see this document
https://docs.aws.amazon.com/ja_jp/codecommit/latest/userguide/troubleshooting-ch.html
```bash
cd ~
git clone git@github.com:kackey0-1/cloud-resource-tempates.git
cd ~/cloud-resource-tempates/aws-app-runner
git config --local user.name "Your Name"
git config --local user.email you@example.com

git init
git add .
git commit -m "Baseline commit"

### Set up the remote CodeCommit repo
# An AWS CodeCommit repo was built as part of the pipeline you created. You will now set this up as a remote repo for your local petclinic repo.
# For authentication purposes, you can use the AWS IAM git credential helper to generate git credentials based on your IAM role permissions. Run:
git config --local credential.helper '!aws codecommit credential-helper $@'
git config --local credential.UseHttpPath true

# From the output of the Terraform build, we use the output `source_repo_clone_url_http` in our next step.
#  cd ~/environment/aws-app-runner/terraform
#  cd ~/environment/aws-app-runner
aws codecommit list-repositories --profile default
export tf_source_repo_clone_url_http=value
git remote add origin $tf_source_repo_clone_url_http
git remote -v
git push -u origin master
```
