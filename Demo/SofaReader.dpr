program SofaReader;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  StrUtils,
  SofaFile in '..\Source\SofaFile.pas',
  HdfFile in '..\HdfFile\Source\HdfFile.pas';

procedure PrintFileInformation(SofaFile: TSofaFile);
begin
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

