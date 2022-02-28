#!/bin/bash

SUBJ="/C=DE/ST=MEINZ/L=MEINZ/O=1&1n/OU=Rakuten/CN=ca.vault-primary-internal/emailAddress=helm@ca.vault-primary-internal"

SERVERS="vault-primary"

SERVERS_DR="vault-dr"

LB="vault-lb"

openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -new -x509 -key ca.key -out ca.crt -days 360 -subj "${SUBJ}"


for val in $SERVERS; do
    SUBJECTS="/C=DE/ST=MEINZ/L=MEINZ/O=1&1n/OU=Rakuten/CN=vault-primary.vault-primary-internal/emailAddress=helm@ca.vault-primary-internal"
    openssl ecparam -name prime256v1 -genkey -noout -out $val.key
    openssl req -new -key "$val".key -out "$val".csr -subj "$SUBJECTS" -addext "subjectAltName = DNS:vault-primary-0.vault-primary-internal, DNS:vault-primary-1.vault-primary-internal, DNS:vault-primary-2.vault-primary-internal, DNS:vault-primary-3.vault-primary-internal, DNS:vault-primary-4.vault-primary-internal"
    openssl x509 -req -days 360 -in "$val".csr -CA ca.crt -CAkey ca.key -CAcreateserial -CAserial ca_serial.seq -out "$val".crt
done


for val in $SERVERS_DR; do
    SUBJECTS="/C=DE/ST=MEINZ/L=MEINZ/O=1&1n/OU=Rakuten/CN=vault-dr.vault-dr-internal/emailAddress=helm@ca.vault-dr-internal"
    openssl ecparam -name prime256v1 -genkey -noout -out $val.key
    openssl req -new -key "$val".key -out "$val".csr -subj "$SUBJECTS" -addext "subjectAltName = DNS:vault-dr-0.vault-dr-internal, DNS:vault-dr-1.vault-dr-internal, DNS:vault-dr-2.vault-dr-internal"
    openssl x509 -req -days 360 -in "$val".csr -CA ca.crt -CAkey ca.key -CAcreateserial -CAserial ca_serial.seq -out "$val".crt
done

for val in $LB; do
    SUBJECTS="/C=DE/ST=MEINZ/L=MEINZ/O=1&1n/OU=Rakuten/CN=vault.rakuten.com/emailAddress=helm@vault.rakuten.com"
    openssl ecparam -name prime256v1 -genkey -noout -out $val.key
    openssl req -new -key "$val".key -out "$val".csr -subj "$SUBJECTS"
done

#kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > vault.ca
