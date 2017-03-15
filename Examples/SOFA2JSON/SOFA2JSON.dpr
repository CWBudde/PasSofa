program SOFA2JSON;

{$APPTYPE CONSOLE}

{$R *.res}

{$DEFINE UseBase64}

uses
  SysUtils,
  StrUtils,
  dwsJson,
  dwsXPlatform,
  dwsEncoding,
  SofaFile in '..\..\Source\SofaFile.pas',
  HdfFile in '..\..\HdfFile\Source\HdfFile.pas';

function BuildJsonFile(SofaFile: TSofaFile): TdwsJSONObject;
var
  DataArray, MeasurementDataArray, ReceiverDataArray: TdwsJSONArray;
  Index, MeasurementIndex, ReceiverIndex: Integer;
begin
  Result := TdwsJSONObject.Create;
  if SofaFile.Title <> '' then
    Result.AddValue('Title', SofaFile.Title);
  if SofaFile.DataType <> '' then
    Result.AddValue('DataType', SofaFile.DataType);
  if SofaFile.RoomType <> '' then
    Result.AddValue('RoomType', SofaFile.RoomType);
  if SofaFile.DateCreated <> '' then
    Result.AddValue('DateCreated', SofaFile.DateCreated);
  if SofaFile.DateModified <> '' then
    Result.AddValue('DateModified', SofaFile.DateModified);
  if SofaFile.APIName <> '' then
    Result.AddValue('APIName', SofaFile.APIName);
  if SofaFile.APIVersion <> '' then
    Result.AddValue('APIVersion', SofaFile.APIVersion);
  if SofaFile.AuthorContact <> '' then
    Result.AddValue('AuthorContact', SofaFile.AuthorContact);
  if SofaFile.Organization <> '' then
    Result.AddValue('Organization', SofaFile.Organization);
  if SofaFile.License <> '' then
    Result.AddValue('License', SofaFile.License);
  if SofaFile.ApplicationName <> '' then
    Result.AddValue('ApplicationName', SofaFile.ApplicationName);
  if SofaFile.ApplicationVersion <> '' then
    Result.AddValue('ApplicationVersion', SofaFile.ApplicationVersion);
  if SofaFile.Comment <> '' then
    Result.AddValue('Comment', SofaFile.Comment);
  if SofaFile.History <> '' then
    Result.AddValue('History', SofaFile.History);
  if SofaFile.References <> '' then
    Result.AddValue('References', SofaFile.References);
  if SofaFile.Origin <> '' then
    Result.AddValue('Origin', SofaFile.Origin);

  Result.AddValue('Measurements', SofaFile.NumberOfMeasurements);
  Result.AddValue('Receivers', SofaFile.NumberOfReceivers);
  Result.AddValue('Emitters', SofaFile.NumberOfEmitters);
  Result.AddValue('DataSamples', SofaFile.NumberOfDataSamples);
  DataArray := Result.AddArray('SampleRate');
  for Index := 0 to SofaFile.SampleRateCount - 1 do
    DataArray.Add(SofaFile.SampleRate[Index]);
  DataArray := Result.AddArray('Delay');
  for Index := 0 to SofaFile.DelayCount - 1 do
    DataArray.Add(SofaFile.Delay[Index]);

  MeasurementDataArray := Result.AddArray('IR');
  for MeasurementIndex := 0 to SofaFile.NumberOfMeasurements - 1 do
  begin
    ReceiverDataArray := MeasurementDataArray.AddArray;
    for ReceiverIndex := 0 to SofaFile.NumberOfReceivers - 1 do
    begin
      {$IFDEF UseBase64}
      ReceiverDataArray.Add(Base64Encode(@SofaFile.ImpulseResponse[MeasurementIndex, ReceiverIndex][Index], SizeOf(Double) * SofaFile.NumberOfDataSamples));
      {$ELSE}
      DataArray := ReceiverDataArray.AddArray;
      for Index := 0 to SofaFile.NumberOfDataSamples - 1 do
        DataArray.Add(SofaFile.ImpulseResponse[MeasurementIndex, ReceiverIndex][Index]);
      {$ENDIF}
    end;
  end;
end;

procedure ReadSofaFile(FileName: TFileName);
var
  SofaFile: TSofaFile;
  JsonObject: TdwsJSONObject;
begin
  // check if file exists
  if not FileExists(FileName) then
    Exit;

  SofaFile := TSofaFile.Create;
  try
    SofaFile.LoadFromFile(FileName);
    JsonObject := BuildJsonFile(SofaFile);
    try
      SaveTextToUTF8File(ChangeFileExt(FileName, '.json'),
        JsonObject.ToBeautifiedString);
    finally
      JsonObject.Free;
    end;
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
end.
