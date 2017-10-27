object fmMain: TfmMain
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Progress bar demo'
  ClientHeight = 96
  ClientWidth = 501
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
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 12
    Top = 8
    Width = 73
    Height = 13
    Caption = 'Enter URL here'
  end
  object lbError: TLabel
    Left = 12
    Top = 75
    Width = 32
    Height = 13
    Caption = 'lbError'
  end
  object edUrl: TEdit
    Left = 12
    Top = 27
    Width = 477
    Height = 21
    TabOrder = 0
    Text = 
      'http://tdf.ip-connect.vn.ua/libreoffice/stable/5.3.6/win/x86_64/' +
      'LibreOffice_5.3.6_Win_x64.msi'
  end
  object btDownload: TButton
    Left = 414
    Top = 54
    Width = 75
    Height = 25
    Caption = 'Download!'
    Default = True
    TabOrder = 1
    OnClick = btDownloadClick
  end
  object progress: TProgressBar
    Left = 12
    Top = 54
    Width = 396
    Height = 15
    Max = 1000
    TabOrder = 2
  end
  object sd: TSaveDialog
    Left = 192
    Top = 12
  end
end
