{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazAutoUpdate;

{$warn 5023 off : no warning about unused units}
interface

uses
  uformupdate, LazUpdateManager, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('LazUpdateManager', @LazUpdateManager.Register);
end;

initialization
  RegisterPackage('LazAutoUpdate', @Register);
end.
