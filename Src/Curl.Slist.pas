(*******************************************************************************

  Simple encapsulation of TCurlSlist

*******************************************************************************)

unit Curl.Slist;

interface

uses
  Curl.Lib;

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

    procedure Add(s : RawByteString);  overload;
    procedure Add(s : string);  overload;

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

procedure TCurlList.Add(s : RawByteString);
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
end;

procedure TCurlList.Add(s : string);
begin
  Add(UTF8Encode(s));
end;

function CurlGetSlist : ICurlSList;
begin
  Result := TCurlList.Create;
end;

end.
