forge create TokenStakingRewards \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $TREND_TOKEN_CONTRACT \
--verify \
--etherscan-api-key $API_KEY