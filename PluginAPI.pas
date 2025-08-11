unit PluginAPI;

interface

uses
  System.Classes, System.SysUtils;

type
  TTaskParameter = record
    Name: string;
    Value: string;
    Description: string;
  end;

  TTaskInfo = record
    ID: string;
    Name: string;
    Description: string;
    Parameters: array of TTaskParameter;
  end;

  TTaskResult = record
    Success: Boolean;
    Message: string;
    Data: TObject; // Для произвольных данных результатов
  end;

  TProgressCallback = procedure(Progress: Integer; const Message: string) of object;
  TTaskCallback = procedure(const Result: TTaskResult) of object;

  // Интерфейс, который должна реализовывать каждая DLL
  IPluginTasks = interface
    ['{3B5A7C2F-1A4D-4A5B-9E3D-8C1E6F2A7B9C}'] // GUID обязателен
    function GetTasksCount: Integer; stdcall;
    function GetTaskInfo(Index: Integer): TTaskInfo; stdcall;
    procedure ExecuteTask(const TaskID: string; Parameters: array of string;
      Callback: TTaskCallback; ProgressCallback: TProgressCallback); stdcall;
    function CanCancelTask(const TaskID: string): Boolean; stdcall;
    procedure CancelTask(const TaskID: string); stdcall;
  end;

implementation

end.
