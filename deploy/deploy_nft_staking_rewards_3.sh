forge create NFTStakingRewards \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $TREND_MASTER_NFT_CONTRACT $TREND_TOKEN_CONTRACT \
--verify \
--etherscan-api-key $API_KEY