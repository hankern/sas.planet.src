object frmDGAvailablePic: TfrmDGAvailablePic
  Left = 730
  Top = 247
  BorderStyle = bsSizeToolWin
  Caption = 'Images available'
  ClientHeight = 359
  ClientWidth = 256
  Color = clBtnFace
  Constraints.MinHeight = 332
  Constraints.MinWidth = 264
  ParentFont = True
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  ShowHint = True
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object spltDesc: TSplitter
    Left = 0
    Top = 240
    Width = 256
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    OnCanResize = spltDescCanResize
    ExplicitTop = 238
    ExplicitWidth = 270
  end
  object gbImageParams: TGroupBox
    Left = 0
    Top = 243
    Width = 256
    Height = 116
    Align = alBottom
    Caption = 'Description:'
    Constraints.MinHeight = 80
    TabOrder = 0
    object veImageParams: TValueListEditor
      Left = 2
      Top = 15
      Width = 252
      Height = 99
      Align = alClient
      TabOrder = 0
      TitleCaptions.Strings = (
        'Parameter'
        'Value')
      ColWidths = (
        120
        126)
    end
  end
  object gbAvailImages: TGroupBox
    Left = 0
    Top = 78
    Width = 256
    Height = 162
    Align = alClient
    Caption = 'Images available'
    Constraints.MinHeight = 144
    TabOrder = 1
    object tvFound: TTreeView
      AlignWithMargins = True
      Left = 5
      Top = 18
      Width = 165
      Height = 139
      Align = alClient
      HideSelection = False
      HotTrack = True
      Indent = 19
      ParentShowHint = False
      ShowHint = True
      SortType = stText
      TabOrder = 0
      OnChange = tvFoundChange
      OnClick = tvFoundClick
      OnDeletion = tvFoundDeletion
      OnMouseDown = tvFoundMouseDown
    end
    object pnlRight: TPanel
      Left = 173
      Top = 15
      Width = 81
      Height = 145
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      object btnUp: TButton
        AlignWithMargins = True
        Left = 3
        Top = 34
        Width = 75
        Height = 25
        Align = alTop
        Caption = 'Up'
        TabOrder = 1
        OnClick = btnUpClick
      end
      object btnDown: TButton
        AlignWithMargins = True
        Left = 3
        Top = 65
        Width = 75
        Height = 25
        Align = alTop
        Caption = 'Down'
        TabOrder = 2
        OnClick = btnDownClick
      end
      object btnCopy: TButton
        AlignWithMargins = True
        Left = 3
        Top = 96
        Width = 75
        Height = 25
        Hint = 'Copy TID'#39's to clipboard'
        Align = alTop
        Caption = 'Copy'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnClick = btnCopyClick
      end
      object btnRefresh: TButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 75
        Height = 25
        Align = alTop
        Caption = 'Refresh'
        TabOrder = 0
        OnClick = btnRefreshClick
      end
    end
  end
  object gbImagesSource: TGroupBox
    Left = 0
    Top = 0
    Width = 256
    Height = 78
    Align = alTop
    Caption = 'Image services'
    TabOrder = 2
    DesignSize = (
      256
      78)
    object lbZoom: TLabel
      Left = 186
      Top = 22
      Width = 47
      Height = 13
      Hint = '(zoom %)'
      Caption = '(zoom %)'
      ParentShowHint = False
      ShowHint = False
    end
    object cbDGstacks: TComboBox
      AlignWithMargins = True
      Left = 71
      Top = 44
      Width = 180
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ItemHeight = 13
      TabOrder = 2
    end
    object chkNMC: TCheckBox
      AlignWithMargins = True
      Left = 71
      Top = 21
      Width = 109
      Height = 17
      Caption = 'Nokia map creator'
      TabOrder = 0
    end
    object chkDG: TCheckBox
      AlignWithMargins = True
      Left = 13
      Top = 44
      Width = 41
      Height = 17
      Caption = 'DG'
      TabOrder = 1
    end
    object chkBing: TCheckBox
      AlignWithMargins = True
      Left = 13
      Top = 21
      Width = 52
      Height = 17
      Caption = 'Bing'
      TabOrder = 3
    end
  end
end
