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

    // ������ ���������� IPluginTasks
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
  // ��� ����������� ������� ��������� �������, ���� �� �������
  if FIsRunning then
    TerminateProcess(FProcessInfo.hProcess, 0);
  inherited;
end;

function TShellCommandPlugin.GetTasksCount: Integer; stdcall;
begin
  Result := 1;  // ���� ������ - ���������� shell-�������
end;

function TShellCommandPlugin.GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
begin
  if Index = 0 then
  begin
    Result.ID := 'ExecuteCmd';
    Result.Name := '��������� shell-�������';
    Result.Description := '��������� ������� � ��������� ������ Windows';
    SetLength(Result.Parameters, 1);
    Result.Parameters[0].Name := 'Command';
    Result.Parameters[0].Description := '������� ��� ���������� (��������, "dir /s")';
  end
  else
    raise Exception.Create('�������� ������ ������');
end;

procedure TShellCommandPlugin.ExecuteTask(const TaskID: string;
  Parameters: array of string; Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
var
  StartupInfo: TStartupInfo;
  CommandLine: string;
  Result: TTaskResult;
begin
  if TaskID <> 'ExecuteCmd' then
    raise Exception.Create('����������� ������: ' + TaskID);

  if Length(Parameters) < 1 then
    raise Exception.Create('�� ������� �������');

  FCancelRequested := False;
  FIsRunning := True;
  try
    CommandLine := 'cmd.exe /C ' + Parameters[0];

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;  // �������� ���� cmd

    // ������� �������
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

    // ������� ���������� �������� � ��������� ������
    while WaitForSingleObject(FProcessInfo.hProcess, 100) = WAIT_TIMEOUT do
    begin
      if FCancelRequested then
      begin
        TerminateProcess(FProcessInfo.hProcess, 0);
        Result.Success := False;
        Result.Message := '������ ��������';
        Callback(Result);
        Exit;
      end;
      if Assigned(ProgressCallback) then
        ProgressCallback(50, '���������� �������...');
    end;

    // �������� ����������
    Result.Success := True;
    Result.Message := '������� ���������';
    Callback(Result);

  finally
    CloseHandle(FProcessInfo.hProcess);
    CloseHandle(FProcessInfo.hThread);
    FIsRunning := False;
  end;
end;

function TShellCommandPlugin.CanCancelTask(const TaskID: string): Boolean; stdcall;
begin
  Result := True;  // ������������ ������
end;

procedure TShellCommandPlugin.CancelTask(const TaskID: string); stdcall;
begin
  FCancelRequested := True;
end;

end.1
