#!/bin/bash

# Check that both values are provided
if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <domain> <wordlist>"
        exit 1
fi

# Set Variables
DOMAIN=$1
WORDLIST_FILE=$2
DIRECTORY=${DOMAIN}_deeprecon

echo "Domain: $DOMAIN"
echo "Wordlist: $WORDLIST_FILE"

# Create the directory we're going to save Recon results to
echo "Creating directory $DIRECTORY."
mkdir $DIRECTORY

# run nmap scan on all ports looking for service versions specifically
echo "Initizalizing nmap scan..."
nmap $DOMAIN -p- -sV -A -v > $DIRECTORY/nmap_scan.nmap
echo "The results of your nmap scan is now stored in $DIRECTORY/nmap_scan.nmap"

# Declares $SERVICES variable/extracts service info from nmap scan
SERVICES=$(grep -E "^[0-9]+/" "$DIRECTORY/nmap_scan.nmap" | awk '{print $4}' | sort -u)

echo "Services found: $SERVICES"
# For loop which runs the search for services extracted above through exploitdb. 
for SERVICE in $SERVICES; do
        echo "Searching exploitdb for $SERVICE..."

        SEARCH_RESULTS=$(searchsploit "$SERVICE")

        # Check if SEARCH_RESULTS came back empty
        if [ -z "$SEARCH_RESULTS" ]; then
            echo "No exploits found for services"
        else

        # Save the search results to a file
           echo "$SEARCH_RESULTS" > "$DIRECTORY/exploitdb_search_$SERVICE.txt"
           echo "Results saved to $DIRECTORY/exploitdb_search_$SERVICE.txt"
        fi
done

# Dnsenum scan
echo "Initizalizing DNS Enumeration..."
dnsenum -enum --noreverse $DOMAIN > $DIRECTORY/dnsenumscan
echo "DNS enumeration complete, results saved to $DIRECTORY/dnsenumscan"

# Assetfinder scan
echo "Initializing Assetfinder scan..."
assetfinder $DOMAIN > $DIRECTORY/assetfinderscan
echo "Assetfinder scan complete, results saved to $DIRECTORY/assetfinderscan"

# Ffuf scan using wordlist
echo "Initializing Web Directory Fuzz..."
ffuf -w "$WORDLIST_FILE" -t 2 -u http://"$DOMAIN"/FUZZ > $DIRECTORY/fuzzed

echo "Web directory fuzz complete, results saved to $DIRECTORY/fuzzed"
echo "Deep Recon complete"
