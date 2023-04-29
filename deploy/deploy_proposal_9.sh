forge create Proposal \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $TOKEN_STAKING_REWARDS_CONTRACT $TREND_MASTER_NFT_CONTRACT $TREASURY_CONTRACT $MASTER_TREASURY_CONTRACT $COUNCIL_CONTRACT \
--verify \
--etherscan-api-key $API_KEY