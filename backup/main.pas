unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, openssl, LCLType, Dialogs, Windows;

type
  { TUpdateManager }
  TUpdateManager = class(TComponent)
    private
      FVersionFileUrl: String;
      FLatestFileUrl: String;
      FDownloadFileName: String;
      function CompareVersions(const Version1, Version2: string): Integer;
	  public
	    CurrentVersion: string;
	    LatestVersion: string;
      FileLength: string;
      TaskDialogButtons: TMsgDlgButtons;
      function GetExeVersion: string;
		  function GetCurrentVersion: string;
		  function GetLatestVersion(const URL: string): string;
		  function ReadLatestVersion(const versionFileName: string): string;
		  function CheckForUpdates: boolean;
		  function ConvertToPercent(maxValue, curValue: real): string;
		  function ConvertToMegabyte(curValue: real): Double;
		  procedure DownloadNewVersion;
		  procedure DownloadException(Sender: TObject; E: Exception);
		  procedure ClientDataReceived(Sender: TObject; const ContentLength, CurrentPos: Int64);
		  procedure GetChangeLogFile(const URL: string);
      procedure CreateTaskDialog(const ACaption, AExpandedText, AText, ATitle: string; AMainIcon: TTaskDialogIcon; AButtons: TMsgDlgButtons);
    published
      property VersionFileURL: string read FVersionFileUrl write FVersionFileUrl;
      property LatestFileURL: string read FLatestFileUrl write FLatestFileUrl;
      property DownloadFileName: string read FDownloadFileName write FDownloadFileName;
	end;

procedure Register;

implementation

uses
  uformupdate;

procedure Register;
begin
  RegisterComponents('AutoUpdate', [TUpdateManager]);
end;

{ TUpdateManager }

function TUpdateManager.CompareVersions(const Version1, Version2: string
  ): Integer;
var
  Ver1List, Ver2List: TStringList;
  I, MaxParts: Integer;
  Part1, Part2: Integer;
begin
  Result := 0; // Assume que as versões são iguais

  Ver1List := TStringList.Create;
  Ver2List := TStringList.Create;

  try
    Ver1List.Delimiter := '.';
    Ver1List.StrictDelimiter := True;
    Ver1List.DelimitedText := Version1;

    Ver2List.Delimiter := '.';
    Ver2List.StrictDelimiter := True;
    Ver2List.DelimitedText := Version2;

    MaxParts := Max(Ver1List.Count, Ver2List.Count);

    for I := 0 to MaxParts - 1 do
    begin
      if I < Ver1List.Count then
        Part1 := StrToInt(Ver1List[I])
      else
        Part1 := 0;

      if I < Ver2List.Count then
        Part2 := StrToInt(Ver2List[I])
      else
        Part2 := 0;

      if Part1 > Part2 then
        Exit(1)
      else if Part1 < Part2 then
        Exit(-1);
    end;
  finally
    Ver1List.Free;
    Ver2List.Free;
  end;
end;

function TUpdateManager.GetExeVersion: string;
var
  lwdVerInfoSize: longword;
  lwdVerValueSize: longword;
  lwdDummy: longword;
  ptrVerInfo: pointer;
  VersionsInformation: PVSFixedFileInfo;
begin

  lwdVerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), lwdDummy);
  GetMem(ptrVerInfo, lwdVerInfoSize);
  GetFileVersionInfo(PChar(ParamStr(0)), 0, lwdVerInfoSize, ptrVerInfo);
  VerQueryValue (ptrVerInfo, '\', Pointer(VersionsInformation), lwdVerValueSize);

  with VersionsInformation^ do
  begin
    Result := IntToStr(dwFileVersionMS shr 16);
    Result := Result + '.'  + IntToStr(dwFileVersionMS and $FFFF);
    Result := Result + '.'  + IntToStr(dwFileVersionLS shr 16);
    Result := Result + '.'  + IntToStr(dwFileVersionLS and $FFFF);
  end;

  FreeMem(ptrVerInfo, lwdVerInfoSize);
end;

function TUpdateManager.GetCurrentVersion: string;
begin
  //Result := frmMain.rxviVersionInfo.FileVersion;
  Result := GetExeVersion;
end;

function TUpdateManager.GetLatestVersion(const URL: string): string;
var
  HTTPCliente: TFPHTTPClient;
  NewVersionFile: TFileStream;
begin
  InitSSLInterface;

  HTTPCliente := TFPHTTPClient.Create(nil);
  NewVersionFile := TFileStream.Create('version', fmCreate or fmOpenWrite);

  try
    try
	     HTTPCliente.AllowRedirect := True;
	     HTTPCliente.OnDataReceived := @ClientDataReceived;
	     HTTPCliente.Get(URL, NewVersionFile);
    except
      on E: Exception do
      begin
        CreateTaskDialog('Sem comunicação', E.Message, 'Desculpe, não consegui obter dados da internet. Por favor, verifique sua conexão e tente novamente.', 'Erro ao obter dados de uma nova versão', tdiError, TaskDialogButtons);
      end;
		end;
	finally
    NewVersionFile.Free;
    HTTPCliente.Free;

    Result := ReadLatestVersion('version');
	end;
end;

function TUpdateManager.ReadLatestVersion(const versionFileName: string
  ): string;
var
  FVersion: TextFile;
  FVersionLine: String;
begin
  AssignFile(FVersion, VersionFileName);
  try
    Reset(FVersion);
    if not Eof(FVersion) then
    begin
      ReadLn(FVersion, FVersionLine);
      Result := FVersionLine;
    end;
  finally
    CloseFile(FVersion);
  end;
end;

function TUpdateManager.CheckForUpdates: boolean;
begin
  Result := False;

  //CurrentVersion := GetCurrentVersion;
  CurrentVersion := GetExeVersion;
  LatestVersion := GetLatestVersion(VersionFileURL);

  if CompareVersions(LatestVersion, CurrentVersion) > 0 then
  begin
    Result := True;
  end;
end;

function TUpdateManager.ConvertToPercent(maxValue, curValue: real): string;
var
  percentValue: real;
begin
  percentValue := ((curValue * 100) / maxValue);
  Result := FormatFloat('#,##0.00%', percentValue);
end;

function TUpdateManager.ConvertToMegabyte(curValue: real): Double;
const
  BytesPorMegabyte = 1048576;
begin
  Result := curValue / BytesPorMegabyte;
end;

procedure TUpdateManager.DownloadNewVersion;
var
  HTTPCliente: TFPHTTPClient;
  NewVersionFile: TFileStream;
begin
  frmUpdates.ShowModal;
  InitSSLInterface;

  HTTPCliente := TFPHTTPClient.Create(nil);
  NewVersionFile := TFileStream.Create(DownloadFileName, fmCreate or fmOpenWrite);

  try
    try
	    HTTPCliente.AllowRedirect := True;
	    HTTPCliente.OnDataReceived := @ClientDataReceived;
	    HTTPCliente.Get(LatestFileURL, NewVersionFile);
    except
      on E: Exception do
      begin
        CreateTaskDialog('Download', E.Message, 'Desculpe, não consegui baixar a nova versão. Por favor, verifique sua conexão e tente novamente.', 'Erro ao baixar nova versão', tdiError, TaskDialogButtons);
      end;
		end;
	finally
    CreateTaskDialog('Download concluído', '', 'A nova atualização foi baixada. Aguarde a aplicação da atualização, o sistema irá fechar e iniciar novamente.', 'Download concluído', tdiInformation, TaskDialogButtons);
    NewVersionFile.Free;
    HTTPCliente.Free;
	end;
end;

procedure TUpdateManager.DownloadException(Sender: TObject; E: Exception);
begin
  CreateTaskDialog('Erro inesperado', E.Message, 'Desculpe, ocorreu um erro inesperado. Por favor, tente novamente. Se o problema persistir, entre em contato com o administrador do sistema ou suporte técnico.', 'Erro inesperado', tdiError, TaskDialogButtons);
end;

procedure TUpdateManager.ClientDataReceived(Sender: TObject;
  const ContentLength, CurrentPos: Int64);
var
  mbAtual, mbTotal: Double;
begin
  frmUpdates.pbgProgress.Max := ContentLength;
  frmUpdates.pbgProgress.Position := CurrentPos;

  frmUpdates.lblCurrentVersion.Caption := CurrentVersion;
  frmUpdates.lblNewVersion.Caption := LatestVersion;

  if (CurrentPos > 0) and (ContentLength > 0) then
    frmUpdates.lblDownloaded.Caption := 'Baixando nova versão [' + ConvertToPercent(ContentLength, CurrentPos) + ' concluídos.]';

  mbTotal := ConvertToMegabyte(ContentLength);
  mbAtual := ConvertToMegabyte(CurrentPos);

  FileLength := Format('%2.f MB', [mbTotal]);

  frmUpdates.lblDownloadedSize.Caption := 'Baixado: ' + Format('%2.f MB', [mbAtual]) + ' de ' + Format('%2.f MB', [mbTotal]);

  //Application.ProcessMessages;
end;

procedure TUpdateManager.GetChangeLogFile(const URL: string);
var
  HTTPCliente: TFPHTTPClient;
  NewVersionFile: TFileStream;
begin
  InitSSLInterface;

  HTTPCliente := TFPHTTPClient.Create(nil);
  NewVersionFile := TFileStream.Create('changelog', fmCreate or fmOpenWrite);

  try
    try
	    HTTPCliente.AllowRedirect := True;
	    HTTPCliente.OnDataReceived := @ClientDataReceived;
	    HTTPCliente.Get(URL, NewVersionFile);
    except
      on E: Exception do
      begin
        CreateTaskDialog('Sem comunicação', E.Message, 'Desculpe, não consegui obter dados da nova versão. Por favor, verifique sua conexão e tente novamente.', 'Erro ao obter dados da nova versão', tdiError, TaskDialogButtons);
      end;
		end;
	finally
    NewVersionFile.Free;
    HTTPCliente.Free;
	end;
end;

procedure TUpdateManager.CreateTaskDialog(const ACaption, AExpandedText, AText,
  ATitle: string; AMainIcon: TTaskDialogIcon; AButtons: TMsgDlgButtons);
var
  TaskDialog: TTaskDialog;
  Button: TMsgDlgBtn;
begin
  TaskDialog := TTaskDialog.Create(nil);
  try
    TaskDialog.Caption := ACaption;
    TaskDialog.ExpandedText := AExpandedText;
    TaskDialog.Text := AText;
    TaskDialog.Title := ATitle;
    TaskDialog.MainIcon := AMainIcon;

    TaskDialog.CommonButtons := [];

    for Button in AButtons do
    begin
      case Button of
        mbYes: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbYes];
        mbNo: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbNo];
        mbOK: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbOk];
        mbCancel: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbCancel];
        mbRetry: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbRetry];
        mbClose: TaskDialog.CommonButtons := TaskDialog.CommonButtons + [tcbClose];
      end;
    end;

    TaskDialog.Execute;
  finally
    TaskDialog.Free;
  end;
end;

end.

