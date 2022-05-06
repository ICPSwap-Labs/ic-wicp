import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import SHA224 "mo:sha224/SHA224";
import CRC32 "../utils/CRC32";

module ExtLedger = {
  public type Result<T, E> = {
    #Ok  : T;
    #Err : E;
  };
  public type AccountIdentifier = Blob;
  public type SubAccount = Blob;
  public type AccountBalanceArgs = { 
    account : AccountIdentifier;
  };
  public type Tokens = { e8s : Nat64 };
  public type BlockHeight = Nat64;
  public type TransferArgs = {
    to : AccountIdentifier;
    fee : Tokens;
    memo : Nat64;
    from_subaccount : ?SubAccount;
    created_at_time : ?{ timestamp_nanos : Nat64 };
    amount : Tokens;
  };
  public type TransferError = {
    #BadFee : { expected_fee : Tokens };
    #InsufficientFunds : { balance: Tokens };
    #TxTooOld : { allowed_window_nanos: Nat64 };
    #TxCreatedInFuture;
    #TxDuplicate : { duplicate_of: BlockHeight; };
  };
  public type TransferResult = Result<BlockHeight, TransferError>;

  public type ValidActor = actor {
    account_balance_dfx : shared query AccountBalanceArgs -> async Tokens;
    transfer : shared TransferArgs -> async TransferResult;
  };

  func beBytes(n: Nat32) : [Nat8] {
    func byte(n: Nat32) : Nat8 {
    Nat8.fromNat(Nat32.toNat(n & 0xff))
    };
    [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
  };

  public func defaultSubaccount() : SubAccount {
    Blob.fromArrayMut(Array.init(32, 0 : Nat8))
  };

  public func accountIdentifier(principal: Principal, subaccount: SubAccount) : AccountIdentifier {
    let hash = SHA224.Digest();
    hash.write([0x0A]);
    hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
    hash.write(Blob.toArray(Principal.toBlob(principal)));
    hash.write(Blob.toArray(subaccount));
    let hashSum : [Nat8] = hash.sum();
    let crc32Bytes : [Nat8] = beBytes(CRC32.ofArray(hashSum));
    var hashBuffer : Buffer.Buffer<Nat8> = Buffer.Buffer<Nat8>(crc32Bytes.size() + hashSum.size());
    for (value in crc32Bytes.vals()) {
      hashBuffer.add(value);
    };
    for (value in hashSum.vals()) {
      hashBuffer.add(value);
    };
    Blob.fromArray(hashBuffer.toArray())
  };
};