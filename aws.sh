#!/usr/bin/env bash
set -e

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
serial_number=`aws iam list-mfa-devices | jq '.MFADevices[0].SerialNumber' -r`

echo "Enter AWS MFA code: "
read mfa_code
results=`aws sts get-session-token --duration-seconds 3600 --serial-number ${serial_number} --token-code ${mfa_code}`

if [[ ! "$results" ]]
then
  echo "Error obtaining credentials."
  exit 1
fi

echo "Obtained temporary AWS credentials. They will expire in one hour and will only work in this terminal."
export AWS_ACCESS_KEY_ID=`echo $results | jq '.Credentials.AccessKeyId' -r`
export AWS_SECRET_ACCESS_KEY=`echo $results | jq '.Credentials.SecretAccessKey' -r`
export AWS_SESSION_TOKEN=`echo $results | jq '.Credentials.SessionToken' -r`

# Redacted environment-specific setup script

bash --rcfile /dev/fd/3 3<<EOF
	. ~/.bashrc
	export AWS_PROD_SHELL=1
	export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
	export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
	export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
	PS1="PROD AWS SHELL | \w $ "
	(sleep 3600; echo "\n>>>> AWS ACCESS EXPIRED <<<<") &
EOF
