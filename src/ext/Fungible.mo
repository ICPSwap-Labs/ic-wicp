/**

 */
import Result "mo:base/Result";
import ExtCore "./Core";
module ExtFungible = {
  public type MintRequest = {
    to : ExtCore.User;
    amount: ExtCore.Balance;
  };
  public type Service = actor {
    mint: shared (request : MintRequest) -> async ();
  };
};
