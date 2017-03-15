unit SofaFile;

interface

uses
  Classes, SysUtils, Contnrs, HdfFile;

type
  TVector3 = record
    X, Y, Z: Double;
  end;

  TSofaFile = class(TInterfacedPersistent, IStreamPersist)
  private
    FNumberOfMeasurements: Integer;
    FNumberOfDataSamples: Integer;
    FNumberOfEmitters: Integer;
    FNumberOfReceivers: Integer;
    FListenerPositions: array of TVector3;
    FReceiverPositions: array of TVector3;
    FSourcePositions: array of TVector3;
    FEmitterPositions: array of TVector3;
    FListenerUp: TVector3;
    FListenerView: TVector3;
    FSampleRate: array of Double;
    FImpulseResponses: array of array of array of Double;
    FDelay: array of Double;
    FDateModified: string;
    FHistory: string;
    FComment: string;
    FLicense: string;
    FAPIVersion: string;
    FAPIName: string;
    FOrigin: string;
    FTitle: string;
    FDateCreated: string;
    FReferences: string;
    FDataType: string;
    FOrganization: string;
    FRoomType: string;
    FApplicationVersion: string;
    FApplicationName: string;
    FAuthorContact: string;
    procedure ReadAttributes(DataObject: THdfDataObject);
    procedure ReadDataObject(DataObject: THdfDataObject);
    function GetEmitterPositions(Index: Integer): TVector3;
    function GetListenerPositions(Index: Integer): TVector3;
    function GetReceiverPositions(Index: Integer): TVector3;
    function GetSourcePositions(Index: Integer): TVector3;
    function GetSampleRate(Index: Integer): Double;
    function GetDelay(Index: Integer): Double;
  public
    procedure AfterConstruction; override;

    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);

    procedure LoadFromFile(Filename: TFileName);
    procedure SaveToFile(Filename: TFileName);

    property DataType: string read FDataType;
    property RoomType: string read FRoomType;
    property Title: string read FTitle;
    property DateCreated: string read FDateCreated;
    property DateModified: string read FDateModified;
    property APIName: string read FAPIName;
    property APIVersion: string read FAPIVersion;
    property AuthorContact: string read FAuthorContact;
    property Organization: string read FOrganization;
    property License: string read FLicense;
    property ApplicationName: string read FApplicationName;
    property ApplicationVersion: string read FApplicationVersion;
    property Comment: string read FComment;
    property History: string read FHistory;
    property References: string read FReferences;
    property Origin: string read FOrigin;

    property NumberOfMeasurements: Integer read FNumberOfMeasurements;
    property NumberOfReceivers: Integer read FNumberOfReceivers;
    property NumberOfEmitters: Integer read FNumberOfEmitters;
    property NumberOfDataSamples: Integer read FNumberOfDataSamples;

    property ListenerPositions[Index: Integer]: TVector3 read GetListenerPositions;
    property ReceiverPositions[Index: Integer]: TVector3 read GetReceiverPositions;
    property SourcePositions[Index: Integer]: TVector3 read GetSourcePositions;
    property EmitterPositions[Index: Integer]: TVector3 read GetEmitterPositions;
    property ListenerUp: TVector3 read FListenerUp;
    property ListenerView: TVector3 read FListenerView;
    property SampleRate[Index: Integer]: Double read GetSampleRate;
    property Delay[Index: Integer]: Double read GetDelay;
  end;

implementation

uses
  Math;


{ TSofaFile }

procedure TSofaFile.AfterConstruction;
begin
  inherited;

end;

function TSofaFile.GetDelay(Index: Integer): Double;
begin
  if (Index < 0) or (Index >= Length(FDelay)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FDelay[Index];
end;

function TSofaFile.GetEmitterPositions(Index: Integer): TVector3;
begin
  if (Index < 0) or (Index >= Length(FEmitterPositions)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FEmitterPositions[Index];
end;

function TSofaFile.GetListenerPositions(Index: Integer): TVector3;
begin
  if (Index < 0) or (Index >= Length(FListenerPositions)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FListenerPositions[Index];
end;

function TSofaFile.GetReceiverPositions(Index: Integer): TVector3;
begin
  if (Index < 0) or (Index >= Length(FReceiverPositions)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FReceiverPositions[Index];
end;

function TSofaFile.GetSampleRate(Index: Integer): Double;
begin
  if (Index < 0) or (Index >= Length(FSampleRate)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FSampleRate[Index];
end;

function TSofaFile.GetSourcePositions(Index: Integer): TVector3;
begin
  if (Index < 0) or (Index >= Length(FSourcePositions)) then
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);

  Result := FSourcePositions[Index];
end;

procedure TSofaFile.LoadFromFile(Filename: TFileName);
var
  MS: TMemoryStream;
begin
  MS := TMemoryStream.Create;
  try
    MS.LoadFromFile(FileName);
    LoadFromStream(MS);
  finally
    MS.Free;
  end;
end;

procedure TSofaFile.LoadFromStream(Stream: TStream);
var
  HdfFile: THdfFile;
  Index: Integer;
begin
  HdfFile := THdfFile.Create;
  try
    HdfFile.LoadFromStream(Stream);
    if HdfFile.GetAttribute('Conventions') <> 'SOFA' then
      raise Exception.Create('File does not contain the SOFA convention');

    for Index := 0 to HdfFile.DataObject.DataObjectCount - 1 do
      ReadDataObject(HdfFile.DataObject.DataObject[Index]);

    ReadAttributes(HdfFile.DataObject);
  finally
    HdfFile.Free;
  end;
end;

procedure TSofaFile.ReadDataObject(DataObject: THdfDataObject);

  function GetDimension(Text: string): Integer;
  var
    TextPos: Integer;
  begin
    Result := 0;
    TextPos := Pos('This is a netCDF dimension but not a netCDF variable.', Text);
    if TextPos > 0 then
    begin
      Delete(Text, TextPos, 53);
      Result := StrToInt(Trim(Text));
    end;
  end;

var
  Index, ItemCount: Integer;
  MeasurementIndex: Integer;
  ReceiverIndex: Integer;
begin
  DataObject.Data.Position := 0;
  if DataObject.Name = 'M' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
    FNumberOfMeasurements := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'R' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
    FNumberOfReceivers := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'E' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
    FNumberOfEmitters := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'N' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
    FNumberOfDataSamples := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'S' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
//    FNumberOf := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'I' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
//    FNumberOf := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'C' then
  begin
    Assert(DataObject.GetAttribute('CLASS') = 'DIMENSION_SCALE');
//    FNumberOf := GetDimension(DataObject.GetAttribute('NAME'));
  end
  else if DataObject.Name = 'ListenerPosition' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div (3 * DataObject.DataType.Size);
    Assert(DataObject.DataType.DataClass = 1);
    SetLength(FListenerPositions, ItemCount);
    for Index := 0 to ItemCount - 1 do
    begin
      DataObject.Data.Read(FListenerPositions[Index].X, 8);
      DataObject.Data.Read(FListenerPositions[Index].Y, 8);
      DataObject.Data.Read(FListenerPositions[Index].Z, 8);
    end;
  end
  else if DataObject.Name = 'ReceiverPosition' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div (3 * DataObject.DataType.Size);
    Assert(DataObject.DataType.DataClass = 1);
    SetLength(FReceiverPositions, ItemCount);
    for Index := 0 to ItemCount - 1 do
    begin
      DataObject.Data.Read(FReceiverPositions[Index].X, 8);
      DataObject.Data.Read(FReceiverPositions[Index].Y, 8);
      DataObject.Data.Read(FReceiverPositions[Index].Z, 8);
    end;
  end
  else if DataObject.Name = 'SourcePosition' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div (3 * DataObject.DataType.Size);
    Assert(DataObject.DataType.DataClass = 1);
    SetLength(FSourcePositions, ItemCount);
    for Index := 0 to ItemCount - 1 do
    begin
      DataObject.Data.Read(FSourcePositions[Index].X, 8);
      DataObject.Data.Read(FSourcePositions[Index].Y, 8);
      DataObject.Data.Read(FSourcePositions[Index].Z, 8);
    end;
  end
  else if DataObject.Name = 'EmitterPosition' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div (3 * DataObject.DataType.Size);
    Assert(DataObject.DataType.DataClass = 1);
    SetLength(FEmitterPositions, ItemCount);
    for Index := 0 to ItemCount - 1 do
    begin
      DataObject.Data.Read(FEmitterPositions[Index].X, 8);
      DataObject.Data.Read(FEmitterPositions[Index].Y, 8);
      DataObject.Data.Read(FEmitterPositions[Index].Z, 8);
    end;
  end
  else if DataObject.Name = 'ListenerUp' then
  begin
    Assert(DataObject.Data.Size > 0);
    Assert(DataObject.DataType.DataClass = 1);
    DataObject.Data.Read(FListenerUp.X, 8);
    DataObject.Data.Read(FListenerUp.Y, 8);
    DataObject.Data.Read(FListenerUp.Z, 8);
  end
  else if DataObject.Name = 'ListenerView' then
  begin
    Assert(DataObject.Data.Size > 0);
    Assert(DataObject.DataType.DataClass = 1);
    DataObject.Data.Read(FListenerView.X, 8);
    DataObject.Data.Read(FListenerView.Y, 8);
    DataObject.Data.Read(FListenerView.Z, 8);
  end
  else if DataObject.Name = 'Data.IR' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := FNumberOfMeasurements * FNumberOfReceivers * FNumberOfDataSamples * 8;
    Assert(DataObject.Data.Size = ItemCount);
    SetLength(FImpulseResponses, FNumberOfMeasurements);
    for MeasurementIndex := 0 to FNumberOfMeasurements - 1 do
    begin
      SetLength(FImpulseResponses[MeasurementIndex], FNumberOfReceivers);
      for ReceiverIndex := 0 to FNumberOfReceivers - 1 do
      begin
        SetLength(FImpulseResponses[MeasurementIndex, ReceiverIndex], FNumberOfDataSamples);
        for Index := 0 to FNumberOfDataSamples - 1 do
          DataObject.Data.Read(FImpulseResponses[MeasurementIndex, ReceiverIndex, Index], 8);
      end;
    end;
  end
  else if DataObject.Name = 'Data.SamplingRate' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div DataObject.DataType.Size;
    SetLength(FSampleRate, ItemCount);
    for Index := 0 to ItemCount - 1 do
      DataObject.Data.Read(FSampleRate[Index], 8);
  end
  else if DataObject.Name = 'Data.Delay' then
  begin
    Assert(DataObject.Data.Size > 0);
    ItemCount := DataObject.Data.Size div DataObject.DataType.Size;
    SetLength(FDelay, ItemCount);
    for Index := 0 to ItemCount - 1 do
      DataObject.Data.Read(FDelay[Index], 8);
  end;
end;

procedure TSofaFile.ReadAttributes(DataObject: THdfDataObject);
var
  Index: Integer;
begin
  for Index := 0 to DataObject.AttributeListCount - 1 do
  begin
    if DataObject.AttributeListItem[Index].Name = 'DateModified' then
      FDateModified := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'History' then
      FHistory := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'Comment' then
      FComment := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'License' then
      FLicense := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'FAPIVersion: tring;' then
      FAPIVersion := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'APIName' then
      FAPIName := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'Origin' then
      FOrigin := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'Title' then
      FTitle := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'DateCreated' then
      FDateCreated := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'References' then
      FReferences := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'DataType' then
      FDataType := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'Organization' then
      FOrganization := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'RoomType' then
      FRoomType := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'ApplicationVersion' then
      FApplicationVersion := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'ApplicationName' then
      FApplicationName := string(DataObject.AttributeListItem[Index].ValueAsString);
    if DataObject.AttributeListItem[Index].Name = 'AuthorContact' then
      FAuthorContact := string(DataObject.AttributeListItem[Index].ValueAsString);
  end;
end;

procedure TSofaFile.SaveToFile(Filename: TFileName);
var
  MS: TMemoryStream;
begin
  MS := TMemoryStream.Create;
  try
    SaveToStream(MS);
    MS.SaveToFile(FileName);
  finally
    MS.Free;
  end;
end;

procedure TSofaFile.SaveToStream(Stream: TStream);
begin
  raise Exception.Create('Not yet implemented');
end;

end.
