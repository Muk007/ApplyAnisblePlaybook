resource "aws_ssm_document" "document_1" {
    name          = "mistnet_ssm_document"
    document_type = "Command"

    content = <<DOC
    {
        "schemaVersion": "2.2",
        "description": "Run Ansible playbook using AWS SSM",
        "parameters": {
            "Check": {
                "allowedValues": [
                    "True",
                    "False"
                ],
                "default": "False",
                "description": "(Optional) Use this parameter to run a check of the Ansible execution.",
                "type": "String"
            },
            "ExtraVariables": {
                "allowedPattern": "^((^|\\s)\\w+=(\\S+|'.*'))*$",
                "default": "SSM=True",
                "description": "(Optional) Additional variables to pass to Ansible at runtime. Enter key/value pairs separated by a space. For example: color=red flavor=cherry",
                "displayType": "textarea",
                "type":  "String"
            },
            "InstallDependencies": {
                "allowedValues": [
                    "True",
                    "False"
                ],
                "default":  "True",
                "description": "(Required) If set to True, Systems Manager installs Ansible and its dependencies, including Python, from the PyPI repo. If set to False, then verify that Ansible and its dependencies are installed on the target instances. If they aren’t, the SSM document fails to run.",
                "type": "String"
            },
            "PlaybookFile": {
                "allowedPattern": "[(a-z_A-Z0-9\\-\\.)/]+(.yml|.yaml)$",
                "default": "test-playbook.yml",
                "description": "(Optional) The Playbook file to run (including relative path). If the main Playbook file is located in the ./automation directory, then specify automation/playbook.yml.",
                "type":  "String"
            },
            "SourceInfo": {
                "default": {"owner":"Muk007","repository":"playbook","path":"level_1","getOptions":"branch:master"},
                "description": "(Optional) Specify the information required to access the resource from the specified source type. If source type is GitHub, then you can specify any of the following: 'owner', 'repository', 'path', 'getOptions', 'tokenInfo'. Example GitHub parameters: {\"owner\":\"awslabs\",\"repository\":\"amazon-ssm\",\"path\":\"Compliance/InSpec/PortCheck\",\"getOptions\":\"branch:master\"}. If source type is S3, then you can specify 'path'. Important: If you specify S3, then the IAM instance profile on your managed instances must be configured with read access to Amazon S3.",
                "displayType": "textarea",
                "type": "StringMap"
            },
            "SourceType": {
                "allowedValues": [
                    "GitHub",
                    "S3"
                ],
                "description": "(Optional) Specify the source type.",
                "type": "String",
                "default": "GitHub"
            },
            "TimeoutSeconds": {
                "default": "3600",
                "description": "(Optional) The time in seconds for a command to be completed before it is considered to have failed.",
                "type": "String"
            },
            "Verbose": {
                "allowedValues": [
                    "-v",
                    "-vv",
                    "-vvv",
                    "-vvvv"
                ],
                "default": "-v",
                "description": "(Optional) Set the verbosity level for logging Playbook executions. Specify -v for low verbosity, -vv or –vvv for medium verbosity, and -vvvv for debug level.",
                "type": "String"
            }
        },
        "mainSteps": [
            {
                "action": "aws:downloadContent",
                "inputs": {
                    "SourceInfo": "{{ SourceInfo }}",
                    "SourceType": "{{ SourceType }}"
                },
                "name": "downloadContent"
            },
            {
                "action": "aws:runShellScript",
                "inputs": {
                    "runCommand": [
                        "#!/bin/bash",
                        "if  [[ \"{{InstallDependencies}}\" == True ]] ; then",
                        "   echo \"Installing and or updating required tools: Ansible, wget unzip ....\" >&2",
                        "   if [ -f  \"/etc/system-release\" ] ; then",
                        "     if cat /etc/system-release|grep -i 'Amazon Linux release 2' ; then ",
                        "       sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                        "       sudo yum install -y ansible",
                        "       sudo yum -y install unzip",
                        "     elif cat /etc/system-release|grep -i 'Amazon Linux AMI' ; then ",
                        "       sudo pip install ansible --upgrade",           
                        "       sudo yum -y install unzip",
                        "     elif cat /etc/system-release|grep -i 'Red Hat Enterprise Linux' ; then ",
                        "       sudo yum -y install python3-pip",
                        "       sudo pip3 install ansible",
                        "       sudo yum -y install unzip",
                        "     else",
                        "       echo \"There was a problem installing or updating the required tools for the document. You can review the log files to help you correct the problem.\" >&2",
                        "       exit 1",
                        "     fi",
                        "   elif cat /etc/issue|grep -i Ubuntu ; then ",
                        "     UBUNTU_VERSION=$(cat /etc/issue | grep -i ubuntu | awk '{print $2}' |  awk -F'.' '{print $1}')",
                        "     sudo apt-get update",
                        "     if [ $(($UBUNTU_VERSION > 18)) == 1 ]; then",
                        "       sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-pip -y",
                        "       sudo pip3 install ansible --upgrade",
                        "     else",
                        "       sudo DEBIAN_FRONTEND=noninteractive apt-get install python-pip -y",
                        "       sudo pip install ansible --upgrade",
                        "     fi",
                        "     sudo DEBIAN_FRONTEND=noninteractive apt-get install unzip -y",
                        "   else",
                        "     echo \"There was a problem installing or updating the required tools for the document. You can review the log files to help you correct the problem.\" >&2",
                        "     exit 1",
                        "   fi",
                        "fi",
                        "echo \"Running Ansible in `pwd`\"",
                        "#this section locates files and unzips them",
                        "for zip in $(find -iname '*.zip'); do",
                        "  unzip -o $zip",
                        "done",
                        "#PlaybookFile=\"test-playbook.yml\"",
                        "if [ ! -f  \"test-playbook.yml\" ] ; then",
                        "   echo \"The specified Playbook file doesn't exist in the downloaded bundle. Please review the relative path and file name.\" >&2",
                        "   exit 2",
                        "fi",
                        "if  [[ \"{{Check}}\" == True ]] ; then",
                        "   ansible-playbook -i \"localhost,\" --check -c local -e \"{{ExtraVariables}}\" \"{{Verbose}}\" \"test-playbook.yml\"",
                        "else",
                        "   ansible-playbook -i \"localhost,\" -c local -e \"{{ExtraVariables}}\" \"{{Verbose}}\" \"test-playbook.yml\"",
                        "fi"
                    ],
                    "timeoutSeconds": "{{ TimeoutSeconds }}"
                },
                "name": "runShellScript"
            }
        ]
    }
DOC
}

resource "aws_ssm_association" "association_1" {
    name = aws_ssm_document.document_1.name
    output_location {
        s3_bucket_name = var.s3_bucket_name
    }
    targets {
        key    = "InstanceIds"
        values = [var.instance_id]
    }
}
