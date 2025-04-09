-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil initialize-roles register-program create-application submit-documents verify-admission verify-documents approve-visa anvil-start deploy-local anvil-create-app anvil-register-program anvil-deploy anvil-register-programs anvil-create-app anvil-submit-docs anvil-verify-admission anvil-verify-docs anvil-approve anvil-upgrade anvil-full-process

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Anvil's default private keys
ANVIL_PRIVATE_KEY_0 := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ANVIL_PRIVATE_KEY_1 := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
ANVIL_PRIVATE_KEY_2 := 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
ANVIL_PRIVATE_KEY_3 := 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
ANVIL_PRIVATE_KEY_4 := 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a

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

# Start local Anvil chain
anvil-start:
	@anvil --block-time 1

# Anvil deployment scripts
anvil-deploy:
	@forge script script/anvil/1_DeployLocal.s.sol:DeployLocal --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_0) --broadcast

anvil-register-programs:
	@forge script script/anvil/2_RegisterProgram.s.sol:RegisterProgram --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_1) --broadcast

anvil-create-app:
	@forge script script/anvil/3_CreateApplication.s.sol:CreateApplication --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_4) --broadcast

anvil-submit-docs:
	@forge script script/anvil/4_SubmitDocuments.s.sol:SubmitDocuments --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_4) --broadcast

anvil-verify-admission:
	@forge script script/anvil/5_VerifyAdmission.s.sol:VerifyAdmission --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_1) --broadcast

anvil-verify-docs:
	@forge script script/anvil/6_VerifyDocuments.s.sol:VerifyDocuments --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_3) --broadcast

anvil-approve:
	@forge script script/anvil/7_ApproveVisa.s.sol:ApproveVisa --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_2) --broadcast

anvil-upgrade:
	@forge script script/anvil/8_UpgradePriority.s.sol:UpgradePriority --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY_4) --broadcast

# Full process in one command
anvil-full-process: anvil-deploy anvil-register-programs anvil-create-app anvil-submit-docs anvil-verify-admission anvil-verify-docs anvil-approve

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network scroll-sepolia,$(ARGS)),--network scroll-sepolia)
	NETWORK_ARGS := --rpc-url $(SCROLL_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(SCROLLSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network vanguard-vanar,$(ARGS)),--network vanguard-vanar)
	NETWORK_ARGS := --rpc-url $(VANGUARD_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --legacy --verify -vvvv
endif

deploy:
	@forge script script/DeploySVS.s.sol:DeploySVS $(NETWORK_ARGS)

deployPostScript:
	@forge script script/RunPostDeployment.s.sol:RunPostDeployment --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

initialize-roles:
	@forge script script/deployment/1_InitializeRoles.s.sol:InitializeRoles --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY)  --froms 0xB58634C4465D93A03801693FD6d76997C797e42A --broadcast -vvv

register-university:
	@forge script script/deployment/1.5_RegisterUniversity.s.sol:RegisterUniversity --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11 --mnemonic-derivation-paths "m/44'/60'/0'/0/0" -vvv 

register-program:
	@forge script script/deployment/2_RegisterProgram.s.sol:RegisterProgram --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11 --mnemonic-derivation-paths "m/44'/60'/0'/0/3" -vvv 

create-application:
	@forge script script/deployment/3_CreateApplication.s.sol:CreateApplication --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0xB58634C4465D93A03801693FD6d76997C797e42A --mnemonic-derivation-paths "m/44'/60'/0'/0/0" --broadcast -vvvv

submit-documents:
	@forge script script/deployment/4_SubmitDocuments.s.sol:SubmitDocuments --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0xB58634C4465D93A03801693FD6d76997C797e42A --mnemonic-derivation-paths "m/44'/60'/0'/0/0" --broadcast -vvv

verify-admission:
	@forge script script/deployment/5_VerifyAdmission.s.sol:VerifyAdmission --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11 --mnemonic-derivation-paths "m/44'/60'/0'/0/3" --broadcast -vvv

verify-documents:
	@forge script script/deployment/6_VerifyDocuments.s.sol:VerifyDocuments --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0xAF8E81e74bA006134493a92D1EAACb8686e86A93 --mnemonic-derivation-paths "m/44'/60'/0'/0/7" --broadcast -vvv

approve-visa:
	@forge script script/deployment/7_ApproveVisa.s.sol:ApproveVisa --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --froms 0xAF8E81e74bA006134493a92D1EAACb8686e86A9 --mnemonic-derivation-paths "m/44'/60'/0'/0/4" --broadcast -vvv

