forge create TokenAirdrop \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $TREND_TOKEN_CONTRACT \
--verify \
--etherscan-api-key $API_KEY