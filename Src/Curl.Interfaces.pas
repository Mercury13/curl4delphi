unit Curl.Interfaces;

interface

uses
  Curl.Lib;

type
  ICurlSList = interface
    procedure Add(s : RawByteString);  overload;
    procedure Add(s : string);  overload;

    function RawValue : PCurlSList;
  end;

  ICurlField = interface
    function Name(x : RawByteString) : ICurlField;  overload;
    function Name(x : string) : ICurlField;  overload;
    function PtrName(x : RawByteString) : ICurlField;

    function Content(x : RawByteString) : ICurlField;  overload;
    function Content(length : integer; const data) : ICurlField;  overload;

    function PtrContent(x : RawByteString) : ICurlField;  overload;
    function PtrContent(length : integer; const data) : ICurlField;  overload;

    function FileContent(x : string) : ICurlField;

    function UploadFile(x : string) : ICurlField;

    function CustomHeaders(x : PCurlSlist) : ICurlField;

    function DoesUseStreams : boolean;

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

    ///  Builds a complex field using fluid ICurlFormBuilder interface
    ///  @warning  it’ll always return the same builder, so
    //function Build : ICurlFormBuilder;

    function RawValue : PCurlHttpPost;

  end;

implementation

end.
