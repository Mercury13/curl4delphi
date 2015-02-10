unit Curl.RawByteStream;

interface

uses
  System.Classes;

type
  TRawByteStream = class(TStream)
  private
    fData : RawByteString;
    fPos : NativeInt;
    procedure SetData(x : RawByteString);
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64);  override;
    function Remainder : NativeInt;
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property Data : RawByteString   read fData write SetData;
    procedure Clear;
  end;

implementation

uses
  System.Math, System.SysUtils;

const
  StringOrigin = 1;

procedure TRawByteStream.SetData(x : RawByteString);
begin
  fData := x;
  fPos := 0;
end;

procedure TRawByteStream.Clear;
begin
  Data := '';
end;

procedure TRawByteStream.SetSize(const NewSize: Int64);
begin
  if (NewSize < 0) or (NewSize > High(NativeInt)) then
    raise ERangeError.Create('[TRawByteStream.SetSize] Wrong size');
  SetLength(fData, NewSize);
  fPos := Max(fPos, Length(fData));
end;

function TRawByteStream.GetSize: Int64;
begin
  Result := Length(fData);
end;


function TRawByteStream.Remainder : NativeInt;
begin
  Result := Length(fData) - fPos;
end;


function TRawByteStream.Read(var Buffer; Count: Longint): Longint;
begin
  if Count < 0
    then Exit(0);
  Count := Min(Count, Remainder);
  Move(fData[fPos + StringOrigin], Buffer, Count);
  Inc(fPos, Count);
  Result := Count;
end;


function TRawByteStream.Write(const Buffer; Count: Longint): Longint;
var
  NewSize : NativeInt;
begin
  if Count < 0
    then Exit(0);
  NewSize := fPos + Count;
  if NewSize > Length(fData)
    then SetLength(fData, NewSize);

  Move(Buffer, fData[fPos + StringOrigin], Count);
  Inc(fPos, Count);
  Result := Count;
end;


function TRawByteStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
  soBeginning: fPos := Offset;
  soCurrent:   Inc(fPos, Offset);
  soEnd:       fPos := Length(fData) + Offset;
  end;
  fPos := EnsureRange(fPos, 0, Length(fData));
  Result := fPos;
end;

end.
