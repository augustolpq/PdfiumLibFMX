unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Layouts, FMX.ListView, PdfiumCore, PdfiumCtrlFMX, FMX.Printer;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    ListViewAttachments: TListView;
    Layout1: TLayout;
    btnPrev: TButton;
    btnNext: TButton;
    btnHighlight: TButton;
    btnScale: TButton;
    btnPrint: TButton;
    btnAddAnnotation: TButton;
    chkLCDOptimize: TCheckBox;
    chkSmoothScroll: TCheckBox;
    edtZoom: TSpinBox;
    chkChangePageOnMouseScrolling: TCheckBox;
    PrintDialog1: TPrintDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnHighlightClick(Sender: TObject);
    procedure btnScaleClick(Sender: TObject);
    procedure chkChangePageOnMouseScrollingClick(Sender: TObject);
    procedure chkLCDOptimizeClick(Sender: TObject);
    procedure edtZoomChange(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure ListViewAttachmentsDblClick(Sender: TObject);
    procedure btnAddAnnotationClick(Sender: TObject);
  private
    FCtrl: TPdfControl;
    procedure WebLinkClick(Sender: TObject; Url: string);
    procedure AnnotationLinkClick(Sender: TObject; LinkInfo: TPdfLinkInfo; var Handled: Boolean);
    procedure PrintDocument(Sender: TObject);
    procedure ListAttachments;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
begin
  {$IFDEF CPUX64}
  //PDFiumDllDir := ExtractFilePath(ParamStr(0)) + 'x64\V8XFA';
  PDFiumDllDir := ExtractFilePath(ParamStr(0)) + 'x64';
  {$ELSE}
  //PDFiumDllDir := ExtractFilePath(ParamStr(0)) + 'x86\V8XFA';
  PDFiumDllDir := ExtractFilePath(ParamStr(0)) + 'x86';
  {$ENDIF CPUX64}

  FCtrl := TPdfControl.Create(Self);
  FCtrl.Align := TAlignLayout.Client;
  FCtrl.Parent := Self;
  FCtrl.SendToBack; // put the control behind the buttons
//  FCtrl.Color := TAlphaColors.Gray;
  //FCtrl.Color := TAlphaColors.White;
  //FCtrl.PageBorderColor := clBlack;
  //FCtrl.PageShadowColor := clDkGray;
  FCtrl.ScaleMode := smFitWidth;
  //FCtrl.PageColor := RGB(255, 255, 200);
  FCtrl.OnWebLinkClick := WebLinkClick; // disabled due to loTreatWebLinkAsUriAnnotationLink + loAutoOpenURI
  FCtrl.OnAnnotationLinkClick := AnnotationLinkClick;
  FCtrl.LinkOptions := FCtrl.LinkOptions - [loAutoOpenURI] {+ cPdfControlAllAutoLinkOptions};
  FCtrl.OnPrintDocument := PrintDocument;

  edtZoom.Value := FCtrl.ZoomPercentage;

  if FileExists(ParamStr(1)) then
    FCtrl.LoadFromFile(ParamStr(1))
  else if OpenDialog1.Execute then
    FCtrl.LoadFromFile(OpenDialog1.FileName)
  else
    Application.Terminate;

  ListAttachments;
end;

procedure TForm1.ListAttachments;
var
  I: Integer;
  Att: TPdfAttachment;
  ListItem: TListItem;
begin
  if (FCtrl.Document <> nil) and FCtrl.Document.Active then
  begin
    ListViewAttachments.Visible := FCtrl.Document.Attachments.Count > 0;

    ListViewAttachments.Items.BeginUpdate;
    try
      for I := 0 to FCtrl.Document.Attachments.Count - 1 do
      begin
        Att := FCtrl.Document.Attachments[I];
        ListItem := ListViewAttachments.Items.Add;
//        ListItem.Caption := Format('%s (%d Bytes)', [Att.Name, Att.ContentSize]);
      end;
    finally
      ListViewAttachments.Items.EndUpdate;
    end;
  end;
end;

procedure TForm1.ListViewAttachmentsDblClick(Sender: TObject);
var
  Att: TPdfAttachment;
begin
  if ListViewAttachments.Selected <> nil then
  begin
    Att := FCtrl.Document.Attachments[ListViewAttachments.Selected.Index];
    SaveDialog1.FileName := Att.Name;
    if SaveDialog1.Execute then
      Att.SaveToFile(SaveDialog1.FileName);
  end;
end;

procedure TForm1.btnPrevClick(Sender: TObject);
begin
  FCtrl.GotoPrevPage;
end;

procedure TForm1.btnPrintClick(Sender: TObject);
{var
  PdfPrinter: TPdfDocumentPrinter;}
begin
  FCtrl.PrintDocument; // calls OnPrintDocument->PrintDocument
  //TPdfDocumentVclPrinter.PrintDocument(FCtrl.Document, 'PDF Example Print Job');

{  PrintDialog1.MinPage := 1;
  PrintDialog1.MaxPage := FCtrl.Document.PageCount;

  if PrintDialog1.Execute(Handle) then
  begin
    PdfPrinter := TPdfDocumentVclPrinter.Create;
    try
      //PdfPrinter.FitPageToPrintArea := False;

      if PrintDialog1.PrintRange = prAllPages then
        PdfPrinter.Print(FCtrl.Document)
      else
        PdfPrinter.Print(FCtrl.Document, PrintDialog1.FromPage - 1, PrintDialog1.ToPage - 1); // zero-based PageIndex
    finally
      PdfPrinter.Free;
    end;
  end;}
end;

procedure TForm1.btnNextClick(Sender: TObject);
begin
  FCtrl.GotoNextPage;
end;

procedure TForm1.btnHighlightClick(Sender: TObject);
begin
  FCtrl.ClearHighlightText;
  FCtrl.AddHightlightText('the', False, True);
  FCtrl.AddHightlightText('in', False, True);
end;

procedure TForm1.btnScaleClick(Sender: TObject);
begin
  if FCtrl.ScaleMode = High(FCtrl.ScaleMode) then
    FCtrl.ScaleMode := Low(FCtrl.ScaleMode)
  else
    FCtrl.ScaleMode := Succ(FCtrl.ScaleMode);
//  Caption := GetEnumName(TypeInfo(TPdfControlScaleMode), Ord(FCtrl.ScaleMode));
end;

procedure TForm1.chkLCDOptimizeClick(Sender: TObject);
begin
  if chkLCDOptimize.IsChecked then
    FCtrl.DrawOptions := FCtrl.DrawOptions + [proLCDOptimized]
  else
    FCtrl.DrawOptions := FCtrl.DrawOptions - [proLCDOptimized];
end;

procedure TForm1.edtZoomChange(Sender: TObject);
begin
  FCtrl.ZoomPercentage := Trunc(edtZoom.Value);
end;

procedure TForm1.chkChangePageOnMouseScrollingClick(Sender: TObject);
begin
  FCtrl.ChangePageOnMouseScrolling := chkChangePageOnMouseScrolling.IsChecked;
end;

procedure TForm1.WebLinkClick(Sender: TObject; Url: string);
begin
  ShowMessage(Url);
end;

procedure TForm1.AnnotationLinkClick(Sender: TObject; LinkInfo: TPdfLinkInfo; var Handled: Boolean);
begin
  Handled := True;
  case LinkInfo.LinkType of
    //altURI:
    //  ShowMessage('URL: ' + LinkAnnotation.LinkUri);

    //altLaunch:
    //  ShowMessage('Launch: ' + LinkAnnotation.LinkFileName);

    altEmbeddedGoto:
      ShowMessage('EmbeddedGoto: ' + LinkInfo.LinkUri);
  else
    Handled := False;
  end;
end;

procedure TForm1.PrintDocument(Sender: TObject);
begin
  TPdfDocumentVclPrinter.PrintDocument(FCtrl.Document, ExtractFileName(FCtrl.Document.FileName));
end;

procedure TForm1.btnAddAnnotationClick(Sender: TObject);
begin
  // Add a new annotation and make it persistent, so that it can be shown and saved to a file.
  FCtrl.CurrentPage.Annotations.NewTextAnnotation('My Annotation Text', TPdfRect.New(200, 750, 250, 700));
  FCtrl.CurrentPage.ApplyChanges;
//  FCtrl.Document.SaveToFile(ExtractFileDir(ParamStr(0)) + PathDelim + 'Test_annot.pdf');

  // Invalid the buffered image of the page
  FCtrl.InvalidatePage;
end;

end.
