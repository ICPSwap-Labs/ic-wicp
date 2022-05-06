import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ExtCore "./Core";
import ExtLedger "./Ledger";

module {

  public type Tokens = {
    e8s : Nat64;
  };

  public type BlockInfo = {
    from : ExtCore.AccountIdentifier;
    to : ExtCore.AccountIdentifier;
    amount : Tokens;
  };

  public type TxError = {
    #InsufficientBalance;
    #InsufficientAllowance;
    #Unauthorized;
    #LedgerTrap;
    #AmountTooSmall;
    #BlockUsed;
    #ErrorOperationStyle;
    #ErrorTo;
    #Other;
  };

  public type RustResult<Ok, Err> = {
    #Ok : Ok;
    #Err : Err;
  };

  public type BlockResult = RustResult<BlockInfo, TxError>;
  
  public type ValidActor = actor {
    getBlock : shared (blockHeigh: Nat64) -> async BlockResult;
  };
}

