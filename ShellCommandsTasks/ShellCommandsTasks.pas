unit ShellCommandsTasks;

interface

uses
  System.Classes, System.SysUtils, Winapi.Windows,
  PluginAPI;

type
  TShellCommandPlugin = class(TInterfacedObject, IPluginTasks)
  private
    FCancelRequested: Boolean;
    FOutput: TStringList;
    FProgressValue: Integer;
    FProgressDirection: Integer;

    procedure ExecuteCommandInThread(const Command: string;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback);
  public
    constructor Create;
    destructor Destroy; override;

    function GetTasksCount: Integer; stdcall;
    function GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
    procedure ExecuteTask(const TaskID: string; Parameters: array of string;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
    function CanCancelTask(const TaskID: string): Boolean; stdcall;
    procedure CancelTask(const TaskID: string); stdcall;
  end;

implementation

{ TShellCommandPlugin }

constructor TShellCommandPlugin.Create;
begin
  inherited;
  FOutput := TStringList.Create;
  FProgressValue := 50;
  FProgressDirection := 1;
end;

destructor TShellCommandPlugin.Destroy;
begin
  FOutput.Free;
  inherited;
end;

function TShellCommandPlugin.GetTasksCount: Integer; stdcall;
begin
  Result := 1;
end;

function TShellCommandPlugin.GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
begin
  if Index = 0 then
  begin
    Result.ID := 'ExecuteCmd';
    Result.Name := '��������� shell-�������';
    Result.Description := '��������� ������� � ��������� ������ Windows � ���������� �����';
    SetLength(Result.Parameters, 1);
    Result.Parameters[0].Name := 'Command';
    Result.Parameters[0].Description := '������� ��� ���������� (��������, "dir", "systeminfo")';
  end
  else
    raise Exception.Create('�������� ������ ������');
end;

procedure TShellCommandPlugin.ExecuteCommandInThread(const Command: string;
  Callback: TTaskCallback; ProgressCallback: TProgressCallback);
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  SecurityAttr: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  Buffer: array[0..4095] of AnsiChar;
  BytesRead: DWORD;
  CommandLine: string;
  Result: TTaskResult;
begin
  FCancelRequested := False;
  FOutput.Clear;

  try
    // ������� pipe ��� ������� ������
    FillChar(SecurityAttr, SizeOf(TSecurityAttributes), 0);
    SecurityAttr.nLength := SizeOf(TSecurityAttributes);
    SecurityAttr.bInheritHandle := True;

    if not CreatePipe(ReadPipe, WritePipe, @SecurityAttr, 0) then
      RaiseLastOSError;

    try
      ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      StartupInfo.wShowWindow := SW_HIDE;
      StartupInfo.hStdOutput := WritePipe;
      StartupInfo.hStdError := WritePipe;

      CommandLine := 'cmd.exe /C ' + Command;

      // ������� �������
      if not CreateProcess(nil, PChar(CommandLine), nil, nil, True,
        0, nil, nil, StartupInfo, ProcessInfo) then
      begin
        RaiseLastOSError;
      end;

      try
        CloseHandle(WritePipe);

        // ��������� �������� �� 50% ��� ������
        if Assigned(ProgressCallback) then
          ProgressCallback(50, '������ �������...');

        // ������ ����� �������
        while not FCancelRequested do
        begin
          if not ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) then
            Break;

          if BytesRead = 0 then
            Break;

          // ����������� ����� � ������
          var OutputText: string;
          SetString(OutputText, PAnsiChar(@Buffer[0]), BytesRead);
          FOutput.Text := FOutput.Text + OutputText;

          // ��������� �������� (45-55%) �� ����� ����������
          if Assigned(ProgressCallback) then
          begin
            FProgressValue := FProgressValue + FProgressDirection;
            if (FProgressValue > 55) or (FProgressValue < 45) then
              FProgressDirection := -FProgressDirection;

            ProgressCallback(FProgressValue, '���������� �������...');
          end;

          // ��������� ����� ����� �� ������� CPU
          Sleep(100);
        end;

        // ������� ���������� ��������
        if not FCancelRequested then
          WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

        // ������������� �������� 100% ��� ����������
        if Assigned(ProgressCallback) then
        begin
          if FCancelRequested then
            ProgressCallback(100, '������ ��������')
          else
            ProgressCallback(100, '������� ��������� �������');
        end;

        // ��������� ���������
        Result.Success := not FCancelRequested;
        if FCancelRequested then
          Result.Message := '������ ��������'
        else
          Result.Message := FOutput.Text;

        // �������� callback
        Callback(Result);

      finally
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end;

    finally
      CloseHandle(ReadPipe);
    end;

  except
    on E: Exception do
    begin
      // ������������� �������� 100% ���� ��� ������
      if Assigned(ProgressCallback) then
        ProgressCallback(100, '������ ����������: ' + E.Message);

      Result.Success := False;
      Result.Message := E.Message;
      Callback(Result);
    end;
  end;
end;

procedure TShellCommandPlugin.ExecuteTask(const TaskID: string;
  Parameters: array of string; Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
var
  Command: string;
begin
  if TaskID <> 'ExecuteCmd' then
    raise Exception.Create('����������� ������: ' + TaskID);

  if Length(Parameters) < 1 then
    raise Exception.Create('�� ������� �������');

  // ��������� ������� � ��������� ���������� ��� �������
  Command := Parameters[0];

  // ��������� � ��������� ������ ����� �� ����������� ���������
  TThread.CreateAnonymousThread(
    procedure
    begin
      ExecuteCommandInThread(Command, Callback, ProgressCallback);
    end
  ).Start;
end;

function TShellCommandPlugin.CanCancelTask(const TaskID: string): Boolean; stdcall;
begin
  Result := True;
end;

procedure TShellCommandPlugin.CancelTask(const TaskID: string); stdcall;
begin
  FCancelRequested := True;
end;

end.
