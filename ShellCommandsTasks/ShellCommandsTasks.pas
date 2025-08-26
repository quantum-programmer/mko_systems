unit ShellCommandsTasks;

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows,
  PluginAPI;

type
  TShellCommandPlugin = class(TInterfacedObject, IPluginTasks)
  private
    FProcessInfo: TProcessInformation;
    FIsRunning: Boolean;
    FCancelRequested: Boolean;
  public
    destructor Destroy; override;

    // Методы интерфейса IPluginTasks
    function GetTasksCount: Integer; stdcall;
    function GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
    procedure ExecuteTask(const TaskID: string; Parameters: array of string;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
    function CanCancelTask(const TaskID: string): Boolean; stdcall;
    procedure CancelTask(const TaskID: string); stdcall;
  end;

implementation

{ TShellCommandPlugin }

destructor TShellCommandPlugin.Destroy;
begin
  // При уничтожении объекта завершаем процесс, если он запущен
  if FIsRunning then
    TerminateProcess(FProcessInfo.hProcess, 0);
  inherited;
end;

function TShellCommandPlugin.GetTasksCount: Integer; stdcall;
begin
  Result := 1;  // Одна задача - выполнение shell-команды
end;

function TShellCommandPlugin.GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
begin
  if Index = 0 then
  begin
    Result.ID := 'ExecuteCmd';
    Result.Name := 'Выполнить shell-команду';
    Result.Description := 'Запускает команду в командной строке Windows';
    SetLength(Result.Parameters, 1);
    Result.Parameters[0].Name := 'Command';
    Result.Parameters[0].Description := 'Команда для выполнения (например, "dir /s")';
  end
  else
    raise Exception.Create('Неверный индекс задачи');
end;

procedure TShellCommandPlugin.ExecuteTask(const TaskID: string;
  Parameters: array of string; Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
var
  StartupInfo: TStartupInfo;
  CommandLine: string;
  Result: TTaskResult;
begin
  if TaskID <> 'ExecuteCmd' then
    raise Exception.Create('Неизвестная задача: ' + TaskID);

  if Length(Parameters) < 1 then
    raise Exception.Create('Не указана команда');

  FCancelRequested := False;
  FIsRunning := True;
  try
    CommandLine := 'cmd.exe /C ' + Parameters[0];

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;  // Скрываем окно cmd

    // Создаем процесс
    if not CreateProcess(
      nil,
      PChar(CommandLine),
      nil,
      nil,
      False,
      0,
      nil,
      nil,
      StartupInfo,
      FProcessInfo) then
    begin
      RaiseLastOSError;
    end;

    // Ожидаем завершения процесса с проверкой отмены
    while WaitForSingleObject(FProcessInfo.hProcess, 100) = WAIT_TIMEOUT do
    begin
      if FCancelRequested then
      begin
        TerminateProcess(FProcessInfo.hProcess, 0);
        Result.Success := False;
        Result.Message := 'Задача отменена';
        Callback(Result);
        Exit;
      end;
      if Assigned(ProgressCallback) then
        ProgressCallback(50, 'Выполнение команды...');
    end;

    // Успешное завершение
    Result.Success := True;
    Result.Message := 'Команда выполнена';
    Callback(Result);

  finally
    CloseHandle(FProcessInfo.hProcess);
    CloseHandle(FProcessInfo.hThread);
    FIsRunning := False;
  end;
end;

function TShellCommandPlugin.CanCancelTask(const TaskID: string): Boolean; stdcall;
begin
  Result := True;  // Поддерживаем отмену
end;

procedure TShellCommandPlugin.CancelTask(const TaskID: string); stdcall;
begin
  FCancelRequested := True;
end;

end.1
