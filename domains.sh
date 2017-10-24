#!/bin/bash

enable_whois=0

domains=$@

echo "testing domains: ${domains[@]}";

for domain in ${domains[@]}; do
	echo "- $domain"

	ipv4_record="$(dig +short $domain A)"
	if [ "$ipv4_record" ]; then
		echo -e "\t IPv4 OK ($ipv4_record)"
		if [ $enable_whois -eq 1 ]; then
			as4="$(whois $ipv4_record | grep origin | awk '{print $2}')"
			echo -e "\t\tas: $as4"
		fi
	else
		echo -e "\t IPv4 FAIL!!!"
	fi
	ipv6_record="$(dig +short $domain AAAA)"
	if [ "$ipv6_record" ]; then
		echo -e "\t IPv6 OK ($ipv6_record)"
		if [ $enable_whois -eq 1 ]; then
			as6="$(whois $ipv6_record | grep origin | awk '{print $2}')"
			echo -e "\t\tas: $as6"
		fi
	else
		echo -e "\t IPv6 FAIL!!!"
	fi

	nsrecords=($(dig +short $domain NS))
	echo -e "\t NS: ${nsrecords[*]}"

	dnskeys=($(dig +short $domain DNSKEY @8.8.8.8))

	if [ "$dnskeys" ]; then
		echo -e "\t DNSSEC OK (${#dnskeys[@]})"
	else
		echo -e "\t DNSSEC FAIL!!!"
	fi

	if [ "$domain" != "bezsanonu.cz" ]; then
		ssl=$(openssl s_client -servername $domain -connect $domain:https < /dev/null 2>/dev/null  | grep Verify)
		if [ "$ssl" ]; then
			echo -e "\t HTTPS OK: $ssl"
		else
			echo -e "\t HTTPS FAIL!!!!"
		fi
	else
		echo -e "\t HTTPS FAIL!!!!"
	fi

	if [ "$domain" != "bezsanonu.cz" ]; then
		redirect="$(curl -w "%{url_effective}\n" -I -L -s -S $domain -o /dev/null)"
		echo $redirect | grep https\: 1>/dev/null 2>/dev/null
		if [ $? -eq 0 ]; then
			echo -e "\t HTTPS 302 OK ($redirect)"
		else
			echo -e "\t HTTPS 302 FAILED! ($redirect)"
		fi

		strict_base=$(curl -s -D- https://$domain | grep Strict)
		strict_redirect=$(curl -s -D- $redirect | grep Strict)

		if [ "$strict_base" ]; then
			echo -e "\t HSTS base OK ($strict_base)"
		else
			echo -e "\t HSTS base FALSE ($strict_base)"
		fi
		if [ "$strict_redirect" ]; then
			echo -e "\t HSTS redirect OK ($strict_redirect)"
		else
			echo -e "\t HSTS redirect FALSE ($strict_redirect)"
		fi
	fi

	caa=$(host -t CAA $domain | grep -i CAA)
	if [ "$caa" ]; then
		echo -e "\t CAA OK ($caa)"
	else
		echo -e "\t CAA FAILED!!!"
	fi

	tlsa="$(host -t TLSA _443._tcp.$domain | grep -i TLSA)"
	if [ "$tlsa" ]; then
		echo -e "\t TLSA OK ($tlsa)"
	else
		echo -e "\t TLSA FAILED!!!"
	fi

	mx="$(host -t MX $domain | grep -i MX | head -n 1)"
	if [ "$mx" ]; then
		echo -e "\t MX OK ($mx)"
	else
		echo -e "\t MX FAILED!!!"
	fi

	spf="$(dig +short $domain TXT | grep -i spf)"
	if [ "$spf" ]; then
		echo -e "\t SPF OK ($spf)"
	else
		echo -e "\t SPF FAILED!!!"
	fi

	googledkim=$(dig +short google._domainkey.$domain TXT | grep -i dkim)
	if [ "$googledkim" ]; then
		echo -e "\t GDKIM OK ($googledkim)"
	else
		echo -e "\t GDKIM FAILED!!!"
	fi
done
