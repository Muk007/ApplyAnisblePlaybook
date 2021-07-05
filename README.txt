#-------------------Pre-requisites for executing this tf script----------------#

1) The terraform version used for this code is v1.0.1

2) AWS plugin version used is v3.47.0

3) This terraform code needs to have a s3 bucket prior executing this script which will be holding the the playbook since the ssm parameters has s3 url mentioned. So, it pulls that playbook from s3 and executes the same,

4) 
