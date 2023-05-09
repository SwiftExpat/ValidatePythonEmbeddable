program ValidateP4DFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmValidateP4DFMXU in 'frmValidateP4DFMXU.pas' {frmValidateP4D};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmValidateP4D, frmValidateP4D);
  Application.Run;
end.
