unit FileOperationsTasks;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils,
  PluginAPI;

type
  TFileOperationsPlugin = class(TInterfacedObject, IPluginTasks)
  private
    FCancelRequested: Boolean;
  public
    // ������ ���������� IPluginTasks
    function GetTasksCount: Integer; stdcall;
    function GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
    procedure ExecuteTask(const TaskID: string; Parameters: array of string;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
    function CanCancelTask(const TaskID: string): Boolean; stdcall;
    procedure CancelTask(const TaskID: string); stdcall;
  end;

implementation

{ TFileOperationsPlugin }

function TFileOperationsPlugin.GetTasksCount: Integer;
begin
  Result := 2; // � ��� ��� ������: ����� ������ � ����� � �����
end;

function TFileOperationsPlugin.GetTaskInfo(Index: Integer): TTaskInfo;
begin
  case Index of
    0: begin
      Result.ID := 'FindFiles';
      Result.Name := '����� ������ �� �����';
      Result.Description := '���� ����� �� �������� ����� � ��������� �����';
      SetLength(Result.Parameters, 2);
      Result.Parameters[0].Name := 'Mask';
      Result.Parameters[0].Description := '����� ������ (��������, *.txt)';
      Result.Parameters[1].Name := 'StartDir';
      Result.Parameters[1].Description := '��������� ���������� ��� ������';
    end;
    1: begin
      Result.ID := 'FindInFile';
      Result.Name := '����� ������ � �����';
      Result.Description := '���� ��������� ����� � �����';
      SetLength(Result.Parameters, 2);
      Result.Parameters[0].Name := 'Pattern';
      Result.Parameters[0].Description := '����� ��� ������';
      Result.Parameters[1].Name := 'FileName';
      Result.Parameters[1].Description := '���� � ����� ��� ������';
    end;
  else
    raise Exception.Create('�������� ������ ������');
  end;
end;

procedure TFileOperationsPlugin.ExecuteTask(const TaskID: string;
  Parameters: array of string; Callback: TTaskCallback; ProgressCallback: TProgressCallback);
var
  Result: TTaskResult;
begin
  FCancelRequested := False;

  try
    if TaskID = 'FindFiles' then
    begin
      // ���������� ������ ������
      if Length(Parameters) < 2 then
        raise Exception.Create('������������ ����������');

      // ����� ����� ��� ������ ������
      Result.Success := True;
      Result.Message := '����� ������ ��������';
    end
    else if TaskID = 'FindInFile' then
    begin
      // ���������� ������ � �����
      if Length(Parameters) < 2 then
        raise Exception.Create('������������ ����������');

      // ����� ����� ��� ������ � �����
      Result.Success := True;
      Result.Message := '����� � ����� ��������';
    end
    else
      raise Exception.Create('����������� ������: ' + TaskID);

    Callback(Result);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.Message := E.Message;
      Callback(Result);
    end;
  end;
end;

function TFileOperationsPlugin.CanCancelTask(const TaskID: string): Boolean;
begin
  Result := True; // ���� ������ ������������ ������
end;

procedure TFileOperationsPlugin.CancelTask(const TaskID: string);
begin
  FCancelRequested := True;
end;

end.
