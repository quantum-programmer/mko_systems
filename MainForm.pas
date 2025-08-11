unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  PluginAPI, System.Generics.Collections;

type

TTaskStatus = (tsPending, tsRunning, tsCompleted, tsFailed, tsCancelled);

TRunningTask = class
  TaskID: string;
  TaskName: string;
  DLLHandle: THandle;
  Status: TTaskStatus;
  StartTime: TDateTime;
  EndTime: TDateTime;
  Result: TTaskResult;
end;

type
  TForm1 = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

end.
