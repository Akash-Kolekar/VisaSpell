-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network scroll-sepolia,$(ARGS)),--network scroll-sepolia)
	NETWORK_ARGS := --rpc-url $(SCROLL_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(SCROLLSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network vanguard-vanar,$(ARGS)),--network vanguard-vanar)
	NETWORK_ARGS := --rpc-url $(VANGUARD_RPC_URL) --private-key $(PRIVATE_KEY) --slow --optimize true --optimizer-runs 10000 --broadcast --legacy -vvvv
endif

deploy:
	@forge script script/DeploySVS.s.sol:DeploySVS $(NETWORK_ARGS)

deployOthers:
	@forge script script/DeployOtherSC.s.sol:DeployOtherSC $(NETWORK_ARGS)

