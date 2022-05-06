/**

 */
import Result "mo:base/Result";

import ExtCore "./Core";
module ExtCommon = {
  public type Page<T> = {
    totalElements: Nat;
    content: [T];
    offset: Nat;
    limit: Nat;
  };
  
  public type Metadata = {
    #fungible : {
      name : Text;
      symbol : Text;
      decimals : Nat8;
      metadata : ?Blob;
      ownerAccount : ExtCore.AccountIdentifier;
    };
    #nonfungible : {
      metadata : ?Blob;
    };
  };
  
  public type Service = actor {
    metadata: query () -> async Result.Result<Metadata, ExtCore.CommonError>;

    supply: query () -> async Result.Result<ExtCore.Balance, ExtCore.CommonError>;
  };
};