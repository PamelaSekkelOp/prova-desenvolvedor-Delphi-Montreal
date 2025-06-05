
unit Horse.SSL;

interface

uses
  Horse,
  Horse.IOHandleSSL;

procedure StartSSL(APort: Integer; const ACertFile, AKeyFile: string);

implementation

procedure StartSSL(APort: Integer; const ACertFile, AKeyFile: string);
begin
  THorse.UseSSL := True;
  THorse.Port := APort;
  THorse.SSLCertFile := ACertFile;
  THorse.SSLKeyFile := AKeyFile;
end;

end.
