library FileOpers;

uses
  ShareMem,
  System.SysUtils,
  System.Classes,
  PluginAPI in '..\PluginAPI.pas',
  FileOperationsTasks in 'FileOperationsTasks.pas';

//{$R *.res}

function GetPluginInterface: IPluginTasks; stdcall;
begin
  Result := TFileOperationsPlugin.Create;
end;

exports
  GetPluginInterface;

begin
end.
