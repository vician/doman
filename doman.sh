#!/bin/bash

if [ $# -eq 0 ]; then
	echo "ERROR: wrong parameters!"
	echo "Shoudl be $0 example.com [www.example.com [mail.example.com]]"
	exit 0
fi

domain="$1"
shift
subdomains="$*"

echo "Analyzing $domain and ${subdomains[*]}"

function dns_a_record {
	fdomain=$1

	a="$(dig +short $fdomain A)"
	if [ "$a" != "" ]; then
		echo "Found A record for $fdomain: $a"
	else
		echo "!!! Not found A record for $fdomain !!!"
	fi
}
function dns_aaaa_record {
	fdomain=$1

	aaaa="$(dig +short $fdomain AAAA)"
	if [ "$aaaa" != "" ]; then
		echo "Found AAAA record for $fdomain: $aaaa"
	else
		echo "!!! Not found AAAA record for $fdomain !!!"
	fi
}

function where_is_dns {
	fdomain=$1

	nameservers=($(dig +short $fdomain NS))
	echo "Found ${#nameservers[@]} nameservers: ${nameservers[*]}"

	for nameserver in ${nameservers[@]}; do
		dns_a_record $nameserver
		dns_aaaa_record $nameserver
	done
}

function where_is_mx {
	fdomain=$1

	mxrecords=($(dig +short $fdomain MX))

	echo "Found ${#mxrecords[@]} mxrecords: ${mxrecords[*]}"

	for mxrecord in ${mxrecords[@]}; do
		mailserver="$(echo $mxrecord | awk '{print $2}')"
		echo "- analyse $mxrecord => $mailserver"

		dns_a_record $mailserver
		dns_aaaa_record $mailserver
	done
}

# Maji IPv4 i IPv6 zaznamy?
dns_a_record $domain
dns_aaaa_record $domain
for subdomain in ${subdomains[@]}; do
	dns_a_and_aaa_record $subdomain
done

where_is_dns $domain
where_is_mx $domain

# has_https $domain
# has_hsts $domain
# dns_tlsa_record $domain
# dns_cca_record $domain
