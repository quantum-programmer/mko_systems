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
    // Методы интерфейса IPluginTasks
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
  Result := 2; // У нас две задачи: поиск файлов и поиск в файле
end;

function TFileOperationsPlugin.GetTaskInfo(Index: Integer): TTaskInfo;
begin
  case Index of
    0: begin
      Result.ID := 'FindFiles';
      Result.Name := 'Поиск файлов по маске';
      Result.Description := 'Ищет файлы по заданной маске в указанной папке';
      SetLength(Result.Parameters, 2);
      Result.Parameters[0].Name := 'Mask';
      Result.Parameters[0].Description := 'Маска файлов (например, *.txt)';
      Result.Parameters[1].Name := 'StartDir';
      Result.Parameters[1].Description := 'Начальная директория для поиска';
    end;
    1: begin
      Result.ID := 'FindInFile';
      Result.Name := 'Поиск текста в файле';
      Result.Description := 'Ищет указанный текст в файле';
      SetLength(Result.Parameters, 2);
      Result.Parameters[0].Name := 'Pattern';
      Result.Parameters[0].Description := 'Текст для поиска';
      Result.Parameters[1].Name := 'FileName';
      Result.Parameters[1].Description := 'Путь к файлу для поиска';
    end;
  else
    raise Exception.Create('Неверный индекс задачи');
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
      // Реализация поиска файлов
      if Length(Parameters) < 2 then
        raise Exception.Create('Недостаточно параметров');

      // Здесь будет код поиска файлов
      Result.Success := True;
      Result.Message := 'Поиск файлов выполнен';
    end
    else if TaskID = 'FindInFile' then
    begin
      // Реализация поиска в файле
      if Length(Parameters) < 2 then
        raise Exception.Create('Недостаточно параметров');

      // Здесь будет код поиска в файле
      Result.Success := True;
      Result.Message := 'Поиск в файле выполнен';
    end
    else
      raise Exception.Create('Неизвестная задача: ' + TaskID);

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
  Result := True; // Наши задачи поддерживают отмену
end;

procedure TFileOperationsPlugin.CancelTask(const TaskID: string);
begin
  FCancelRequested := True;
end;

end.
