#!/bin/bash

EASYRSADIR="/etc/openvpn/easy-rsa/2.0"
client=$1
password=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 clientname password"
    exit 1
fi

cd "${EASYRSADIR}"
if [ ! -e keys/$client.key ]; then
    echo "No keys/$client.key exists."    
    echo "Generating keys..."
    . vars
    ./pkitool $client
    echo "...keys generated."
else
    echo "keys/$client.key already exists."
    echo "Doing nothing."
fi

zipfile=keys/$client.zip

if [ ! -e $zipfile ]; then
    echo "No zip file keys/$client.zip exists."
    echo "Creating zip file..."
    tmpdir=$(mktemp -d) || exit 1
    echo "Inlining keys..."
    cp company.ovpn $tmpdir
    sed -e "/# ca.crt blob/ {r keys/ca.crt" -e 'd}' \
	-i $tmpdir/company.ovpn
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
	keys/$client.crt > $tmpdir/$client.crt
    sed -e "/# client1.crt blob/ {r $tmpdir/$client.crt" -e 'd}' \
	-i $tmpdir/company.ovpn
    sed -e "/# client1.key blob/ {r keys/$client.key" -e 'd}' \
	-i $tmpdir/company.ovpn
    echo "..inlining completed."
    zip -j --password $password $zipfile $tmpdir/company.ovpn
    echo "..zip file created."
    rm -rf $tmpdir
else
    echo "Zip file keys/$client.zip already exists."
    echo "Doing nothing."
fi
