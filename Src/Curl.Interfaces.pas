unit Curl.Interfaces;

interface

uses
  Curl.Lib, System.Classes, System.SysUtils;

type
  ICurlCustomSList = interface
    function RawValue : PCurlSList;
  end;

  TCurlStreamFlag = (
          csfAutoRewind,    ///< Each Perform reader stream is auto-rewound to 0.
                            ///  Writer stream is cleared and rewound.
          csfAutoDestroy ); ///< The stream is auto-destroyed when the owner
                            ///  disappears, or the stream is reassigned.
  TCurlStreamFlags = set of TCurlStreamFlag;

  TCurlAutoStream = record
    Stream : TStream;
    Flags : TCurlStreamFlags;

    procedure Init;  inline;
    procedure InitFrom(const v : TCurlAutoStream);
    procedure Assign(aStream : TStream; aFlags : TCurlStreamFlags);
    procedure RewindRead;
    procedure RewindWrite;
    procedure Destroy;
  end;

  ICloseable = interface
    ///  There’s a common problem of garbage collection that’s frequent for
    ///     ref-counting too. You don’t exactly know when the object
    ///     disappears, and if the stream is not shareable, the underlying
    ///     object (file, blob, etc) is locked. This function releases all
    ///     files and blobs.
    ///  @warning  After this you should NEVER work until you replace
    ///     ALL streams with fresh ones, or set them to NULL
    ///     (if applicable, some ICloseable’s are disposable and thus are
    ///     unusable forever).
    procedure CloseStreams;
  end;

  IRewindable = interface (ICloseable)
    ///  Rewinds all internal streams.
    procedure RewindStreams;
  end;

  ICurlCustomField = interface (IRewindable)
    ///  Some CurlField’s store some data.
    ///  @return  [+] It stores some data, and we should keep a reference.
    function DoesStore : boolean;

    ///  @return  [+] The form uses some stream for reading,
    ///          even when GiveStream returns nothing.
    function DoesUseStream : boolean;

    ///  Finally builds a PCurlHttpPost.
    function Build : PCurlForms;
  end;

  ICurlCustomForm = interface (IRewindable)
    function RawValue : PCurlHttpPost;

    ///  @return  form read function, or nil
    function ReadFunction : EvCurlRead;
  end;

  ICurlStringBuilder = interface
    function Build : RawByteString;
  end;

  ECurl = class (Exception) end;
  ECurlInternal = class (Exception) end;

function CurlStreamWrite(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
function CurlStreamRead(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;

implementation

procedure TCurlAutoStream.Init;
begin
  Stream := nil;
  Flags := [];
end;

procedure TCurlAutoStream.RewindRead;
begin
  if csfAutoRewind in Flags
    then Stream.Position := 0;
end;

procedure TCurlAutoStream.RewindWrite;
begin
  if csfAutoRewind in Flags then begin
    Stream.Position := 0;
    Stream.Size := 0;
  end;
end;

procedure TCurlAutoStream.Destroy;
begin
  if csfAutoDestroy in Flags then begin
    FreeAndNil(Stream);
    Flags := [];
  end;
end;

procedure TCurlAutoStream.Assign(aStream : TStream; aFlags : TCurlStreamFlags);
begin
  if Stream <> aStream
    then Destroy;
  Stream := aStream;
  if aStream <> nil
    then Flags := aFlags;
end;


procedure TCurlAutoStream.InitFrom(const v : TCurlAutoStream);
begin
  Stream := v.Stream;
  Flags := v.Flags - [csfAutoDestroy];
end;


function CurlStreamWrite(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Write(Buffer, Size * NItems);
end;


function CurlStreamRead(
        var Buffer;
        Size, NItems : NativeUInt;
        OutStream : pointer) : NativeUInt;  cdecl;
begin
  Result := TStream(OutStream).Read(Buffer, Size * NItems);
end;


end.
