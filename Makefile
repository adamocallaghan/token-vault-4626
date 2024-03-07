-include .env

# === DEPLOY TOKEN & MINT TO USERS ===
deploy-layers-token:
	forge create src/LayersToken.sol:LayersToken --private-key $(DEPLOYER_PK)

mint-layers-tokens-to-deployer:
	cast send $(LAYERS_TOKEN) "mint(address,uint256)" $(DEPLOYER_ADDRESS) 123000000 --private-key $(DEPLOYER_PK)

mint-layers-tokens-to-user:
	cast send $(LAYERS_TOKEN) "mint(address,uint256)" $(USER_ADDRESS) 456000000 --private-key $(DEPLOYER_PK)

check-user-token-balance:
	cast call $(LAYERS_TOKEN) "balanceOf(address)(uint256)" $(USER_ADDRESS)

# === DEPLOY VAULT ===
deploy-token-vault:
	forge create src/TokenVault.sol:TokenVault --constructor-args $(LAYERS_TOKEN) $(VAULT_TOKEN_NAME) $(VAULT_TOKEN_SYMBOL) --private-key $(DEPLOYER_PK)

# == TOKEN APPROVAL & TOKEN DEPOSIT ===
approve-vault-to-spend-user-tokens:
	cast send $(LAYERS_TOKEN) "approve(address,uint256)" $(TOKEN_VAULT_ADDRESS) 432000000 --private-key $(USER_PK)

deposit-assets-from-user:
	cast send $(TOKEN_VAULT_ADDRESS) "_deposit(uint256)" 111000000 --private-key $(USER_PK)

# === CHECK ASSETS & SHARES ===
get-total-assets-in-vault:
	cast call $(TOKEN_VAULT_ADDRESS) "totalAssets()(uint256)"

get-total-assets-user-possesses:
	cast call $(TOKEN_VAULT_ADDRESS) "totalAssetsOfUser(address)(uint256)" $(USER_ADDRESS)

get-assets-deposited-mapping-value-for-user:
	cast call $(TOKEN_VAULT_ADDRESS) "assetsDeposited(address)(uint256)" $(USER_ADDRESS)

# === 4626 IN ACTION ===

preview-redeem:
	cast call $(TOKEN_VAULT_ADDRESS) "previewRedeem(uint256)(uint256)" 10000