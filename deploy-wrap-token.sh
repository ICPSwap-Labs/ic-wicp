#!/bin/bash
cp -R ./dfx.json ./dfx_temp.json

cat <<< $(jq '.canisters={ wicp: .canisters.wicp }' dfx.json) > dfx.json

dfx identity use icpswap-v2

# dfx deploy wicp --argument="(\"Wrapped ICP\", \"WICP\", 8, 100000000000000000, principal \"$(dfx identity get-principal)\")"
dfx deploy --wallet=yudqc-5aaaa-aaaak-aacrq-cai --network=ic wicp --argument="(\"Wrapped ICP\", \"WICP\", 8, 100000000000000000, principal \"$(dfx identity get-principal)\")"

rm ./dfx.json

cp -R ./dfx_temp.json ./dfx.json

rm ./dfx_temp.json

