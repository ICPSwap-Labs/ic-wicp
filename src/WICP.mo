import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import List "mo:base/List";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import SHA256 "mo:sha256/SHA256";
import Prim "mo:⛔";
import PrincipalUtils "mo:ic-commons/PrincipalUtils";
import NatUtils "mo:ic-commons/NatUtils";
import TextUtils "mo:ic-commons/TextUtils";
import CollectionUtils "mo:ic-commons/CollectUtils";
import Types "./ext/Types";
import AID "./utils/AccountIdentifier";
import ExtCore "./ext/Core";
import ExtCommon "./ext/Common";
import ExtAllowance "./ext/Allowance";
import ExtFungible "./ext/Fungible";
import ExtFee "./ext/Fee";
import ExtArchive "./ext/Archive";
import ExtTransactions "./ext/Transactions";
import ExtHolders "./ext/Holders";
import ExtLogo "./ext/Logo";
import ExtBlock "./ext/Block";
import ExtLedger "./ext/Ledger";
import ExtWrapper "./ext/Wrapper";

shared(msg) actor class WICP(init_name: Text, init_symbol: Text, init_decimals: Nat8, init_supply: ExtCore.Balance, init_owner: Principal) = this {
    
    type AccountIdentifier = ExtCore.AccountIdentifier;
    type SubAccount = ExtCore.SubAccount;
    type User = ExtCore.User;
    type Balance = ExtCore.Balance;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type Extension = ExtCore.Extension;
    type CommonError = ExtCore.CommonError;
    type Metadata = ExtCommon.Metadata;
    type BalanceRequest = ExtCore.BalanceRequest;
    type BalanceResponse = ExtCore.BalanceResponse;
    type TransferRequest = ExtCore.TransferRequest;
    type TransferResponse = ExtCore.TransferResponse;
    type AllowanceRequest = ExtAllowance.AllowanceRequest;
    type ApproveRequest = ExtAllowance.ApproveRequest;
    type Transaction = ExtTransactions.Transaction;
    type TransactionRequest = ExtTransactions.TransactionRequest;
    type TransType = ExtTransactions.TransType;
    type HoldersRequest = ExtHolders.HoldersRequest;
    type Holder = ExtHolders.Holder;

    type BlockHeight = ExtLedger.BlockHeight;
    type ILedger = ExtLedger.ValidActor;
    type BlockResult = ExtBlock.BlockResult;
    type IBlock = ExtBlock.ValidActor;
    type WrapType = ExtWrapper.WrapType;
    type WrapRecord = ExtWrapper.WrapRecord;
    type MintRequest = ExtWrapper.MintRequest;
    type WithdrawRequest = ExtWrapper.WithdrawRequest;
    type WrapRequest = ExtWrapper.WrapRequest;

    private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/allowance", "@ext/fee", "@ext/transactions", "@ext/holders", "@ext/logo", "@ext/wrapper"];
    private let NULL_ACCOUNT : AccountIdentifier = "0000000000000000000000000000000000000000000000000000000000000000";

    private stable var owner : Principal = init_owner;
    private stable var ownerAccount : AccountIdentifier = PrincipalUtils.toAddress(owner); 
    private stable var decimals : Nat8 = init_decimals;
    private stable var symbol : Text = init_symbol;
    private stable var totalSupply : Balance = init_supply;
    private stable var blackHole : AccountIdentifier = PrincipalUtils.toAddress(Principal.fromText("aaaaa-aa"));
    private stable var feeTo : Principal = owner;
    private stable var feeToAccount : AccountIdentifier = PrincipalUtils.toAddress(feeTo); 
    private stable var transFee : Nat = 0;
    private stable var tokenLogo : Text = "";
    
    private stable var balanceEntries : [(AccountIdentifier, Nat)] = [];
    private stable var allowanceEntries : [(AccountIdentifier, [(AccountIdentifier, Nat)])] = [];
    private stable var index : Nat = 0;


    private var balances : HashMap.HashMap<AccountIdentifier, Nat> = HashMap.HashMap<AccountIdentifier, Nat>(1, Text.equal, Text.hash);
    private var allowances : HashMap.HashMap<AccountIdentifier, HashMap.HashMap<AccountIdentifier, Nat>> = HashMap.HashMap<AccountIdentifier, HashMap.HashMap<AccountIdentifier, Nat>>(1, Text.equal, Text.hash);
    private var txs : Buffer.Buffer<Transaction> = Buffer.Buffer<Transaction>(0);
    private stable var txsArr : [Transaction] = [];

    private stable var blocks : List.List<BlockHeight> = List.nil<BlockHeight>();
    private stable var wrapArray : [WrapRecord] = [];
    private var wraps : Buffer.Buffer<WrapRecord> = Buffer.Buffer<WrapRecord>(0);
    private stable var wrapIndex : Nat = 0;
    private stable var wrapTxIndex : Nat64 = 1;
    private let WRAPPED_ICP_THRESHOLD : Balance = 20_000;
    private let WRAPPED_ICP_FEE : Balance = 10_000;
    private let BLOCK_CANISTER_ID : Text = "4hw4x-jyaaa-aaaah-aa6qa-cai";
    private let LEDGER_CANISTER_ID : Text = "ryjl3-tyaaa-aaaaa-aaaba-cai";

    private stable let METADATA : Metadata = #fungible({
        name = init_name;
        symbol = init_symbol;
        decimals = init_decimals;
        metadata = null;
        ownerAccount = ownerAccount;
    });
    

    private func _transactionHash(_type: Text, from: Text, to: Text, value: Nat, timestamp: Int) : Text {
        let text : Text = "type=" # _type # ", from=" # from # ", to=" # to # ", value=" # Nat.toText(value) # ", timestamp=" # Int.toText(timestamp);
        var buffer : Buffer.Buffer<Nat8> = Buffer.Buffer<Nat8>(0);
        for (char in text.chars()) {
            for (n in NatUtils.nat32ToNat8Arr(Char.toNat32(char)).vals()) {
                buffer.add(n);
            };
        };
        var arr : [Nat8] = buffer.toArray();
        let digest : SHA256.Digest = SHA256.Digest();
        digest.write(arr);
        var hashBytes: [Nat8] = CollectionUtils.arrayRange(digest.sum(), 0, 32);
        
        if (hashBytes.size() < 32) {
            buffer.clear();
            for (h in hashBytes.vals()) {
                buffer.add(h);
            };
            for (i in Iter.range(hashBytes.size(), 32)) {
                buffer.add(0);
            };
            hashBytes := buffer.toArray();
        };
        return TextUtils.encode(hashBytes);
    };

    private func _chargeFee(from: AccountIdentifier, transFee: Nat) {
        if(transFee > 0) {
            _transfer(from, feeToAccount, transFee, null);
        };
    };

    private func _transfer(from: AccountIdentifier, to: AccountIdentifier, value: Nat, nonce: ?Nat) {
        let fromBalance : Nat = _balanceOf(from);
        let fromBalanceNew : Nat = fromBalance - value;
        if (fromBalanceNew != 0) { balances.put(from, fromBalanceNew); }
        else { balances.delete(from); };

        let toBalance : Nat = _balanceOf(to);
        let toBalanceNew : Nat = toBalance + value;
        if (toBalanceNew != 0) { balances.put(to, toBalanceNew); };
    };

    private func _balanceOf(who: AccountIdentifier) : Nat {
        switch (balances.get(who)) {
            case (?balance) { return balance; };
            case (_) { return 0; };
        }
    };

    private func _allowance(owner: AccountIdentifier, spender: AccountIdentifier) : Nat {
        switch(allowances.get(owner)) {
            case (?allowanceOwner) {
                switch(allowanceOwner.get(spender)) {
                    case (?allowance) { return allowance; };
                    case (_) { return 0; };
                }
            };
            case (_) { return 0; };
        }
    };

    private func _addTx(_transType: TransType, _index: Nat, _from: AccountIdentifier, _to: AccountIdentifier, _amount: Balance, _fee: Balance, _memo: ?Blob) {
        let _timestamp : Int = Time.now();
        let _hash : Text = _transactionHash(switch (_transType) {
            case (#approve) { "approve" };
            case (#transfer) { "transfer" };
            case (#mint) { "mint" };
            case (#burn) { "burn" };
        }, _from, _to, _amount, _timestamp);
        txs.add({
            index = _index;
            from = _from;
            to = _to;
            amount = _amount;
            fee = _fee;
            timestamp = _timestamp;
            hash = _hash;
            memo = _memo;
            status = "Completed";
            transType = _transType;
        });
    };

    public query func extensions() : async [Extension] {
        EXTENSIONS;
    };

    public query func metadata(): async Result.Result<Metadata, CommonError> {
        return #ok(METADATA);
    };

    public query func supply(): async Result.Result<Balance, CommonError> {
        return #ok(totalSupply);
    };

    public query func balance(request : BalanceRequest) : async BalanceResponse {
        let aid : AccountIdentifier = ExtCore.User.toAID(request.user);
        return #ok(_balanceOf(aid));
    };

    public shared(msg) func approve(request: ApproveRequest) : async Result.Result<Bool, CommonError> {
        let owner : AccountIdentifier = AID.fromPrincipal(msg.caller, request.subaccount);
        if(_balanceOf(owner) < transFee) { 
            return #err(#InsufficientBalance);
        };
        let spender: AccountIdentifier = AID.fromPrincipal(request.spender, null);
        _chargeFee(owner, transFee);
        let value : Nat = request.allowance;
        let v : Nat = value + transFee;
        if (value == 0 and Option.isSome(allowances.get(owner))) {
            let allowanceCaller = Types.unwrap(allowances.get(owner));
            allowanceCaller.delete(spender);
            if (allowanceCaller.size() == 0) { allowances.delete(owner); }
            else { allowances.put(owner, allowanceCaller); };
        } else if (value != 0 and Option.isNull(allowances.get(owner))) {
            var temp = HashMap.HashMap<AccountIdentifier, Nat>(1, Text.equal, Text.hash);
            temp.put(spender, v);
            allowances.put(owner, temp);
        } else if (value != 0 and Option.isSome(allowances.get(owner))) {
            let allowanceCaller = Types.unwrap(allowances.get(owner));
            allowanceCaller.put(spender, v);
            allowances.put(owner, allowanceCaller);
        };
        _addTx(#approve, index, owner, spender, value, transFee, null);
        index := index + 1;
        return #ok(true);
    };

    public query func allowance(request: AllowanceRequest) : async Result.Result<Balance, CommonError> {
        let owner : AccountIdentifier = ExtCore.User.toAID(request.owner);
        let spender : AccountIdentifier = AID.fromPrincipal(request.spender, null);
        return #ok(_allowance(owner, spender));
    };

    public shared(msg) func transfer(request : TransferRequest): async TransferResponse {
        let from : AccountIdentifier = ExtCore.User.toAID(request.from);
        let to : AccountIdentifier = ExtCore.User.toAID(request.to);
        let caller : AccountIdentifier = AID.fromPrincipal(msg.caller, request.subaccount);
        let value : Nat = request.amount;
        if (AID.equal(from, caller) == false) {
          return #err(#Unauthorized(caller));
        };
        if (_balanceOf(from) < value + transFee) { 
            return #err(#InsufficientBalance); 
        };
        _chargeFee(from, transFee);
        _transfer(from, to, value, request.nonce);
        index := index + 1;
        _addTx(#transfer, index - 1, from, to,  value, transFee, Option.make(request.memo));
        return #ok(value + transFee);
    };

    public shared(msg) func transferFrom(request : TransferRequest) : async TransferResponse {
        let from : AccountIdentifier = ExtCore.User.toAID(request.from);
        let to : AccountIdentifier = ExtCore.User.toAID(request.to);
        let caller : AccountIdentifier = AID.fromPrincipal(msg.caller, request.subaccount);
        let value : Nat = request.amount;        

        if (_balanceOf(from) < value + transFee) { 
            return #err(#InsufficientBalance); 
        };
        let allowed : Nat = _allowance(from, caller);
        if (allowed < value + transFee) { 
            return #err(#InsufficientAllowance); 
        };

        _chargeFee(from, transFee);
        _transfer(from, to, value, request.nonce);

        let allowedNew : Nat = allowed - value - transFee;
        if (allowedNew != 0) {
            let allowanceFrom = Types.unwrap(allowances.get(from));
            allowanceFrom.put(caller, allowedNew);
            allowances.put(from, allowanceFrom);
        } else {
            if (allowed != 0) {
                let allowanceFrom = Types.unwrap(allowances.get(from));
                allowanceFrom.delete(caller);
                if (allowanceFrom.size() == 0) { allowances.delete(from); }
                else { allowances.put(from, allowanceFrom); };
            };
        };
        index := index + 1;
        _addTx(#transfer, index - 1, from, to,  value, transFee, Option.make(request.memo));
        return #ok(value + transFee);
    };

    public shared(msg) func mint(request : MintRequest): async Result.Result<Bool, ExtCore.CommonError> {
        let callerAddress : AccountIdentifier = PrincipalUtils.toAddress(msg.caller);
        let blockStorage : IBlock = actor(BLOCK_CANISTER_ID): IBlock;
        let blockResult : BlockResult = await blockStorage.getBlock(request.blockHeight);
        switch (blockResult) {
            case (#Ok(blockInfo)) {
                let from : AccountIdentifier = blockInfo.from;
                let to : AccountIdentifier = blockInfo.to;
                let amount : Nat = Nat64.toNat(blockInfo.amount.e8s);

                if (callerAddress != from) {
                    return #err(#Unauthorized(callerAddress));
                };

                let wicpCanisterAddress : AccountIdentifier = PrincipalUtils.toAddress(Principal.fromActor(this));
                if (wicpCanisterAddress != to) {
                    return #err(#Other("error_to_address"));
                };

                if (List.some<BlockHeight>(blocks, func (usedBlockHeight: BlockHeight): Bool {
                    return usedBlockHeight == request.blockHeight;
                })) {
                    return #err(#Other("used_block_height"));
                };

                blocks := List.push<BlockHeight>(request.blockHeight, blocks);
                _mint(PrincipalUtils.toAddress(Principal.fromActor(this)), callerAddress, amount, request.blockHeight);
                return #ok(true);
            };
            case (#Err(code)) {
                return #err(#Other("block_error"));
            };
        };
    };

    private func _mint(from : AccountIdentifier, to : AccountIdentifier, amount : Nat, blockHeight : BlockHeight) : () {
        var toBalanceNew : Nat = switch (balances.get(to)) {
            case (?toBalance) {
                toBalance + amount;
            };
            case (_) {
                amount;
            };
        };
        totalSupply += amount;
        if (toBalanceNew > 0) {
            balances.put(to, toBalanceNew);
        };
        _addWrap(#wrap, from, to, amount, blockHeight);
        _addTx(#mint, index, NULL_ACCOUNT, to, amount, 0, null);
        index += 1;
    };

    public shared(msg) func withdraw(request : WithdrawRequest): async Result.Result<BlockHeight, ExtCore.CommonError> {
        let callerAddress : AccountIdentifier = PrincipalUtils.toAddress(msg.caller);
        switch (balances.get(callerAddress)) {
            case (?callerBalance) {
                if (callerBalance < request.amount) {
                   return #err(#InsufficientBalance); 
                };

                if (request.amount < WRAPPED_ICP_THRESHOLD) {
                    return #err(#Other("amount_too_small"));
                };

                var newBalance: Nat = callerBalance - request.amount;
                if (newBalance > 0) {
                    balances.put(callerAddress, newBalance);
                } else {
                    balances.delete(callerAddress);
                };

                let transferAmount : Nat64 = Nat64.fromNat(request.amount - WRAPPED_ICP_FEE);

                let ledger : ILedger = actor(LEDGER_CANISTER_ID): ILedger;
                let res : ExtLedger.TransferResult = await ledger.transfer({
                    memo = wrapTxIndex;
                    to = ExtLedger.accountIdentifier(msg.caller, ExtLedger.defaultSubaccount());
                    amount = {
                        e8s = transferAmount;
                    };
                    fee = {
                        e8s = Nat64.fromNat(WRAPPED_ICP_FEE);
                    };
                    from_subaccount = null;
                    created_at_time = null;
                });
                switch (res) {
                    case (#Ok(blockIndex)) {
                        _withdraw(callerAddress, PrincipalUtils.toAddress(Principal.fromActor(this)), request.amount, blockIndex);
                        wrapTxIndex += 1;
                        return #ok(blockIndex);
                    };
                    case (#Err(#InsufficientFunds { balance })) {
                        balances.put(callerAddress, callerBalance);
                        return #err(#InsufficientBalance);
                    };
                    case (#Err(other)) {
                        balances.put(callerAddress, callerBalance);
                        return #err(#Other("unexpected_error"));
                    };
                };
            };
            case (_) {
                return #err(#InsufficientBalance);
            };
        };
    };

    private func _withdraw(from : AccountIdentifier, to : AccountIdentifier, amount : Balance, blockHeight : BlockHeight) : () {
        if (totalSupply < amount) {
            totalSupply := 0;
        } else {
            totalSupply -= amount;
        };
        _addWrap(#unwrap, from, to, amount - WRAPPED_ICP_FEE, blockHeight);
        _addTx(#burn, index, from, NULL_ACCOUNT, amount, 0, null);
        index += 1;
    };

    private func _addWrap(wrapType : WrapType, from : AccountIdentifier, to : AccountIdentifier, amount : Balance, blockHeight : BlockHeight) : () {
        let wrapRecord : WrapRecord = {
            index = wrapIndex;
            wrapType = wrapType;
            date = Prim.time();
            from = from;
            to = to;
            amount = amount;
            blockHeight = blockHeight;
        };

        wraps.add(wrapRecord);
        wrapIndex += 1;
    };

    public shared(msg) func wrappedTx(request : WrapRequest): async Result.Result<ExtCommon.Page<WrapRecord>, ExtCore.CommonError> {
        var buffer : Buffer.Buffer<WrapRecord> = Buffer.Buffer<WrapRecord>(0);
        var _offset : Nat = Option.get(request.offset, 0);
        var _limit : Nat = Option.get(request.limit, 0);
        let size : Nat = wraps.size();
        var index : Nat = 0;
        var i : Nat = size;
        var total : Nat = 0;
        while (i > 0) {
            i -= 1;
            let wrap : WrapRecord = wraps.get(i);
            if (Option.isSome(request.index)) {
                if (Option.get(request.index, 0) == wrap.index) {
                    return #ok({
                        totalElements = 1;
                        offset = 0;
                        limit = 1;
                        content = [wrap];
                    });
                };
            } else if (Option.isSome(request.user)) {
                if (_wrapFilter(wrap, request.user)) {
                    if (_limit == 0 or (index >= _offset and buffer.size() < _limit)) {
                        buffer.add(wrap);
                    };
                    index += 1;
                    total += 1;
                };
            } else {
                if (_limit == 0 or (index >= _offset and buffer.size() < _limit)) {
                    buffer.add(wrap);
                } else if (_limit > 0 and index >= _offset + _limit) {
                    i := 0;
                };
                index += 1;
                total := size;
            }
        };
        return #ok({
            totalElements = total;
            offset = _offset;
            limit = _limit;
            content = buffer.toArray();
        });
    };

    private func _wrapFilter(item: WrapRecord, user: ?User): Bool {
        switch(user) {
            case (?u) {
                let aid = ExtCore.User.toAID(u);
                if (aid == item.from or aid == item.to) {
                    return true;
                } else {
                    return false;
                };
            };
            case null {
                return true;
            }
        };
    };

    public query func getFee() : async Result.Result<Balance, CommonError> {
        return #ok(transFee);
    };
    
    public shared(msg) func setFee(_fee: Balance): async Result.Result<Bool, CommonError> {
        if(msg.caller != owner) {
            return #err(#Unauthorized(AID.fromPrincipal(msg.caller, null)));
        };
        transFee := _fee;
        return #ok(true);
    };

    public shared(msg) func setFeeTo(user: User): async Result.Result<Bool, CommonError> {
        if(msg.caller != owner) {
            return #err(#Unauthorized(AID.fromPrincipal(msg.caller, null)));
        };
        feeToAccount := ExtCore.User.toAID(user);
        return #ok(true);
    };

    public query func logo() : async Result.Result<Text, CommonError> {
        return #ok(tokenLogo);
    };
    
    public shared(msg) func setLogo(_logo: Text): async Result.Result<Bool, CommonError> {
        if(msg.caller != owner) {
            return #err(#Unauthorized(AID.fromPrincipal(msg.caller, null)));
        };
        tokenLogo := _logo;
        return #ok(true);
    };

    private func _filter(item: Transaction, user: ?User): Bool {
        switch(user) {
            case (?u) {
                let aid = ExtCore.User.toAID(u);
                if (aid == item.from or aid == item.to) {
                    return true;
                } else {
                    return false;
                };
            };
            case null {
                return true;
            }
        };
    };

    public query func transactions(request : TransactionRequest): async Result.Result<ExtCommon.Page<Transaction>, ExtCore.CommonError> {
        var buffer : Buffer.Buffer<Transaction> = Buffer.Buffer<Transaction>(0);
        var _offset : Nat = Option.get(request.offset, 0);
        var _limit : Nat = Option.get(request.limit, 0);
        let size : Nat = txs.size();
        var index : Nat = 0;
        var i : Nat = size;
        var total : Nat = 0;
        while (i > 0) {
            i -= 1;
            let tx: Transaction = txs.get(i);
            if (Option.isSome(request.index)) {
                if (Option.get(request.index, 0) == tx.index) {
                    return #ok({
                        totalElements = 1;
                        offset = 0;
                        limit = 1;
                        content = [tx];
                    });
                };
            } else if (Option.isSome(request.hash)) {
                if (Option.get(request.hash, 0) == tx.hash) {
                    return #ok({
                        totalElements = 1;
                        offset = 0;
                        limit = 1;
                        content = [tx];
                    });
                };
            } else if (Option.isSome(request.user)) {
                if (_filter(tx, request.user)) {
                    if (_limit == 0 or (index >= _offset and buffer.size() < _limit)) {
                        buffer.add(tx);
                    };
                    index += 1;
                    total += 1;
                };
            } else {
                if (_limit == 0 or (index >= _offset and buffer.size() < _limit)) {
                    buffer.add(tx);
                } else if (_limit > 0 and index >= _offset + _limit) {
                    i := 0;
                };
                index += 1;
                total := size;
            }
        };
        return #ok({
            totalElements = total;
            offset = _offset;
            limit = _limit;
            content = buffer.toArray();
        });
    };

    public query func totalHolders(): async Result.Result<Nat, ExtCore.CommonError> {
        return #ok(balances.size());
    };

    public query func holders(request : HoldersRequest): async Result.Result<ExtCommon.Page<Holder>, ExtCore.CommonError>{
        var buffer : Buffer.Buffer<Holder> = Buffer.Buffer<Holder>(0);
        for ((k, v) in balances.entries()) {
            buffer.add({
                account = k;
                balance = v;
            });
        };
        var allHolders : [Holder] = Array.sort<Holder>(buffer.toArray(), func (x: Holder, y: Holder) : {#less; #equal; #greater} {
            if (y.balance < x.balance) { #less }
            else if (y.balance == x.balance) { #equal }
            else { #greater }
        });
        var i : Nat = 0;
        var _start : Nat = Option.get(request.offset, 0);
        var _limit : Nat = Option.get(request.limit, 0);
        var _end : Nat = _start + _limit;
        var holders : Buffer.Buffer<Holder> = Buffer.Buffer<Holder>(0);
        label l for (holder in allHolders.vals()) {
            if (_limit == 0 or i >= _start) {
                holders.add(holder);
            };
            i := i + 1;
            if (_limit > 0 and i >= _end) {
                break l;
            };
        };
        return #ok({
            totalElements = balances.size();
            offset = _start;
            limit = _limit;
            content = holders.toArray();
        });
    };

    public query func registry() : async [(AccountIdentifier, Balance)] {
        Iter.toArray(balances.entries());
    };

    public query func cycleBalance() : async Result.Result<Nat, CommonError> {
        return #ok(ExperimentalCycles.balance());
    };
    
    public shared(msg) func cycleAvailable() : async Result.Result<Nat, CommonError> {
        return #ok(ExperimentalCycles.available());
    };

    /*
    * upgrade functions
    */
    system func preupgrade() {
        balanceEntries := Iter.toArray(balances.entries());
        txsArr := txs.toArray();
        var size : Nat = allowances.size();
        var temp : [var (AccountIdentifier, [(AccountIdentifier, Nat)])] = Array.init<(AccountIdentifier, [(AccountIdentifier, Nat)])>(size, (ownerAccount, []));
        size := 0;
        for ((k, v) in allowances.entries()) {
            temp[size] := (k, Iter.toArray(v.entries()));
            size += 1;
        };
        allowanceEntries := Array.freeze(temp);
        wrapArray := wraps.toArray();
    };

    system func postupgrade() {
        balances := HashMap.fromIter<AccountIdentifier, Nat>(balanceEntries.vals(), 1, Text.equal, Text.hash);
        balanceEntries := [];
        for ((k, v) in allowanceEntries.vals()) {
            let allowed_temp = HashMap.fromIter<AccountIdentifier, Nat>(v.vals(), 1, Text.equal, Text.hash);
            allowances.put(k, allowed_temp);
        };
        allowanceEntries := [];
        var buffer : Buffer.Buffer<Transaction> = Buffer.Buffer<Transaction>(txsArr.size());
        for (it in txsArr.vals()) {
            buffer.add(it);
        };
        txs := buffer;
        wraps := Buffer.Buffer<WrapRecord>(wrapArray.size());
        for (wrap in wrapArray.vals()) {
            wraps.add(wrap);
        };
    };
};
