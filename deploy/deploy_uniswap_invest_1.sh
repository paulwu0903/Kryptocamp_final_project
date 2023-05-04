forge create UniswapV2Invest \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args $UNISWAP_ROUTE_CONTRACT $UNISWAP_FACTORY_CONTRACT $TREND_TOKEN_CONTRACT \
--verify \
--etherscan-api-key $API_KEY