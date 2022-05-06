import Text "mo:base/Text";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import ExtCore "./Core";

module ExtLogo = {
  
  public type Service = actor {
    setLogo: shared (Text) -> async Result.Result<Bool, ExtCore.CommonError>;
    logo: query () -> async Result.Result<Text, ExtCore.CommonError>;
  };

};