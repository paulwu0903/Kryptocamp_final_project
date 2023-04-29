forge create Council \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $TOKEN_STAKING_REWARDS_CONTRACT $TREASURY_CONTRACT $MASTER_TREASURY_CONTRACT \
--verify \
--etherscan-api-key $API_KEY

