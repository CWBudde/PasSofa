program SofaReader;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  StrUtils,
  SofaFile in '..\..\Source\SofaFile.pas',
  HdfFile in '..\..\HdfFile\Source\HdfFile.pas';

procedure PrintFileInformation(SofaFile: TSofaFile);
begin
  if SofaFile.Title <> '' then
    WriteLn('Title: ' + SofaFile.Title);
  if SofaFile.DataType <> '' then
    WriteLn('DataType: ' + SofaFile.DataType);
  if SofaFile.RoomType <> '' then
    WriteLn('RoomType: ' + SofaFile.RoomType);
  if SofaFile.DateCreated <> '' then
    WriteLn('DateCreated: ' + SofaFile.DateCreated);
  if SofaFile.DateModified <> '' then
    WriteLn('DateModified: ' + SofaFile.DateModified);
  if SofaFile.APIName <> '' then
    WriteLn('APIName: ' + SofaFile.APIName);
  if SofaFile.APIVersion <> '' then
    WriteLn('APIVersion: ' + SofaFile.APIVersion);
  if SofaFile.AuthorContact <> '' then
    WriteLn('AuthorContact: ' + SofaFile.AuthorContact);
  if SofaFile.Organization <> '' then
    WriteLn('Organization: ' + SofaFile.Organization);
  if SofaFile.License <> '' then
    WriteLn('License: ' + SofaFile.License);
  if SofaFile.ApplicationName <> '' then
    WriteLn('ApplicationName: ' + SofaFile.ApplicationName);
  if SofaFile.ApplicationVersion <> '' then
    WriteLn('ApplicationVersion: ' + SofaFile.ApplicationVersion);
  if SofaFile.Comment <> '' then
    WriteLn('Comment: ' + SofaFile.Comment);
  if SofaFile.History <> '' then
    WriteLn('History: ' + SofaFile.History);
  if SofaFile.References <> '' then
    WriteLn('References: ' + SofaFile.References);
  if SofaFile.Origin <> '' then
    WriteLn('Origin: ' + SofaFile.Origin);

  WriteLn('');

  WriteLn('Number of Measurements: ' + IntToStr(SofaFile.NumberOfMeasurements));
  WriteLn('Number of Receivers: ' + IntToStr(SofaFile.NumberOfReceivers));
  WriteLn('Number of Emitters: ' + IntToStr(SofaFile.NumberOfEmitters));
  WriteLn('Number of DataSamples: ' + IntToStr(SofaFile.NumberOfDataSamples));
  WriteLn('SampleRate: ' + FloatToStr(SofaFile.SampleRate[0]));
  WriteLn('Delay: ' + FloatToStr(SofaFile.Delay[0]));
end;

procedure ReadSofaFile(FileName: TFileName);
var
  SofaFile: TSofaFile;
begin
  // check if file exists
  if not FileExists(FileName) then
    Exit;

  SofaFile := TSofaFile.Create;
  try
    SofaFile.LoadFromFile(FileName);
    PrintFileInformation(SofaFile);
  finally
    SofaFile.Free;
  end;
end;

procedure ReadSofaFiles;
var
  SR: TSearchRec;
  FileName: TFileName;
begin
  if FindFirst('*.sofa', faAnyFile, SR) = 0 then
  try
    repeat
      FileName := SR.Name;
      WriteLn('Process file ' + ExtractFileName(FileName));
      ReadSofaFile(FileName);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

begin
  try
    if ParamCount >= 1 then
      ReadSofaFile(ParamStr(1))
    else
      ReadSofaFiles;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  {$IFDEF DEBUG}
  ReadLn;
  {$ENDIF}
end.

