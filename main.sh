#!/bin/bash

# Function: Display usage instructions
show_usage() {
    echo "_____  _____  _______";
    echo "  |   |_____] |______";
    echo "__|__ |       |      ";
    echo "              Trabbit";
    echo
    echo "Usage: $0 -d <domain>";
    echo "Example: $0 -d example.com";
    exit 1
}

banner() {
    echo "_____  _____  _______";
    echo "  |   |_____] |______";
    echo "__|__ |       |      ";
    echo "              Trabbit";
    echo
}

# Function: Fetch domain info
fetch_domain_info() {
  local response=$(curl -s -o /dev/null -w "%{http_code}" "$domain")
  case $response in
    200) rc=$(echo -e "\e[32m200 OK\e[0m") ;;
    404) rc=$(echo -e "\e[31m404 Not Found\e[0m") ;;
    *) rc=$(echo -e "\e[33m$response\e[0m") ;;
  esac

  echo -e "\e[1;34m[Domain Information]\e[0m"
  echo -e "--------------------------------------------------------"
  echo -e "Domain: $domain"
  echo -e "HTTP Status Code: $rc"
  echo -e "--------------------------------------------------------"
}

# Function: Retrieve IP addresses using `dig`
get_ips_with_dig() {
  echo -e "\e[1;32m[IP Addresses from Dig]\e[0m"
  echo -e "--------------------------------------------------------"
  dig @1.1.1.1 "$domain" A +short || echo "Error retrieving IPs via dig"
  echo -e "--------------------------------------------------------"
}

# Function: Retrieve IP history from ViewDNS
get_viewdns_history() {
  echo -e "\e[1;33m[IP History from ViewDNS]\e[0m"
  echo -e "--------------------------------------------------------"
  curl -s "https://viewdns.info/iphistory/?domain=$domain" \
    -H 'Referer: https://viewdns.info/' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' | \
    grep -oP '(?<=<td>)(\d{1,3}\.){3}\d{1,3}(?=</td>)' || echo "Error retrieving IP history from ViewDNS"
  echo -e "--------------------------------------------------------"
}

# Function: Fetch IP data from FOFA (base64 encoded query)
fetch_fofa_data() {
  echo -e "\e[1;35m[FOFA Results]\e[0m"
  echo -e "--------------------------------------------------------"
  local query
  query=$(echo -n "cert.subject.cn=\"$domain\"" | base64)
  curl -s "https://en.fofa.info/result?qbase64=$query&page=1&page_size=10" | \
    grep -oP '(?<=ip=")[^"]+' || echo "Error retrieving FOFA results"
  echo -e "--------------------------------------------------------"
}

# Function: Combine and analyze results
analyze_results() {
  echo -e "\e[1;36m[Consolidated Results with HTTPX]\e[0m"
  echo -e "--------------------------------------------------------"
  {
    get_ips_with_dig
    get_viewdns_history
    fetch_fofa_data
  } | tr ' ' '\n' | sort -u | httpx -silent -status-code -content-length -title || echo "Error consolidating results with HTTPX"
  echo -e "--------------------------------------------------------"
}

# Parse command-line arguments
while getopts "d:" opt; do
  case $opt in
    d) domain=$OPTARG ;;
    *) show_usage ;;
  esac
done

# Validate input
if [[ -z $domain ]]; then
  show_usage
fi

# Clear screen and execute functions
clear
banner
fetch_domain_info
get_ips_with_dig
get_viewdns_history
fetch_fofa_data
analyze_results

# Display final note
echo -e "\e[1;32m[ Done ]\e[0m"
