#!/usr/bin/env bash
set -e

# We use functions in order to be able to pass a variable number of arguments to the shell being invoked.
#
# bash needs two (`--rcfile` followed by the filename), whereas zsh needs one (the full command to be executed at startup,
# which in our case is a `source` command).
#
# Also, we do this shell logic as soon as possible to avoid prompting for an MFA code twice in case we need to retry.

user_shell=$(basename $SHELL)
case $user_shell in
bash)
	function invoke_shell() {
		bash --rcfile /dev/fd/3
	}
	;;
zsh)
	zshi=$(dirname $BASH_SOURCE)/vendor/zshi/zshi

	if ! test -f $zshi; then
		echo 'zshi submodule not detected, but your login shell is zsh.' 2>&1
		echo 'Running `git submodule update --init` to download it.' 2>&1
		if ! (cd $(dirname $BASH_SOURCE) && git submodule update --init); then
			echo 'Failed to download zshi. Retrying with your shell set to bash.' 2>&1
			SHELL=/bin/bash exec $0 "$@"
		fi
	fi

	function invoke_shell() {
		$zshi 'source /dev/fd/3'
	}
	;;
*)
	echo "Unsupported login shell $user_shell detected; retrying with your shell set to bash." 2>&1
	echo '(Feel free to add support for '"$user_shell"'!)' 2>&1
	SHELL=/bin/bash exec $0 "$@"
	;;
esac

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

invoke_shell 3<<EOF
	# Note: the bash process running aws.sh expands these variables _before_ passing it to `$shell`.
	# Therefore, we can reference variables even if they're not exported and it will work OK.
	#
	# If you're not following how this works, try putting `echo` before the test case and watch what's printed.
	#
	# Because of this same behavior, uses of $ (e.g. to access variables) must be changed to \$.
	test $user_shell = bash && . ~/.bashrc
	export AWS_PROD_SHELL=1
	export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
	export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
	export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
	case $user_shell in
	# Different shells have different PS1 metacharacters
	zsh)
		workdir='%~'
		;;
	bash)
		workdir='\w'
		;;
	esac
	PS1="PROD AWS SHELL | \$workdir $ "
	(sleep 3600; echo "\n>>>> AWS ACCESS EXPIRED <<<<") &
	# We disown because zsh by default complains about background jobs when you type ^D
	disown
EOF
