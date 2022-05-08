#!/bin/bash
dfx deploy --network=ic wicp --argument="(\"Wrapped ICP\", \"WICP\", 8, 0, principal \"$(dfx identity get-principal)\")"