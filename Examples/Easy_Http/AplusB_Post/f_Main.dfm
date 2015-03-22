object fmMain: TfmMain
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'POST form demo'
  ClientHeight = 169
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Padding.Left = 12
  Padding.Top = 8
  Padding.Right = 12
  Padding.Bottom = 8
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 12
    Top = 38
    Width = 15
    Height = 13
    Caption = 'A='
  end
  object Label2: TLabel
    Left = 121
    Top = 38
    Width = 14
    Height = 13
    Caption = 'B='
  end
  object Label3: TLabel
    Left = 12
    Top = 11
    Width = 19
    Height = 13
    Caption = 'URL'
  end
  object edA: TEdit
    Left = 33
    Top = 35
    Width = 72
    Height = 21
    TabOrder = 0
    Text = '10'
  end
  object edB: TEdit
    Left = 141
    Top = 35
    Width = 72
    Height = 21
    TabOrder = 1
    Text = '20'
  end
  object btAdd: TButton
    Left = 219
    Top = 35
    Width = 75
    Height = 25
    Caption = 'Add them!'
    Default = True
    TabOrder = 2
    OnClick = btAddClick
  end
  object edUrl: TEdit
    Left = 37
    Top = 8
    Width = 257
    Height = 21
    TabOrder = 4
    Text = 'http://localhost/php_curl/aplusb/action.php'
  end
  object memoResponse: TMemo
    Left = 12
    Top = 66
    Width = 282
    Height = 95
    TabOrder = 3
  end
end
