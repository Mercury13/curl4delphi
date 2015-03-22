unit Curl.Interfaces;

interface

uses
  Curl.Lib, System.Classes;

type
  ICurlSList = interface
    function AddRaw(s : RawByteString) : ICurlSList;
    function Add(s : string) : ICurlSList;

    function RawValue : PCurlSList;
  end;

  ICurlField = interface
    function Name(x : RawByteString) : ICurlField;
    function PtrName(x : RawByteString) : ICurlField;

    function ContentRaw(x : RawByteString) : ICurlField;
    function Content(x : string) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(x : string) : ICurlField;

    function UploadFile(x : string) : ICurlField;

    // Custom file uploading
    function FileName(x : RawByteString) : ICurlField;
    function FileBuffer(x : RawByteString) : ICurlField;  overload;
    function FileBuffer(length : integer; const data) : ICurlField;  overload;
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
  end;

  ICurlForm = interface
    ///  This is the simplest version of Add; use it if you want something
    ///  like name=value.
    procedure Add(aName, aValue : RawByteString);  overload;
    procedure Add(aName, aValue : string);  overload;
    ///  @warning
    ///  This is a rawmost version of Add. Please have CURLFORM_END
    ///     in the end.
    procedure Add(aArray : array of TCurlPostOption);  overload;
    procedure Add(aField : ICurlField);  overload;

    ///  Builds a complex field using fluid ICurlFormBuilder interface
    ///  @warning  it’ll always return the same builder, so
    //function Build : ICurlFormBuilder;

    function RawValue : PCurlHttpPost;

  end;

implementation

end.
