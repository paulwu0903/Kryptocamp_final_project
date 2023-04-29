forge create MasterTreasury \
--rpc-url=$RPC_URL \
--private-key=$PRIVATE_KEY \
--constructor-args [0x81f46b132424aB6fde3943b352A6Fb17eb37Bc82,0x07447e37ac263d25661902b1027443a0Eac87A52,0x665E0998e82F0293103C4331534Fd346e270FEc3,0xe09b050E3dC9c7d7DaEa37D96637e2EA988c99CD] $UNISWAP_INVEST_CONTRACT $TREND_MASTER_NFT_CONTRACT \
--verify \
--etherscan-api-key $API_KEY