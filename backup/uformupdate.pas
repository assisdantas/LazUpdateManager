unit uformupdate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls;

type

  { TfrmUpdates }

  TfrmUpdates = class(TForm)
    lblDownloadedSize: TLabel;
    lblDownloaded: TLabel;
    lblNewVersion: TLabel;
    lblCurrentVersion: TLabel;
    pbgProgress: TProgressBar;
  private

  public

  end;

var
  frmUpdates: TfrmUpdates;

implementation

{$R *.lfm}

end.

