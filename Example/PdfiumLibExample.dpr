program PdfiumLibFMXExample;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  PdfiumCore in '..\Source\PdfiumCore.pas',
  PdfiumCtrl in '..\Source\PdfiumCtrl.pas',
  PdfiumLib in '..\Source\PdfiumLib.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
