library ShellControl;

uses
  ShareMem,
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  PluginAPI in '..\PluginAPI.pas',
  ShellCommandsTasks in 'ShellCommandsTasks.pas';

//{$R *.res}

function GetPluginInterface: IPluginTasks; stdcall;
begin
  Result := TShellCommandPlugin.Create;
end;

exports
  GetPluginInterface;

begin
end.
