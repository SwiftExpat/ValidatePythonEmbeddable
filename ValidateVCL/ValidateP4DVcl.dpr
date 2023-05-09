program ValidateP4DVcl;

uses
  Vcl.Forms,
  frmValidateP4DVCLU in 'frmValidateP4DVCLU.pas' {frmValidateP4D};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmValidateP4D, frmValidateP4D);
  Application.Run;
end.
