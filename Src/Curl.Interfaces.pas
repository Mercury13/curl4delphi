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

  ICurlField = interface
    function Name(const x : RawByteString) : ICurlField;
    function PtrName(const x : RawByteString) : ICurlField;

    function ContentRaw(const x : RawByteString) : ICurlField;
    function Content(const x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(const x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(const x : string) : ICurlField;

    function UploadFile(const aFname : string) : ICurlField;
    function ContentType(const aFname : RawByteString) : ICurlField;

    // Custom file uploading
    function FileName(const x : RawByteString) : ICurlField;
    function FileBuffer(
            const aFname, aData : RawByteString) : ICurlField;  overload;
    function FileBuffer(
            const aFname : RawByteString;
            length : integer; const data) : ICurlField;  overload;
    ///  @warning
    ///  When you assign FileStream, you SHOULD use Delphi streams for all
    ///     other reading operations of ICurl concerned!
    ///  E.g. use SetSendStream, not SetOpt(CURLOPT_READFUNCTION).
    function FileStream(x : TStream) : ICurlField;

    function CustomHeaders(x : ICurlSlist) : ICurlField;

    ///  Some CurlField’s store some data.
    ///  @return  a reference-counted object we should store until
    ///        we perform an operation.
    function Storage : IInterface;

    function Build : PCurlHttpPost;

    /// @return [+] the form uses some stream for reading
    function DoesUseStream : boolean;
  end;

  ICurlForm = interface
    ///  This is the simplest version of Add; use it if you want something
    ///  like name=value.
    function Add(aName, aValue : RawByteString) : ICurlForm;  overload;
    function Add(aName, aValue : string) : ICurlForm;  overload;
    ///  @warning
    ///  This is a rawmost version of Add. Please have CURLFORM_END
    ///     in the end.
    function Add(aArray : array of TCurlPostOption) : ICurlForm;  overload;
    function Add(aField : ICurlField) : ICurlForm;  overload;

    ///  Adds a single disk file for uploading.
    ///     in the end.
    function AddDiskFile(
              aFieldName : RawByteString;
              aFileName : string;
              aContentType : RawByteString) : ICurlForm;  overload;

    ///  Builds a complex field using fluid ICurlFormBuilder interface
    ///  @warning  it’ll always return the same builder, so
    //function Build : ICurlFormBuilder;

    function RawValue : PCurlHttpPost;

    /// @return [+] the form uses some stream for reading
    function DoesUseStream : boolean;
  end;

  ECurl = class (Exception) end;
  ECurlInternal = class (Exception) end;

implementation

end.
