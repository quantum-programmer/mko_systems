unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  PluginAPI, System.Generics.Collections, Vcl.Menus;

type

  TTaskStatus = (tsPending, tsRunning, tsCompleted, tsFailed, tsCancelled);

  TRunningTask = class
  public
    TaskID: string;
    TaskName: string;
    DLLName: string;
    Status: TTaskStatus;
    StartTime: TDateTime;
    EndTime: TDateTime;
    Result: TTaskResult;
    Thread: TThread;
  end;

  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    OpenDialog: TOpenDialog;
    PageControl1: TPageControl;
    tsAvailableTasks: TTabSheet;
    tsRunningTasks: TTabSheet;
    tsCompletedTasks: TTabSheet;
    Panel2: TPanel;
    Label1: TLabel;
    btnExecute: TButton;
    btnCancel: TButton;
    btnViewResults: TButton;
    Splitter1: TSplitter;
    MemoLog: TMemo;
    ProgressBar: TProgressBar;
    StatusBar: TStatusBar;
    ListBoxTasks: TListBox;
    ListViewRunning: TListView;
    ListViewCompleted: TListView;
    PopupMenu1: TPopupMenu;
    miExecuteTask: TMenuItem;
    miViewInfo: TMenuItem;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnViewResultsClick(Sender: TObject);
    procedure ListBoxTasksDblClick(Sender: TObject);
    procedure miExecuteTaskClick(Sender: TObject);
    procedure miViewInfoClick(Sender: TObject);
    procedure ListBoxTasksContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
  private
    { Private declarations }
    FDLLs: TDictionary<THandle, IPluginTasks>;
    FDLLNames: TDictionary<THandle, string>;
    FRunningTasks: TObjectList<TRunningTask>;
    FCompletedTasks: TObjectList<TRunningTask>;
    FTaskInfoList: TList<TTaskInfo>;

    procedure LoadDLL(const FileName: string);
    procedure UnloadAllDLLs;
    procedure UpdateTasksList;
    procedure UpdateRunningTasksList;
    procedure UpdateCompletedTasksList;
    procedure TaskCompletedCallback(Task: TRunningTask; const Result: TTaskResult);
    procedure ProgressCallback(Task: TRunningTask; Progress: Integer; const Message: string);
    procedure ExecuteSelectedTask;
    function CreateTaskThread(TaskInfo: TTaskInfo; DLLHandle: THandle; Plugin: IPluginTasks): TRunningTask;
    procedure ShowTaskInfo(TaskInfo: TTaskInfo);
    function GetParametersForTask(TaskInfo: TTaskInfo): TArray<string>;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


{ TTaskThread }

type
  TTaskThread = class(TThread)
  private
    FTask: TRunningTask;
    FPlugin: IPluginTasks;
    FParameters: TArray<string>;
    FTaskID: string;
    FCallback: TTaskCallback;
    FProgressCallback: TProgressCallback;
  protected
    procedure Execute; override;
  public
    constructor Create(Task: TRunningTask; Plugin: IPluginTasks;
      const TaskID: string; Parameters: TArray<string>;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback);
  end;

constructor TTaskThread.Create(Task: TRunningTask; Plugin: IPluginTasks;
  const TaskID: string; Parameters: TArray<string>;
  Callback: TTaskCallback; ProgressCallback: TProgressCallback);
begin
  inherited Create(True);
  FTask := Task;
  FPlugin := Plugin;
  FTaskID := TaskID;
  FParameters := Parameters; // сохраняем параметры
  FCallback := Callback;
  FProgressCallback := ProgressCallback;
  FreeOnTerminate := False;
end;

procedure TTaskThread.Execute;
begin
  try
    FPlugin.ExecuteTask(FTaskID, FParameters, FCallback, FProgressCallback);
  except
    on E: Exception do
    begin
      // Обработка ошибок выполнения задачи
      TThread.Synchronize(nil,
        procedure
        begin
          // Логирование ошибки
        end);
    end;
  end;
end;

{ **** TTaskThread **** }

procedure TForm1.btnCancelClick(Sender: TObject);
begin
  if ListViewRunning.Selected <> nil then
  begin
    var Task := FRunningTasks[ListViewRunning.Selected.Index];
    var DLLHandle := GetModuleHandle(PWideChar(Task.DLLName));
    if FDLLs.ContainsKey(DLLHandle) then
    begin
      var Plugin := FDLLs[DLLHandle];
      if Plugin.CanCancelTask(Task.TaskID) then
      begin
        Plugin.CancelTask(Task.TaskID);
        MemoLog.Lines.Add(Format('Отмена задачи: %s', [Task.TaskName]));
      end
      else
        ShowMessage('Эта задача не поддерживает отмену');
    end;
  end;
end;

procedure TForm1.btnExecuteClick(Sender: TObject);
begin
  ExecuteSelectedTask;
end;

procedure TForm1.btnViewResultsClick(Sender: TObject);
begin
  if ListViewCompleted.Selected <> nil then
  begin
    var Task := FCompletedTasks[ListViewCompleted.Selected.Index];
    ShowMessage(Format('Результат задачи %s:'#13#10'%s',
      [Task.TaskName, Task.Result.Message]));
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    try
      LoadDLL(OpenDialog.FileName);
      StatusBar.Panels[0].Text := 'DLL загружена: ' + ExtractFileName(OpenDialog.FileName);
    except
      on E: Exception do
        ShowMessage('Ошибка загрузки DLL: ' + E.Message);
    end;
  end;
end;

function TForm1.CreateTaskThread(TaskInfo: TTaskInfo; DLLHandle: THandle;
  Plugin: IPluginTasks): TRunningTask;
var
  Task: TRunningTask;
  Thread: TTaskThread;
  Parameters: TArray<string>;
begin
  // Получаем параметры для задачи
  Parameters := GetParametersForTask(TaskInfo);
  if Length(Parameters) = 0 then
  begin
    ShowMessage('Не указаны параметры для задачи');
    Exit(nil);
  end;

  Task := TRunningTask.Create;
  Task.TaskID := TaskInfo.ID;
  Task.TaskName := TaskInfo.Name;
  Task.DLLName := FDLLNames[DLLHandle];
  Task.Status := tsPending;
  Task.StartTime := Now;

  // Правильный вызов конструктора
  Thread := TTaskThread.Create(
    Task,
    Plugin,
    TaskInfo.ID,
    Parameters,
    // Callback для завершения задачи
    procedure(const Result: TTaskResult)
    begin
      TaskCompletedCallback(Task, Result);
    end,
    // Callback для прогресса
    procedure(Progress: Integer; const Message: string)
    begin
      ProgressCallback(Task, Progress, Message);
    end
  );

  Task.Thread := Thread;
  FRunningTasks.Add(Task);
  Result := Task;
end;

procedure TForm1.ExecuteSelectedTask;
var
  SelectedIndex: Integer;
  TaskInfo: TTaskInfo;
  Parameters: TArray<string>;
  Task: TRunningTask;
  DLLHandle: THandle;
  Plugin: IPluginTasks;
begin
  SelectedIndex := ListBoxTasks.ItemIndex;
  if SelectedIndex < 0 then Exit;

  TaskInfo := FTaskInfoList[SelectedIndex];

  // Получаем параметры от пользователя
  Parameters := GetParametersForTask(TaskInfo);
  if Length(Parameters) = 0 then Exit;

  // Находим DLL и плагин для этой задачи
  DLLHandle := 0;
  Plugin := nil;
  for var Handle in FDLLs.Keys do
  begin
    Plugin := FDLLs[Handle];
    for var I := 0 to Plugin.GetTasksCount - 1 do
    begin
      if Plugin.GetTaskInfo(I).ID = TaskInfo.ID then
      begin
        DLLHandle := Handle;
        Break;
      end;
    end;
    if DLLHandle <> 0 then Break;
  end;

  if not Assigned(Plugin) then
  begin
    ShowMessage('Не удалось найти плагин для задачи');
    Exit;
  end;

  // Создаем и запускаем задачу
  Task := CreateTaskThread(TaskInfo, DLLHandle, Plugin);
  Task.Thread.Start;

  MemoLog.Lines.Add(Format('Запущена задача: %s (%s)', [TaskInfo.Name, TaskInfo.ID]));
  UpdateRunningTasksList;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FDLLs := TDictionary<THandle, IPluginTasks>.Create;
  FDLLNames := TDictionary<THandle, string>.Create;
  FRunningTasks := TObjectList<TRunningTask>.Create(True);
  FCompletedTasks := TObjectList<TRunningTask>.Create(True);
  FTaskInfoList := TList<TTaskInfo>.Create;

  // Настройка интерфейса
  ListViewRunning.ViewStyle := vsReport;
  ListViewRunning.Columns.Add.Width := 150;
  ListViewRunning.Columns.Add.Width := 200;
  ListViewRunning.Columns.Add.Width := 100;
  ListViewRunning.Columns.Add.Width := 100;

  ListViewCompleted.ViewStyle := vsReport;
  ListViewCompleted.Columns.Add.Width := 150;
  ListViewCompleted.Columns.Add.Width := 200;
  ListViewCompleted.Columns.Add.Width := 100;
  ListViewCompleted.Columns.Add.Width := 100;
  ListViewCompleted.Columns.Add.Width := 100;

  StatusBar.Panels.Add.Width := 200;
  StatusBar.Panels.Add.Width := 100;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnloadAllDLLs;
  FDLLs.Free;
  FDLLNames.Free;
  FRunningTasks.Free;
  FCompletedTasks.Free;
  FTaskInfoList.Free;
end;

function TForm1.GetParametersForTask(TaskInfo: TTaskInfo): TArray<string>;
var
  I: Integer;
  ParamValue: string;
begin
  SetLength(Result, Length(TaskInfo.Parameters));
  for I := 0 to High(TaskInfo.Parameters) do
  begin
    ParamValue := InputBox('Параметр задачи',
      TaskInfo.Parameters[I].Description, '');
    if ParamValue = '' then
    begin
      ShowMessage('Все параметры обязательны для заполнения');
      SetLength(Result, 0);
      Exit;
    end;
    Result[I] := ParamValue;
  end;
end;

procedure TForm1.ListBoxTasksContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  miExecuteTask.Enabled := ListBoxTasks.ItemIndex >= 0;
  miViewInfo.Enabled := ListBoxTasks.ItemIndex >= 0;
end;

procedure TForm1.ListBoxTasksDblClick(Sender: TObject);
begin
  ExecuteSelectedTask;
end;

procedure TForm1.LoadDLL(const FileName: string);
var
  Handle: THandle;
  GetPluginFunc: function: IPluginTasks; stdcall;
  Plugin: IPluginTasks;
  I: Integer;
  TaskInfo: TTaskInfo;
begin
  Handle := LoadLibrary(PWideChar(FileName));
  if Handle = 0 then
    raise Exception.Create('Не удалось загрузить DLL: ' + FileName);

  @GetPluginFunc := GetProcAddress(Handle, 'GetPluginInterface');
  if not Assigned(GetPluginFunc) then
  begin
    FreeLibrary(Handle);
    raise Exception.Create('Не найден экспорт GetPluginInterface в DLL');
  end;

  Plugin := GetPluginFunc();
  if not Assigned(Plugin) then
  begin
    FreeLibrary(Handle);
    raise Exception.Create('DLL не вернула интерфейс IPluginTasks');
  end;

  FDLLs.Add(Handle, Plugin);
  FDLLNames.Add(Handle, ExtractFileName(FileName));

  // Получаем задачи из DLL
  for I := 0 to Plugin.GetTasksCount - 1 do
  begin
    TaskInfo := Plugin.GetTaskInfo(I);
    FTaskInfoList.Add(TaskInfo);
  end;

  UpdateTasksList;
end;

procedure TForm1.miExecuteTaskClick(Sender: TObject);
begin
  ExecuteSelectedTask;
end;

procedure TForm1.miViewInfoClick(Sender: TObject);
begin
  if ListBoxTasks.ItemIndex >= 0 then
    ShowTaskInfo(FTaskInfoList[ListBoxTasks.ItemIndex]);
end;

procedure TForm1.ProgressCallback(Task: TRunningTask; Progress: Integer;
  const Message: string);
begin
  TThread.Queue(nil, // Используем Queue вместо Synchronize для прогресса
    procedure
    begin
      ProgressBar.Position := Progress;
      StatusBar.Panels[1].Text := Format('%d%%', [Progress]);
      if Message <> '' then
        MemoLog.Lines.Add(Format('[%s] %s', [Task.TaskName, Message]));
    end);
end;

procedure TForm1.ShowTaskInfo(TaskInfo: TTaskInfo);
var
  InfoText: string;
  I: Integer;
begin
  InfoText := Format('Задача: %s'#13#10'ID: %s'#13#10'Описание: %s'#13#10#13#10'Параметры:',
    [TaskInfo.Name, TaskInfo.ID, TaskInfo.Description]);

  for I := 0 to High(TaskInfo.Parameters) do
  begin
    InfoText := InfoText + Format(#13#10'%d. %s: %s',
      [I + 1, TaskInfo.Parameters[I].Name, TaskInfo.Parameters[I].Description]);
  end;

  ShowMessage(InfoText);
end;

procedure TForm1.TaskCompletedCallback(Task: TRunningTask;
  const Result: TTaskResult);
begin
    Task.Result := Result;
    Task.EndTime := Now;
    if Result.Success then
      Task.Status := tsCompleted
    else
      Task.Status := tsFailed;

    FRunningTasks.Remove(Task);
    FCompletedTasks.Add(Task);

    MemoLog.Lines.Add(Format('Задача завершена: %s - %s',
      [Task.TaskName, Result.Message]));

    UpdateRunningTasksList;
    UpdateCompletedTasksList;

    Task.Thread.Free;
end;

procedure TForm1.UnloadAllDLLs;
var
  Handle: THandle;
begin
  // Отменяем все выполняющиеся задачи
  for var Task in FRunningTasks do
  begin
    if Task.Status = tsRunning then
    begin
      var Plugin: IPluginTasks;
      if FDLLs.TryGetValue(GetModuleHandle(PWideChar(Task.DLLName)), Plugin) then
      begin
        if Plugin.CanCancelTask(Task.TaskID) then
          Plugin.CancelTask(Task.TaskID);
      end;
    end;
  end;

  // Выгружаем все DLL
  for Handle in FDLLs.Keys do
  begin
    FreeLibrary(Handle);
  end;
  FDLLs.Clear;
  FDLLNames.Clear;
  FTaskInfoList.Clear;

end;

procedure TForm1.UpdateCompletedTasksList;
begin
  ListViewCompleted.Items.BeginUpdate;
  try
    ListViewCompleted.Items.Clear;
    for var Task in FCompletedTasks do
    begin
      with ListViewCompleted.Items.Add do
      begin
        Caption := Task.TaskName;
        SubItems.Add(Task.DLLName);
        SubItems.Add(FormatDateTime('hh:nn:ss', Task.StartTime));
        SubItems.Add(FormatDateTime('hh:nn:ss', Task.EndTime));
        case Task.Status of
          tsCompleted: SubItems.Add('Успешно');
          tsFailed: SubItems.Add('Ошибка');
          tsCancelled: SubItems.Add('Отменено');
        end;
      end;
    end;
  finally
    ListViewCompleted.Items.EndUpdate;
  end;
end;

procedure TForm1.UpdateRunningTasksList;
begin
  ListViewRunning.Items.BeginUpdate;
  try
    ListViewRunning.Items.Clear;
    for var Task in FRunningTasks do
    begin
      with ListViewRunning.Items.Add do
      begin
        Caption := Task.TaskName;
        SubItems.Add(Task.DLLName);
        SubItems.Add(FormatDateTime('hh:nn:ss', Task.StartTime));
        case Task.Status of
          tsRunning: SubItems.Add('Выполняется');
          tsPending: SubItems.Add('Ожидание');
        end;
      end;
    end;
  finally
    ListViewRunning.Items.EndUpdate;
  end;
end;

procedure TForm1.UpdateTasksList;
begin
  ListBoxTasks.Clear;
  for var TaskInfo in FTaskInfoList do
  begin
    ListBoxTasks.Items.Add(TaskInfo.Name + ' (' + TaskInfo.ID + ')');
  end;
  btnExecute.Enabled := ListBoxTasks.ItemIndex >= 0;
end;

end.
