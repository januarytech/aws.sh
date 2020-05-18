#!/usr/bin/env bash
set -e
serial_number=`aws iam list-mfa-devices | jq '.MFADevices[0].SerialNumber' -r`

echo "Enter AWS MFA code: "
read mfa_code
results=`aws sts get-session-token --duration-seconds 3600 --serial-number ${serial_number} --token-code ${mfa_code}`

if [[ ! results ]]
then
  echo "Error obtaining credentials."
  exit 1
fi

echo "Obtained temporary AWS credentials. They will expire in one hour."
echo
echo "To load credentials into your environment, run the following:"
echo export AWS_ACCESS_KEY_ID=`echo $results | jq '.Credentials.AccessKeyId'`
echo export AWS_SECRET_ACCESS_KEY=`echo $results | jq '.Credentials.SecretAccessKey'`
echo export AWS_SESSION_TOKEN=`echo $results | jq '.Credentials.SessionToken'`

