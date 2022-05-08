# IC-Wrapped ICP(WICP)

Wrapped ICP (WICP) is a wrapped version of the IC's native token, ICP. Each WICP will be backed 1:1 with ICP, meaning that 1 WICP will always have the exact same value as 1 ICP. The only difference is that, unlike ICP, WICP uses the EXT fungible token standard that is specifically designed to allow for interoperability between dApps and other tokens.

- [Wrapped ICP Website](https://app.icpswap.com/swap/wicp)

---

## 🧰 Interacting with Wrapped ICP (WICP) - On Mainnet (DFX)

In order to interact with the Internet Computer mainnet version of the Wrapped ICP (WICP) canister, you need the address.

- WICP Canister ID: `5xnja-6aaaa-aaaan-qad4a-cai`
- WICP Account ID: `e994ad0378bb902896b55dd5a69a72e7fb2762bba50b32f66f77d2d99d07ac94`

You have to use this address (Canister ID) to make your calls, with the exception of the Account ID during the mint.

---

### Deposit ICP to mint an WICP balance - mint

#### In command

Using the mint method is done in two steps. First, we need to make a transfer call at the ICP ledger to the WICP account ID. Using the following command you’ll be returned the block height when your transaction was approved.

```bash
dfx ledger --network ic transfer "e994ad0378bb902896b55dd5a69a72e7fb2762bba50b32f66f77d2d99d07ac94" --amount value --memo 0
```

Now that we have the blockHeight of our ICP transfer, we can call the mint method on the WICP canister.

```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai mint '(record {to=variant {principal=principal "yourPrincipalId"}; blockHeight=yourBlockHeight:nat64})'
```
```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai mint '(record {to=variant {address="yourAccountId"}; blockHeight=yourBlockHeight:nat64})'
```

#### In Website

Open ICPSwap 1.0 and come to the Wrap page. For example, enter 0.1 as follows, then click the "Wrap" button.

![wicp-mint](https://user-images.githubusercontent.com/98505086/167277778-768943f9-d44e-437a-bff5-22998db54f7a.png)

---

### Unwrap your WICP and regain a balance of ICP - withdraw

Calling withdraw unwraps your WICP, burns it, and then unlocks and sends ICP from the WICP canister to the balance of the Principal ID you specify.

#### In command

The Withdraw method takes two parameters, ‘amount’ and ‘to’. Amount is an integer that represents the amount of WICP you’d like to withdraw to ICP. To is a string that should be the Principal ID or Account ID that you wish the ICP to be transferred to.

```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai withdraw '(record {to=variant {principal=principal "yourPrincipalId"}; amount=value:nat})'
```
```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai withdraw '(record {to=variant {address="yourAccountId"}; amount=value:nat})'
```

#### In Website

the Unwarp feature is to restore the WICP to ICP, click the button as shown, exchange the WICP and ICP location, enter the WICP amount, and click the "Unwrap" button.

![wicp-unwrap-1](https://user-images.githubusercontent.com/98505086/167277962-d4e08618-a501-4c3c-b512-421692ed0175.png)
![wicp-unwrap-2](https://user-images.githubusercontent.com/98505086/167277964-c2517ff0-2c82-409a-8567-ca3345556879.png)

---

### Transfer WICP to Another WICP Balance - transfer

You can transfer WICP to any other valid Account. Your balance at the WICP ledger will be deducted and the Account you transfer to, will be incremented.

#### In Command

Transfers ‘value’ (Nat) amount of tokens to user ‘to’ (Principal or Account), returns a TransferResponse which contains the transfer amount or an error message.

```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai transfer '(record {to=variant {principal=principal "toPrincipalId"}; token="WICP"; notify=false; from=variant {principal=principal "yourPrincipalId"}; memo=vec {}; subaccount=null; nonce=1; amount=value})'
```
```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai transfer '(record {to=variant {address="toAddress"}; token="WICP"; notify=false; from=variant {address="yourAddress"}; memo=vec {}; subaccount=null; nonce=1; amount=value})'
```

#### In Website

Open ICPSwap 1.0 and come to the Wallet page. Click the Token tab, then you will find the token list. Click the transfer button of WICP, input the Account and Amount in the new window.

<img width="1409" alt="transfer-1" src="https://user-images.githubusercontent.com/98505086/167295214-ae97a2e3-13f9-4765-a0a4-23d0f134c239.png">
![transfer-2](https://user-images.githubusercontent.com/98505086/167278150-3c28c3b5-e3db-4b08-a51e-915767892ef9.png)

---

### Set an Allowance to Another Identity - approve

You can set an allowance using this method, giving a third-party access to a specific number of tokens they can withdraw from your balance if they want.

An allowance permits the ‘spender’ (Principal) to withdraw tokens from your account or your subAccount, up to the ‘value’ (Nat) amount. If it is called again it overwrites the current allowance with ‘value’ (Nat). There is no upper limit for value, you can approve a larger value than you have, but 3rd parties are still bound by the upper limit of your account balance.

```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai approve '(record {subaccount=null; allowance=value; spender=principal "toPrincipalId"})'
```

---

### Transfer WICP on Another User's Behalf - transferFrom

Transfers ‘value’ (Nat) amount of tokens from user ‘from’ (Principal or Acount) to user ‘to’ (Principal or Account), this method allows canister smart contracts to transfer tokens on your behalf, it returns a TransferResponse which contains the transfer amount or an error message.

```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai transferFrom '(record {to=variant {principal=principal "toPrincipalId"}; token="WICP"; notify=false; from=variant {principal=principal "yourPrincipalId"}; memo=vec {}; subaccount=null; nonce=1; amount=value})'
```
```bash
dfx canister --network=ic call 5xnja-6aaaa-aaaan-qad4a-cai transferFrom '(record {to=variant {address="toAddress"}; token="WICP"; notify=false; from=variant {address="yourAddress"}; memo=vec {}; subaccount=null; nonce=1; amount=value})'
```

---

### Set the fee of token - setFee

Set the fee of the token. Only the owner of the token has permission.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai setFee '(value:nat)'
```

---

### Set the account for the fee of token - setFeeTo

Set the account for the fee of the token. Only the owner of the token has permission.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai setFeeTo '(variant {principal=principal "fee-to-principal"})'
```
```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai setFeeTo '(variant {address="fee-to-address"})'
```

---

### Check your Balance - balance

Returns the balance of user `who`.

```bash
​​dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai balance '(record {token="WICP"; user=variant {principal=principal "who-principal"}})'
```
```bash
​​dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai balance '(record {token="WICP"; user=variant {address="who-address"}})'"(principal \"who-account-principal\")"
```

---

### Check the set allowance for an ID - allowance

Returns the amount which spender is still allowed to withdraw from owner.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai allowance '(record {owner=variant {principal=principal "owner-principal"}; subaccount=null; spender=principal "spender-principal"})'
```
```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai allowance '(record {owner=variant {address="owner-address"}; subaccount=null; spender=principal "spender-principal"})'
```

---

### Get the wrap transaction - wrappedTx

Returns the wrap transaction of Wrapped ICP (WICP). The ‘user’ and ‘index’ is optional.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai wrappedTx '(record {user=opt variant {principal=principal "query-principal"}; offset=opt 1; limit=opt 10; index=opt 10001})'
```
```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai wrappedTx '(record {user=opt variant {address="query-address"}; offset=opt 1; limit=opt 10; index=opt 10001})'
```

---

### Get the transfer records - transactions

Returns the transfer records of Wrapped ICP (WICP). The ‘hash’, ‘user’ and ‘index’ is optional.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai transactions '(record {hash=opt "hash-value"; user=opt variant {principal=principal "query-principal"}; offset=opt 1; limit=opt 10; index=opt 10001})'
```
```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai transactions '(record {hash=opt "hash-value"; user=opt variant {address="query-address"}; offset=opt 1; limit=opt 10; index=opt 10001})'
```

---

### Get list of holders - holders

Returns the list of the Wrapped ICP (WICP) holders.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai holders '(record {offset=opt 1; limit=opt 10})'
```

---

### Get amount of holders - totalHolders

Returns the total amount of the Wrapped ICP (WICP) holders.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai totalHolders
```

---

### Get token logo - logo

Returns the logo of Wrapped ICP (WICP).

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai logo
```

---

### Get total supply of token - supply

Returns the total supply of the token.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai supply
```

---

### Get the fee of token - getFee

Returns the fee of the token.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai getFee
```

---

### Get token’s metadata - metadata

Returns the metadata of the token.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai metadata
```

---

### Get token’s extensions - extensions

Returns the extensions of the token.

```bash
dfx canister --network=ic call --query 5xnja-6aaaa-aaaan-qad4a-cai extensions
```

---

## 🙏 Contributing

Create branches from the `main` branch and name it in accordance to **conventional commits** [here](https://www.conventionalcommits.org/en/v1.0.0/), or follow the examples bellow:

```txt
test: 💍 Adding missing tests
feat: 🎸 A new feature
fix: 🐛 A bug fix
chore: 🤖 Build process or auxiliary tool changes
docs: ✏️ Documentation only changes
refactor: 💡 A code change that neither fixes a bug or adds a feature
style: 💄 Markup, white-space, formatting, missing semi-colons...
```
