object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 841
  ClientWidth = 1131
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 681
    Width = 1131
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 625
    ExplicitWidth = 216
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1131
    Height = 65
    Align = alTop
    TabOrder = 0
    object Button1: TButton
      Left = 928
      Top = 21
      Width = 137
      Height = 25
      Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' DLL'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 65
    Width = 1131
    Height = 576
    ActivePage = tsCompletedTasks
    Align = alClient
    TabOrder = 1
    ExplicitTop = 71
    ExplicitHeight = 448
    object tsAvailableTasks: TTabSheet
      Caption = #1044#1086#1089#1090#1091#1087#1085#1099#1077' '#1079#1072#1076#1072#1095#1080
      object ListBoxTasks: TListBox
        Left = 24
        Top = 16
        Width = 1049
        Height = 385
        ItemHeight = 15
        TabOrder = 0
        OnContextPopup = ListBoxTasksContextPopup
        OnDblClick = ListBoxTasksDblClick
      end
    end
    object tsRunningTasks: TTabSheet
      Caption = #1042#1099#1087#1086#1083#1085#1103#1102#1097#1080#1077#1089#1103' '#1079#1072#1076#1072#1095#1080
      ImageIndex = 1
      object ListViewRunning: TListView
        Left = 24
        Top = 16
        Width = 1073
        Height = 489
        Columns = <>
        TabOrder = 0
      end
    end
    object tsCompletedTasks: TTabSheet
      Caption = #1047#1072#1074#1077#1088#1096#1077#1085#1085#1099#1077' '#1079#1072#1076#1072#1095#1080
      ImageIndex = 2
      object ListViewCompleted: TListView
        Left = 24
        Top = 16
        Width = 1073
        Height = 489
        Columns = <>
        TabOrder = 0
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 641
    Width = 1131
    Height = 40
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    ExplicitLeft = -8
    ExplicitTop = 635
    object Label1: TLabel
      Left = 72
      Top = 6
      Width = 46
      Height = 35
      Caption = 'Label1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnExecute: TButton
      Left = 168
      Top = 6
      Width = 137
      Height = 28
      Caption = #1042#1099#1087#1086#1083#1085#1080#1090#1100
      TabOrder = 0
      OnClick = btnExecuteClick
    end
    object btnCancel: TButton
      Left = 352
      Top = 4
      Width = 145
      Height = 30
      Caption = #1054#1090#1084#1077#1085#1080#1090#1100
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object btnViewResults: TButton
      Left = 528
      Top = 4
      Width = 201
      Height = 30
      Caption = #1055#1088#1086#1089#1084#1086#1090#1088#1077#1090#1100' '#1088#1077#1079#1091#1083#1100#1090#1072#1090#1099
      TabOrder = 2
      OnClick = btnViewResultsClick
    end
  end
  object MemoLog: TMemo
    Left = 0
    Top = 684
    Width = 1131
    Height = 117
    Align = alBottom
    Lines.Strings = (
      '')
    TabOrder = 3
    ExplicitTop = 628
  end
  object ProgressBar: TProgressBar
    Left = 0
    Top = 801
    Width = 1131
    Height = 20
    Align = alBottom
    TabOrder = 4
    ExplicitTop = 804
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 821
    Width = 1131
    Height = 20
    Panels = <>
    ExplicitTop = 822
  end
  object OpenDialog: TOpenDialog
    Left = 1080
    Top = 17
  end
  object PopupMenu1: TPopupMenu
    Left = 888
    Top = 24
    object miExecuteTask: TMenuItem
      Caption = #1042#1099#1087#1086#1083#1085#1080#1090#1100' '#1079#1072#1076#1072#1095#1091
      OnClick = miExecuteTaskClick
    end
    object miViewInfo: TMenuItem
      Caption = #1055#1088#1086#1089#1084#1086#1090#1088
      OnClick = miViewInfoClick
    end
  end
end
