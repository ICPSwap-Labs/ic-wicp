/**

//TODO need a way to retreive the correct transfer request if it has been overwritten

 */
import ExtCore "./Core";
import ExtCommon "./Common";
import Result "mo:base/Result";


module ExtHolders = {
  public type Holder = {
      account: ExtCore.AccountIdentifier;
      balance: Nat;
  };

  public type HoldersRequest = {
      offset: ?Nat;
      limit: ?Nat;
  };
  
  public type HoldersActor = actor {
      totalHolders : query () -> async Result.Result<Nat, ExtCore.CommonError>;
      holders : query (request : HoldersRequest) -> async Result.Result<ExtCommon.Page<Holder>, ExtCore.CommonError>;
  };
};