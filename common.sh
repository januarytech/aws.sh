#!/usr/bin/env bash
function export_aws_vars() {
    results=$1
    export AWS_ACCESS_KEY_ID=$(echo "$results" | jq '.Credentials.AccessKeyId' -r)
    export AWS_SECRET_ACCESS_KEY=$(echo "$results" | jq '.Credentials.SecretAccessKey' -r)
    export AWS_SESSION_TOKEN=$(echo "$results" | jq '.Credentials.SessionToken' -r)
}

function get_mfa_session() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    serial_number=$(aws iam list-mfa-devices --user-name $(aws iam get-user --query 'User.UserName' --output text) | jq '.MFADevices[0].SerialNumber' -r)

    printf "Enter AWS MFA code: "
    read -r mfa_code
    results=$(aws sts get-session-token --duration-seconds 7200 --serial-number "${serial_number}" --token-code "${mfa_code}")

    if [[ ! "$results" ]]
    then
      echo "Error obtaining credentials." 1>&2
      exit 1
    fi

    export_aws_vars "$results"
}

function assume_role() {
    role=$1
    if [[ "$2" != "" ]]; then
        session_name="$2"
    else
        session_name=$(date +"%s")
    fi

    results=$(aws sts assume-role --role-arn arn:aws:iam::000000000000:role/"${role}"\
     --role-session-name "${session_name}" --duration-seconds 900)

    if [[ ! "$results" ]]
    then
      echo "Error obtaining credentials." 1>&2
      exit 1
    fi

    export_aws_vars "$results"
}
