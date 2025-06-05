
unit Horse.IOHandleSSL;

interface

uses
  System.Classes, Horse;

type
  THorseIOHandleSSL = class
  public
    class procedure New;
  end;

implementation

uses
  IdServerIOHandlerSSLOpenSSL;

class procedure THorseIOHandleSSL.New;
begin
  THorse.UseSSL := True;
end;

end.
