import ExtCore "./Core";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
// module ExtFee = {
//   public type TransferRequest = {
//     from : ExtCore.User;
//     to : ExtCore.User;
//     token : ExtCore.TokenIdentifier;
//     amount : ExtCore.Balance;
//     fee : ExtCore.Balance;
//     memo : ExtCore.Memo;
//     notify : Bool;
//     subaccount : ?ExtCore.SubAccount;
//   };
//   public type Service = actor {
//     fee: (token : ExtCore.TokenIdentifier) -> async ();
//   }
// };

module ExtFee = {
  public type Service = actor {
    getFee: query () -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
    setFee: shared (fee: Nat) -> async Result.Result<Bool, ExtCore.CommonError>;
    setFeeTo: shared (ExtCore.User) -> async Result.Result<Bool, ExtCore.CommonError>;
  };
};