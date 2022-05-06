import Result "mo:base/Result";
import ExtCore "./Core";
import ExtArchive "./Archive";
import ExtLedger "./Ledger";
import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";

module ExtWrapper = {

    public type BlockIndex = Nat64;

    public type WrapType = {
        #wrap;
        #unwrap;
    };

    public type WrapRecord = {
        index: Nat;
        wrapType: WrapType;
        date: ExtArchive.Date;
        from: ExtCore.AccountIdentifier;
        to: ExtCore.AccountIdentifier;
        amount: ExtCore.Balance;
        blockHeight: ExtLedger.BlockHeight;
    };

    public type MintRequest = {
        to : ExtCore.User;
        blockHeight : ExtLedger.BlockHeight;
    };

    public type WithdrawRequest = {
        to : ExtCore.User;
        amount : ExtCore.Balance;
    };

    public type WrapRequest = {
        offset: ?Nat;
        limit: ?Nat;
        user: ?ExtCore.User;
        index: ?Nat;
    };

    public type ValidActor = actor {
        mint: shared (request : MintRequest) -> async Result.Result<Bool, ExtCore.CommonError>;
            
        withdraw: shared (request : WithdrawRequest) -> async Result.Result<ExtLedger.BlockHeight, ExtCore.CommonError>;

        wraps : query (request : WrapRequest) -> async Result.Result<[WrapRecord], ExtCore.CommonError>;
    };
};