object Form1: TForm1
  Left = 216
  Top = 238
  Width = 1132
  Height = 677
  Caption = 'scream'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  PixelsPerInch = 120
  TextHeight = 17
  object img1: TImage
    Left = 10
    Top = 10
    Width = 23
    Height = 23
    Stretch = True
    OnMouseDown = img1MouseDown
  end
  object imgFontImage: TImage
    Left = 10
    Top = 392
    Width = 3922
    Height = 206
    Stretch = True
  end
  object Label1: TLabel
    Left = 671
    Top = 115
    Width = 65
    Height = 17
    Caption = 'FontWidth'
  end
  object Label2: TLabel
    Left = 672
    Top = 174
    Width = 52
    Height = 17
    Caption = 'FontFlag'
  end
  object Label3: TLabel
    Left = 670
    Top = 230
    Width = 80
    Height = 17
    Caption = 'FontTracking'
  end
  object Label4: TLabel
    Left = 858
    Top = 282
    Width = 39
    Height = 17
    Caption = 'Label4'
  end
  object Label5: TLabel
    Left = 670
    Top = 285
    Width = 63
    Height = 17
    Caption = 'FontIndex'
  end
  object _FontNum: TScrollBar
    Left = 667
    Top = 42
    Width = 158
    Height = 22
    Max = 255
    PageSize = 0
    Position = 192
    TabOrder = 0
    OnChange = _FontNumChange
  end
  object TMemoLOG: TMemo
    Left = 837
    Top = 0
    Width = 242
    Height = 211
    Lines.Strings = (
      'mmo1')
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object btn_SaveBTN: TButton
    Left = 732
    Top = 73
    Width = 98
    Height = 33
    Caption = 'save res'
    TabOrder = 2
    OnClick = btn_SaveBTNClick
  end
  object FontZoom1: TScrollBar
    Left = 837
    Top = 362
    Width = 242
    Height = 21
    Max = 300
    PageSize = 0
    Position = 80
    TabOrder = 3
    OnChange = FontZoom1Change
  end
  object ScrollBar2: TScrollBar
    Left = 324
    Top = 0
    Width = 159
    Height = 21
    PageSize = 0
    Position = 16
    TabOrder = 4
    OnChange = ScrollBar2Change
  end
  object _FontWidth: TSpinEdit
    Left = 670
    Top = 141
    Width = 158
    Height = 27
    MaxValue = 24
    MinValue = 0
    TabOrder = 5
    Value = 0
  end
  object _FontFlag: TSpinEdit
    Left = 670
    Top = 196
    Width = 158
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 6
    Value = 0
  end
  object _FontTracking: TSpinEdit
    Left = 670
    Top = 248
    Width = 158
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 7
    Value = 0
  end
  object _ImportBMP: TButton
    Left = 847
    Top = 230
    Width = 98
    Height = 33
    Caption = 'imprt bmp'
    TabOrder = 8
    OnClick = _ImportBMPClick
  end
  object _C_height: TSpinEdit
    Left = 952
    Top = 230
    Width = 116
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 9
    Value = 0
  end
  object _FontIndex: TSpinEdit
    Left = 670
    Top = 306
    Width = 158
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 10
    Value = 0
  end
  object _row_length: TSpinEdit
    Left = 942
    Top = 272
    Width = 158
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 11
    Value = 0
  end
  object _ClrSym: TButton
    Left = 952
    Top = 314
    Width = 98
    Height = 33
    Caption = 'Clear sym buf'
    TabOrder = 12
    OnClick = _ClrSymClick
  end
  object Button1: TButton
    Left = 668
    Top = 345
    Width = 158
    Height = 33
    Caption = #1056#1072#1079#1086#1073#1088#1072#1090#1100' res'
    TabOrder = 13
    OnClick = Button1Click
  end
  object _FontChoose: TScrollBar
    Left = 667
    Top = 3
    Width = 157
    Height = 21
    Max = 1
    PageSize = 0
    TabOrder = 14
    OnChange = _FontChooseChange
  end
end
