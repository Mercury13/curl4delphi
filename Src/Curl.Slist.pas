(*******************************************************************************

  Simple encapsulation of TCurlSlist

*******************************************************************************)

unit Curl.Slist;

interface

uses
  Curl.Lib, Curl.Interfaces;

function CurlGetSList : ICurlSList;

implementation

uses
  System.Generics.Collections;

type
  TCurlList = class (TInterfacedObject, ICurlSList)
  private
    type
      PEntry = ^TEntry;
      TVar = record
      case integer of
      0 : ( Raw : TCurlSList; );
      1 : ( Data : PAnsiChar; Next : PEntry );
      end;
      TEntry = record
        v : TVar;
        Storage : RawByteString;
      end;
    var
      fStart, fEnd : PEntry;
  public
    constructor Create;
    destructor Destroy;  override;

    function AddRaw(s : RawByteString) : ICurlSList;
    function Add(s : string) : ICurlSList;

    function RawValue : PCurlSList;
  end;

constructor TCurlList.Create;
begin
  inherited;
  fStart := nil;
  fEnd := nil;
end;

destructor TCurlList.Destroy;
var
  p, p1 : PEntry;
begin
  p := fStart;
  while p <> nil do begin
    p1 := p^.v.Next;
    Dispose(p);
    p := p1;
  end;
  inherited;
end;

function TCurlList.RawValue : PCurlSList;
begin
  Result := @fStart.v.Raw;
end;

function TCurlList.AddRaw(s : RawByteString) : ICurlSList;
var
  p : PEntry;
begin
  New(p);
  p^.Storage := s;
  p^.v.Raw.Data := PAnsiChar(s);
  p^.v.Next := nil;
  if fStart = nil then begin
    fStart := p;
    fEnd := p;
  end else begin
    fEnd^.v.Next := p;
    fEnd := p;
  end;
  Result := Self;
end;

function TCurlList.Add(s : string) : ICurlSList;
begin
  Result := AddRaw(UTF8Encode(s));
end;

function CurlGetSlist : ICurlSList;
begin
  Result := TCurlList.Create;
end;

end.
