
function send_webhook_sev {
	[[ -z $text ]] && echo \ error: function $0 requires \$text && exit 1
	# lock is optional (not required for detectors)
	# sev already checked, but not yet its deference (webhook url)

	# indirection / deference
	wh_url="`eval echo \$webhook_$sev`"
	[[ -z $wh_url ]] && echo error: define webhook_$sev in dam.conf && exit 1

	if (( dummy == 1 )); then
		echo the following would be sent to webhook_$sev
		echo "$text"
	else
		echo -n \ info: $alert - sending webhook_$sev ...
		curl -sX POST --fail -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" "$wh_url" || echo FAIL; echo

		[[ -n $lock ]] && touch $lock
	fi

	unset wh_url
}

