unit SofaFile;

interface

uses
  Classes, SysUtils, Contnrs, HdfFile;

type
  TSofaFile = class(TInterfacedPersistent, IStreamPersist)
  private
    FNumberOfMeasurements: Integer;
    FNumberOfDataSamples: Integer;
    FNumberOfEmitters: Integer;
    FNumberOfReceivers: Integer;
    procedure ReadDataObject(DataObject: THdfDataObject);
  public
    procedure AfterConstruction; override;

    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);

    procedure LoadFromFile(Filename: TFileName);
    procedure SaveToFile(Filename: TFileName);

    property NumberOfMeasurements: Integer read FNumberOfMeasurements;
    property NumberOfReceivers: Integer read FNumberOfReceivers;
    property NumberOfEmitters: Integer read FNumberOfEmitters;
    property NumberOfDataSamples: Integer read FNumberOfDataSamples;
  end;

implementation

uses
  Math;


{ TSofaFile }

procedure TSofaFile.AfterConstruction;
begin
  inherited;

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
    for Index := 0 to HdfFile.DataObject.DataObjectCount - 1 do
      ReadDataObject(HdfFile.DataObject.DataObject[Index]);
  finally
    HdfFile.Free;
  end;
end;

procedure TSofaFile.ReadDataObject(DataObject: THdfDataObject);
begin
  if DataObject.Name = 'N' then
  begin
    Assert(DataObject.Data.Size = 8);
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
