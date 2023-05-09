unit frmValidateP4DVCLU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.TypInfo,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.TMSFNCTypes, Vcl.TMSFNCUtils, Vcl.TMSFNCGraphics, Vcl.TMSFNCGraphicsTypes,
  Vcl.TMSFNCCustomControl, Vcl.TMSFNCStatusBar, Vcl.TMSFNCToolBar, Vcl.TMSFNCPageControl, Vcl.TMSFNCTabSet,
  Vcl.TMSFNCTreeViewBase, Vcl.TMSFNCTreeViewData, Vcl.TMSFNCCustomTreeView, Vcl.TMSFNCTreeView,
  Vcl.TMSFNCObjectInspector, PythonEngine, Vcl.TMSFNCCustomComponent, Vcl.TMSFNCTaskDialog, Vcl.StdCtrls,
  Vcl.PythonGUIInputOutput, Vcl.ExtCtrls, Vcl.TMSFNCSplitter;

type
  TfrmValidateP4D = class(TForm)
    TMSFNCStatusBar1: TTMSFNCStatusBar;
    TMSFNCToolBar1: TTMSFNCToolBar;
    pcMain: TTMSFNCPageControl;
    TMSFNCPageControl1Page0: TTMSFNCPageControlContainer;
    TMSFNCPageControl1Page1: TTMSFNCPageControlContainer;
    TMSFNCPageControl1Page2: TTMSFNCPageControlContainer;
    PythonEngine1: TPythonEngine;
    objInspector: TTMSFNCObjectInspector;
    btnPyEngLoadDll: TTMSFNCToolBarButton;
    btnPyEngBrowseDLL: TTMSFNCToolBarButton;
    btnPyEngUnloadDLL: TTMSFNCToolBarButton;
    TaskDialog: TTMSFNCTaskDialog;
    PythonGUIInputOutput1: TPythonGUIInputOutput;
    memoIDEResult: TMemo;

    TMSFNCToolBar2: TTMSFNCToolBar;
    btnIDEExecute: TTMSFNCToolBarButton;
    Splitter1: TSplitter;
    tvEngine: TTMSFNCTreeView;
    memoPip: TMemo;
    memoIDECmd: TMemo;
    TMSFNCSplitter1: TTMSFNCSplitter;

    procedure FormCreate(Sender: TObject);
    procedure objInspectorReadProperty(Sender, AObject: TObject; APropertyInfo: PPropInfo; APropertyName: string;
      APropertyType: TTypeKind; var ACanRead: Boolean);
    procedure objInspectorWritePropertyValue(Sender, AObject: TObject; APropertyInfo: PPropInfo; APropertyName: string;
      APropertyType: TTypeKind; var APropertyValue: string; var ACanWrite: Boolean);
    procedure objInspectorPropertyValueChanged(Sender, AObject: TObject; APropertyInfo: PPropInfo;
      APropertyName: string; APropertyType: TTypeKind; APropertyValue: string);
    procedure btnPyEngLoadDllClick(Sender: TObject);
    procedure PythonEngine1BeforeLoad(Sender: TObject);
    procedure PythonEngine1BeforeUnload(Sender: TObject);
    procedure PythonEngine1AfterLoad(Sender: TObject);
    procedure PythonEngine1AfterInit(Sender: TObject);
    procedure PythonEngine1PathInitialization(Sender: TObject; var Path: string);
    procedure PythonEngine1SysPathInit(Sender: TObject; PathList: PPyObject);
    procedure TaskDialogDialogResult(Sender: TObject; AModalResult: TModalResult);
    procedure btnPyEngBrowseDLLClick(Sender: TObject);
    procedure btnPyEngUnloadDLLClick(Sender: TObject);
    procedure btnIDEExecuteClick(Sender: TObject);
  strict private
    FStatusText: TTMSFNCStatusBarPanel;
    FSysPathNode, FSysVersionNode, FSysExecutableNode: TTMSFNCTreeViewNode;
    procedure AssignObjectInspector;
    procedure CreateLogger;
    procedure StatusMessage(AMessage: string; ASuccess: Boolean = true);
    procedure ShowBrowseDLL;
    procedure InitEngineTree;
    procedure PythonEngineInitVar(const AVarName: string; var AVar: TPythonDelphiVar);
    procedure PythonEngineQueryDetails;
    procedure PythonEngineQueryPIP;
    procedure PythonEngineQueryPackages;
  private
    procedure InitPyEngineEmbedded;
    function PyEnginePathValid: Boolean;
    procedure PyEngineSetDLL(const AFile: string; const AResult: Boolean);
  public
    { Public declarations }
  end;

var
  frmValidateP4D: TfrmValidateP4D;

implementation

{$R *.dfm}

uses System.IOUtils, Vcl.SEFNC.Logger, Vcl.SEFNC.CVLoggerViewer;

{ TfrmValidateP4D }

procedure TfrmValidateP4D.FormCreate(Sender: TObject);
begin
  CreateLogger;
  memoIDECmd.Lines.Clear;
  memoIDEResult.Lines.Clear;
  memoPip.Lines.Clear;
  FStatusText := TMSFNCStatusBar1.Panels.Add;
  InitEngineTree;
  InitPyEngineEmbedded;
  pcMain.ActivePageIndex := 1;
  AssignObjectInspector;
end;

procedure TfrmValidateP4D.CreateLogger;
var
  lv: TSEFNCLogViewer;
  pg: TTMSFNCPageControlPage;
begin
  pg := pcMain.AddPage('Logger');
  lv := TSEFNCLogViewer.Create(pg.Container);
  lv.Parent := pg.Container;
  lv.Active := true;
end;

procedure TfrmValidateP4D.ShowBrowseDLL;
  function FilterString(const AFileExt: string): string;
  begin
    result := AFileExt.ToUpper + ' Files (*.' + AFileExt.ToLower + ')|*.' + AFileExt.ToUpper
  end;

var
  fn: string;
begin
  TTMSFNCUtils.SelectFile(fn, '', FilterString('DLL'), PyEngineSetDLL);
  Logger.Info('Browse = ' + fn, self)
end;

procedure TfrmValidateP4D.StatusMessage(AMessage: string; ASuccess: Boolean = true);
  function MsgColorAlert: string;
  begin
    result := '<FONT color="#FF0000">' + AMessage + '</FONT>';
  end;

begin
  if ASuccess then
    FStatusText.Text := AMessage
  else
    FStatusText.Text := MsgColorAlert;
  Logger.Debug('Status changed to ' + AMessage, self);
end;

procedure TfrmValidateP4D.TaskDialogDialogResult(Sender: TObject; AModalResult: TModalResult);
begin
  if AModalResult = 100 then
    ShowBrowseDLL;
end;

procedure TfrmValidateP4D.InitEngineTree;
begin
  tvEngine.Nodes.Clear;
  FSysExecutableNode := tvEngine.AddNode(nil);
  FSysExecutableNode.Text[0] := 'Executable';
  FSysExecutableNode.Extended := true;

  FSysPathNode := tvEngine.AddNode(nil);
  FSysPathNode.Text[0] := 'SysPath';
  FSysPathNode.Extended := true;

  FSysVersionNode := tvEngine.AddNode(nil);
  FSysVersionNode.Text[0] := 'Version';
  FSysVersionNode.Extended := true;

end;

/// <summary>Modify the component defaults to work with PyEmbedded</summary>
/// <remarks>Disables autoload and discovering a python version</remarks>
procedure TfrmValidateP4D.InitPyEngineEmbedded;
begin
  PythonEngine1.AutoLoad := false;
  PythonEngine1.FatalAbort := false;
  PythonEngine1.UseLastKnownVersion := false;
  PythonEngine1.InitScript.Add('import os');
  btnPyEngLoadDll.Enabled := false;
end;

procedure TfrmValidateP4D.AssignObjectInspector;
begin
  objInspector.&Object := PythonEngine1;
end;

procedure TfrmValidateP4D.btnIDEExecuteClick(Sender: TObject);
begin
  memoIDEResult.Lines.Clear;
  PythonEngine1.ExecStrings(memoIDECmd.Lines);
end;

procedure TfrmValidateP4D.btnPyEngBrowseDLLClick(Sender: TObject);
begin
  ShowBrowseDLL;
  if PyEnginePathValid then
    btnPyEngLoadDll.Enabled := true;
end;

procedure TfrmValidateP4D.btnPyEngLoadDllClick(Sender: TObject);
begin
  Logger.Debug('Begin DLL Load');
  StatusMessage('Python Loading');
  try
    btnPyEngUnloadDLL.Enabled := true;
    if PyEnginePathValid then
      PythonEngine1.LoadDll;
    PythonEngineQueryDetails;
    btnPyEngLoadDll.Enabled := false;
  except
    on E: Exception do
    begin
      Logger.Error('Failed Engine load', E, self);
      StatusMessage('Failed Python Load', false);
    end
    else
      Logger.Error('Failed Engine load - other exception', self);
  end;
end;

procedure TfrmValidateP4D.btnPyEngUnloadDLLClick(Sender: TObject);
begin
  try
    PythonEngine1.UnloadDll;
    btnPyEngLoadDll.Enabled := true;
    btnPyEngUnloadDLL.Enabled := false;
  except
    on E: Exception do
    begin
      Logger.Error('Failed Engine Unload', E, self);
      StatusMessage('Failed Python UnLoad');
    end
    else
      Logger.Error('Failed Engine Unload - other exception', self);
  end;
end;

function TfrmValidateP4D.PyEnginePathValid: Boolean;
  procedure ShowErrorDialog;
  begin
    TaskDialog.Icon := TTMSFNCTaskDialogIcon.tdiError;
    TaskDialog.CustomButtons.Clear;
    TaskDialog.CustomButtons.Add('Browse Python DLL');
    TaskDialog.CustomButtons.Add('Cancel');
    if PythonEngine1.DllPath.IsEmpty then
    begin
      TaskDialog.Title := 'Directory Not Set on Engine component';
      TaskDialog.Instruction := 'Python Directory is empty';
      TaskDialog.Content := 'Directory  is empty on component settings';
    end
    else
    begin
      TaskDialog.Title := 'Directory Not found';
      TaskDialog.Instruction := 'Python Directory not found';
      TaskDialog.Content := 'Directory = ' + PythonEngine1.DllPath;
    end;
    TaskDialog.Execute;
  end;

var
  fn: string;
begin
  result := false;
  if TDirectory.exists(PythonEngine1.DllPath) then
  begin
    fn := TPath.Combine(PythonEngine1.DllPath, PythonEngine1.DllName);
    result := TFile.exists(fn);
    if result then
      Logger.Info('Python Dll exists @ ' + fn, self)
    else
      Logger.Error('Python Dll not found @ ' + fn, self);
  end
  else
    ShowErrorDialog;
end;

procedure TfrmValidateP4D.PyEngineSetDLL(const AFile: string; const AResult: Boolean);
var
  dn, fn: string;
begin
  if not AResult then
    StatusMessage('Browse DLL Canceled')
  else if TFile.exists(AFile) then
  begin
    dn := TPath.GetDirectoryName(AFile);
    Logger.Info('Selected Directory for dll is' + dn, self);
    PythonEngine1.DllPath := dn;
    fn := TPath.GetFileName(AFile);
    PythonEngine1.DllName := fn;
    StatusMessage('Dll paths updated');
    AssignObjectInspector;
  end
  else
    StatusMessage('File does not exist');
end;

procedure TfrmValidateP4D.PythonEngine1AfterInit(Sender: TObject);
begin
  Logger.Info('Engine Event After Init', Sender);
end;

procedure TfrmValidateP4D.PythonEngine1AfterLoad(Sender: TObject);
begin
  Logger.Info('Engine Event After Load', Sender);
  StatusMessage('Python Loaded successfully');
end;

procedure TfrmValidateP4D.PythonEngine1BeforeLoad(Sender: TObject);
begin
  Logger.Info('Engine Event Before Load', Sender);
end;

procedure TfrmValidateP4D.PythonEngine1BeforeUnload(Sender: TObject);
begin
  Logger.Info('Engine Event Before UnLoad', Sender);
end;

procedure TfrmValidateP4D.PythonEngine1PathInitialization(Sender: TObject; var Path: string);
begin

  Logger.Info('Engine Event Path Initialization', Sender);
  Logger.Info('Path = ' + Path, Sender);
end;

procedure TfrmValidateP4D.PythonEngine1SysPathInit(Sender: TObject; PathList: PPyObject);
var
  pi: TStringList;
  p: string;
  pn: TTMSFNCTreeViewNode;
begin
  pi := TStringList.Create;
  try
    Logger.Info('Engine Event Sys Path Init', Sender);
    PythonEngine1.PyListToStrings(PathList, pi);
    for p in pi do
    begin
      Logger.Debug('Path item = ' + p, Sender);
      pn := tvEngine.AddNode(FSysPathNode);
      pn.Text[0] := p;
    end;
    FSysPathNode.Expand(true);
  finally
    pi.Free;
  end;
end;

procedure TfrmValidateP4D.PythonEngineInitVar(const AVarName: string; var AVar: TPythonDelphiVar);
begin
  AVar := TPythonDelphiVar.Create(nil);
  AVar.Engine := PythonEngine1;
  AVar.Module := PythonEngine1.ExecModule;
  AVar.VarName := AnsiString(AVarName);
  AVar.Initialize;
  AVar.Value := 'ver';
end;

procedure TfrmValidateP4D.PythonEngineQueryDetails;
  procedure InitScript(var AScript: TStringList);
  begin
    AScript.Clear;
    AScript.Add('import sys');
    AScript.Add('rsver.Value = (sys.version)');
    AScript.Add('rsexnm.Value = (sys.executable)');
    AScript.Add('print("Version = " +rsver.Value)');
    AScript.Add('print("Executable = "+rsexnm.Value)');
  end;

var
  script: TStringList;
  tn: TTMSFNCTreeViewNode;
  pvver, pvexnm: TPythonDelphiVar;
begin
  script := TStringList.Create;
  PythonEngineInitVar('rsver', pvver);
  PythonEngineInitVar('rsexnm', pvexnm);
  try
    InitScript(script);
    PythonEngine1.ExecStrings(script);
    // version
    tn := tvEngine.AddNode(FSysVersionNode);
    tn.Text[0] := pvver.ValueAsString;
    FSysVersionNode.Expand(false);
    // Executable
    tn := tvEngine.AddNode(FSysExecutableNode);
    tn.Text[0] := pvexnm.ValueAsString;
    FSysExecutableNode.Expand(false);

  finally
    script.Free;
    pvver.Finalize; // prevent memory leak
    pvver.Free;
    pvexnm.Finalize; // prevent memory leak
    pvexnm.Free;
  end;
  PythonEngineQueryPackages;
end;

procedure TfrmValidateP4D.PythonEngineQueryPackages;
begin
  PythonEngineQueryPIP;
end;

procedure TfrmValidateP4D.PythonEngineQueryPIP;
  procedure InitScript(var AScript: TStringList);
  var
    pnm: string;
  begin // query pthon sys package for base dir?
    pnm := TPath.Combine(PythonEngine1.DllPath, 'python.exe');
    AScript.Clear;
    AScript.Add('import subprocess');
    AScript.Add('import sys');
    AScript.Add('def pip_list():');
    AScript.Add('    args = ["' + pnm + '", "-m", "pip", "list", "-v"]');
    AScript.Add('    p = subprocess.run(args, check=True, capture_output=True)');
    AScript.Add('    return p.stdout.decode()');
    AScript.Add('rspip.Value = pip_list()');
    // AScript.Add('print(rspip.Value)');
  end;

var
  script: TStringList;
  pvpip: TPythonDelphiVar;
begin
  script := TStringList.Create;
  PythonEngineInitVar('rspip', pvpip);
  try
    InitScript(script);
    PythonEngine1.ExecStrings(script);
    memoPip.Lines.Add(pvpip.ValueAsString);
  finally
    script.Free;
    pvpip.Finalize; // prevent memory leak
    pvpip.Free;
  end;
end;

procedure TfrmValidateP4D.objInspectorPropertyValueChanged(Sender, AObject: TObject; APropertyInfo: PPropInfo;
  APropertyName: string; APropertyType: TTypeKind; APropertyValue: string);
begin
  Logger.Info(APropertyName + ' changed value to : ' + APropertyValue);
  AssignObjectInspector;
end;

procedure TfrmValidateP4D.objInspectorReadProperty(Sender, AObject: TObject; APropertyInfo: PPropInfo;
  APropertyName: string; APropertyType: TTypeKind; var ACanRead: Boolean);
begin
  if APropertyName = 'Tag' then
    ACanRead := false;
end;

procedure TfrmValidateP4D.objInspectorWritePropertyValue(Sender, AObject: TObject; APropertyInfo: PPropInfo;
  APropertyName: string; APropertyType: TTypeKind; var APropertyValue: string; var ACanWrite: Boolean);
begin
  if APropertyName = 'AutoLoad' then
    ACanWrite := false
  else if APropertyName = 'Name' then
    ACanWrite := false;
end;

{$IFDEF DEBUG}

initialization

ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.
