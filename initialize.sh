#!/bin/bash

set -e

NETWORK="$1"

SOROBAN_RPC_HOST="$2"

if [[ -f "./.soroban/contracts/million" ]]; then
  echo "Found existing '.soroban/contracts' directory; already initialized."
  exit 0
fi

if [[ -f "./target/bin/soroban" ]]; then
  echo "Using soroban binary from ./target/bin"
elif command -v soroban &> /dev/null; then
  echo "Using soroban cli"
else
  echo "Soroban not found, install soroban cli"
  cargo install_soroban
fi

if [[ "$SOROBAN_RPC_HOST" == "" ]]; then
  if [[ "$NETWORK" == "futurenet" ]]; then
    SOROBAN_RPC_HOST="https://rpc-futurenet.stellar.org"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  elif [[ "$NETWORK" == "testnet" ]]; then
    SOROBAN_RPC_HOST="https://soroban-testnet.stellar.org"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
  else
     # assumes standalone on quickstart, which has the soroban/rpc path
    SOROBAN_RPC_HOST="http://localhost:8000"
    SOROBAN_RPC_URL="$SOROBAN_RPC_HOST/soroban/rpc"
  fi
else 
  SOROBAN_RPC_URL="$SOROBAN_RPC_HOST"
fi

case "$1" in
futurenet)
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Future Network ; October 2022"
  ;;
testnet)
  echo "Using Testnet network with RPC URL: $SOROBAN_RPC_URL"
  SOROBAN_NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
  ;;
standalone)
  SOROBAN_NETWORK_PASSPHRASE="Standalone Network ; February 2017"
  ;;
*)
  echo "Usage: $0 standalone|futurenet|testnet [rpc-host]"
  exit 1
  ;;
esac

echo "Using $NETWORK network"
echo "  RPC URL: $SOROBAN_RPC_URL"

echo Add the $NETWORK network to cli client
soroban config network add \
  --rpc-url "$SOROBAN_RPC_URL" \
  --network-passphrase "$SOROBAN_NETWORK_PASSPHRASE" "$NETWORK"

#echo "Add $NETWORK to shared config"
#echo "{ \"network\": \"$NETWORK\", \"rpcUrl\": \"$SOROBAN_RPC_URL\", \"networkPassphrase\": \"$SOROBAN_NETWORK_PASSPHRASE\" }" > ./src/shared/config.json

if !(soroban config identity ls | grep token-admin 2>&1 >/dev/null); then
  echo "Create the token-admin identity"
  soroban config identity generate token-admin --network $NETWORK
fi

if !(soroban config identity ls | grep user 2>&1 >/dev/null); then
  echo "Create the user identity"
  soroban config identity generate user --network $NETWORK
fi

# This will fail if the account already exists, but it'll still be fine.
echo "Fund token-admin & user accounts from friendbot"
soroban config identity fund token-admin --network $NETWORK
soroban config identity fund user --network $NETWORK

ARGS="--network $NETWORK --source token-admin"

NATIVE_ID="$(soroban lab token id --network $NETWORK --source token-admin --asset native &)"
echo "Native token with ID: $NATIVE_ID"

WASM_PATH="./target/wasm32-unknown-unknown/release/"
MLH_CONTRACT_PATH=$WASM_PATH"soroban_mlh_contract"
MLH_MARKETPLACE_PATH=$WASM_PATH"soroban_mlh_marketplace"

# Compiles the smart contracts and stores WASM files in ./target/wasm32-unknown-unknown/release
echo "Build contracts"
soroban contract build
echo "Optimizing contracts"
soroban contract optimize --wasm $MLH_CONTRACT_PATH".wasm"
# soroban contract optimize --wasm $MLH_MARKETPLACE_PATH".wasm"

# Deploys the contracts and stores the contract IDs in .soroban

# Deploy the mlh contract
echo "Deploy the mlh contract"
MLH_ID="$(
  soroban contract deploy \
    $ARGS \
    --wasm $MLH_CONTRACT_PATH".optimized.wasm"
)"
echo "Contract deployed succesfully with ID: $MLH_ID"

# Initialize the contracts
echo "Initializing the mlh contract"
soroban contract invoke \
	$ARGS \
	--id $MLH_ID \
	-- \
	initialize \
	--admin token-admin \
	--asset $NATIVE_ID \
	--price 2560000000

# Installing the mlh contract
echo "Installing the mlh contract to get hash"
MLH_HASH="$(
	soroban contract install \
    $ARGS \
    --wasm $MLH_CONTRACT_PATH".optimized.wasm"
)"

# Upgrading the contracts
echo "Upgrading the mlh contract"
soroban contract invoke \
  $ARGS \
  --id $MLH_ID \
  -- \
  upgrade \
  --wasm_hash $MLH_HASH

# Contract total supply
TOTAL_SUPPLY="$(soroban contract invoke $ARGS --id $MLH_ID -- total_supply)"
echo "Total supply of mlh contract is $TOTAL_SUPPLY"

# Minting to token admin
# echo "Minting to user"
# soroban contract invoke --network $NETWORK --source user --id $MLH_ID -- mint --to user --x 0 --y 0

# Extending the contracts
echo "Extending the mlh contract"
soroban contract extend \
	$ARGS \
	--id $MLH_ID \
	--ledgers-to-extend 100000 \
	--durability persistent

#soroban contract invoke $ARGS --id $MLH_ID -- -h

# Binding the contracts
echo "Generate binding contracts"
soroban contract bindings typescript \
	--network $NETWORK \
	--id $MLH_ID \
	--wasm $MLH_CONTRACT_PATH".optimized.wasm" \
	--output-dir ./.soroban/contracts/million \
	--overwrite

echo "Done"
