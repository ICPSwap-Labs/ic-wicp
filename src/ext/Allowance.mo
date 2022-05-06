import Result "mo:base/Result";
import ExtCore "./Core";
import Bool "mo:base/Bool";

module ExtAllowance = {

  public type AllowanceRequest = {
    owner : ExtCore.User;
    subaccount : ?ExtCore.SubAccount;
    spender : Principal;
  };

  public type ApproveRequest = {
    subaccount : ?ExtCore.SubAccount;
    spender : Principal;
    allowance : ExtCore.Balance;
  };

  public type ValidActor = actor {
    allowance: shared query (request : AllowanceRequest) -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;

    approve: shared (request : ApproveRequest) -> async Result.Result<Bool, ExtCore.CommonError>;

    transferFrom: shared (request : ExtCore.TransferRequest) -> async ExtCore.TransferResponse;
  };
};