unit Curl.Interfaces;

interface

uses
  Curl.Lib, System.Classes, System.SysUtils;

type
  ICurlSList = interface
    function AddRaw(s : RawByteString) : ICurlSList;
    function Add(s : string) : ICurlSList;

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

  ICurlField = interface (IRewindable)
    function Name(const x : RawByteString) : ICurlField;

    function ContentRaw(const x : RawByteString) : ICurlField;
    function Content(const x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    ///  Sets content from a RawByteString.
    ///  @warning  This RawByteString should live until Perform ends.
    function PtrContent(const x : RawByteString) : ICurlField;  overload;
    ///  Sets content from a memory buffer.
    ///  @warning  This buffer should live until Perform ends.
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(const x : string) : ICurlField;

    function UploadFile(const aFname : string) : ICurlField;
    function ContentType(const aFname : RawByteString) : ICurlField;

    // Sets a file name
    function FileName(const x : RawByteString) : ICurlField;
    // Sets file data, either as RawByteString or as data buffer
    function FileBuffer(
            const aFname, aData : RawByteString) : ICurlField;  overload;
    function FileBuffer(
            const aFname : RawByteString;
            length : integer; const data) : ICurlField;  overload;
    ///  @warning
    ///  When you assign FileStream, you SHOULD use Delphi streams for all
    ///     other reading operations of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function FileStream(x : TStream; aFlags : TCurlStreamFlags) : ICurlField;

    function CustomHeaders(x : ICurlSlist) : ICurlField;

    ///  Some CurlField’s store some data.
    ///  @return  It stores some data, and we should keep a reference.
    function DoesStore : boolean;

    ///  @return [+] the form uses some stream for reading,
    ///          even when GiveStream returns nothing.
    function DoesUseStream : boolean;

    ///  Finally builds an array of TCurlHttpPost.
    function Build : PCurlHttpPost;
  end;

  ICurlForm = interface (IRewindable)
    ///  This is the simplest version of Add; use it if you want something
    ///  like name=value.
    function Add(aName, aValue : RawByteString) : ICurlForm;  overload;
    function Add(aName, aValue : string) : ICurlForm;  overload;
    ///  This is a rawmost version of Add.
    ///  @warning  Please have CURLFORM_END in the end.
    ///  @warning  Some options of Windows cURL request disk file name
    ///         in a single-byte encoding.
    function Add(aArray : array of TCurlPostOption) : ICurlForm;  overload;
    ///  Adds a field using a special array-builder.
    function Add(aField : ICurlField) : ICurlForm;  overload;

    ///  Adds a single disk file for uploading.
    ///  @warning  Because of cURL bug, it uses a stream internally.
    ///     You SHOULD use Delphi streams for all other reading operations
    ///     of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function AddDiskFile(
              aFieldName : RawByteString;
              aFileName : string;
              aContentType : RawByteString) : ICurlForm;  overload;

    function RawValue : PCurlHttpPost;

    ///  @return [+] the form uses some stream for reading
    function DoesUseStream : boolean;
  end;

  ECurl = class (Exception) end;
  ECurlInternal = class (Exception) end;

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

end.
