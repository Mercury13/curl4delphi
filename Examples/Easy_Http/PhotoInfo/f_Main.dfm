object fmMain: TfmMain
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'POST form demo'
  ClientHeight = 200
  ClientWidth = 309
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
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel
    Left = 12
    Top = 11
    Width = 19
    Height = 13
    Caption = 'URL'
  end
  object Label1: TLabel
    Left = 12
    Top = 41
    Width = 36
    Height = 13
    Caption = 'Disk file'
  end
  object Label2: TLabel
    Left = 12
    Top = 72
    Width = 76
    Height = 13
    Caption = 'Synthetic image'
  end
  object edUrl: TEdit
    Left = 37
    Top = 8
    Width = 257
    Height = 21
    TabOrder = 1
    Text = 'http://localhost/php_curl/photoinfo/action.php'
  end
  object memoResponse: TMemo
    Left = 15
    Top = 97
    Width = 282
    Height = 95
    TabOrder = 0
  end
  object btEasy: TButton
    Left = 54
    Top = 35
    Width = 75
    Height = 25
    Caption = 'Easy way'
    TabOrder = 2
    OnClick = btEasyClick
  end
  object btHard: TButton
    Left = 135
    Top = 35
    Width = 75
    Height = 25
    Caption = 'Hard way'
    TabOrder = 3
    OnClick = btHardClick
  end
  object btSynthStream: TButton
    Left = 94
    Top = 66
    Width = 75
    Height = 25
    Caption = 'Stream'
    TabOrder = 4
    OnClick = btSynthStreamClick
  end
  object btSynthMemory: TButton
    Left = 175
    Top = 66
    Width = 75
    Height = 25
    Caption = 'Memory'
    TabOrder = 5
    OnClick = btSynthMemoryClick
  end
  object od: TOpenDialog
    Filter = 'Images (*.jpg; *.jpeg; *.png)|*.jpg; *.jpeg; *.png'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 264
    Top = 8
  end
end
