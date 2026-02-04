{$IFDEF FPC}
  {$MODE DelphiUnicode}
{$ENDIF FPC}

{$A8,B-,E-,F-,G+,H+,I+,J-,K-,M-,N-,P+,Q-,R-,S-,T-,U-,V+,X+,Z1}
{$STRINGCHECKS OFF}

unit PdfiumCtrlFMX;

// Show invalidated paint regions. Don't enable this if you aren't trying to optimize the repainting
{.$DEFINE REPAINTTEST}

{$IFDEF FPC}
  {$DEFINE USE_PRINTCLIENT_WORKAROUND}
{$ELSE}
  {$IF CompilerVersion <= 20.0} // 2009 and older
    {$DEFINE USE_PRINTCLIENT_WORKAROUND}
  {$IFEND}
  {$IF CompilerVersion >= 21.0} // 2010+
    {$DEFINE VCL_HAS_TOUCH}
  {$IFEND}
{$ENDIF FPC}

interface

uses
  {$IFDEF FPC}
  LCLType, PrintersDlgs, Win32Extra,
  {$ENDIF FPC}
  {$IFDEF MSWINDOWS}
  Windows, Messages, ShellAPI,
  {$ENDIF MSWINDOWS}
  Types, SysUtils, Classes, Contnrs, FMX.Graphics, System.UITypes, FMX.Controls, FMX.Types,
  FMX.Forms, FMX.Dialogs, PdfiumCore;

type
  TPdfControlLinkOptionType = (
    loAutoGoto,                        // Jumps in the document are allowed and automatically handled
    loAutoRemoteGotoReplaceDocument,   // Jumps to a remote document are allowed and automatically handled by replacing the loaded document
    loAutoOpenURI,                     // Jumps to URI are allowed and automatically handled by using ShellExecuteEx. Disables OnWebLinkClick if loTreatWebLinkAsUriAnnotationLink is set
    loAutoLaunch,                      // Allow executing/opening a program/file automatically by using ShellExecuteEx
    loAutoEmbeddedGotoReplaceDocument, // Jumps to an attached PDF document are allowed and automatically handled by replacing the loaded document

    loTreatWebLinkAsUriAnnotationLink, // OnAnnotationLinkClick also handles WebLinks
    loAlwaysDetectWebAndUriLink        // If if OnWebLinkClick and OnAnnotationLinkClick aren't assigned, URI and WebLinks are detected
  );
  TPdfControlLinkOptions = set of TPdfControlLinkOptionType;

const
  cPdfControlDefaultDrawOptions = [proAnnotations];
  cPdfControlDefaultLinkOptions = [loAutoGoto, loTreatWebLinkAsUriAnnotationLink, loAlwaysDetectWebAndUriLink];
  cPdfControlAllAutoLinkOptions = [loAutoGoto, loAutoRemoteGotoReplaceDocument, loAutoOpenURI,
                                   loAutoLaunch, loAutoEmbeddedGotoReplaceDocument];

type
  TPdfControlScaleMode = (
    smFitAuto,
    smFitWidth,
    smFitHeight,
    smZoom
  );

  TPdfControlWebLinkClickEvent = procedure(Sender: TObject; Url: string) of object;
  TPdfControlAnnotationLinkClickEvent = procedure(Sender: TObject; LinkInfo: TPdfLinkInfo; var Handled: Boolean) of object;
  TPdfControlRectArray = array of TRect;

  TPdfControl = class(TControl)
  private
    FDocument: TPdfDocument;
    FPageIndex: Integer;
    FRenderedPageIndex: Integer;
    FPageBitmap: TBitmap;
    FDrawX: Integer;
    FDrawY: Integer;
    FDrawWidth: Integer;
    FDrawHeight: Integer;
    FRotation: TPdfPageRotation;
    {$IFDEF USE_PRINTCLIENT_WORKAROUND}
    FPrintClient: Boolean;
    {$ENDIF USE_PRINTCLIENT_WORKAROUND}
    FMousePressed: Boolean;
    FSelectionActive: Boolean;
    FAllowUserTextSelection: Boolean;
    FAllowUserPageChange: Boolean;
    FAllowFormEvents: Boolean;
    FBufferedPageDraw: Boolean;
    FSmoothScroll: Boolean;
    FScrollTimerActive: Boolean;
    FScrollTimer: Boolean;
    FChangePageOnMouseScrolling: Boolean;
    FSelStartCharIndex: Integer;
    FSelStopCharIndex: Integer;
    FMouseDownPt: TPoint;
    FCheckForTrippleClick: Boolean;
    FWebLinkInfo: TPdfPageWebLinksInfo;
    FDrawOptions: TPdfPageRenderOptions;
    FScaleMode: TPdfControlScaleMode;
    FZoomPercentage: Integer;
    FPageColor: TAlphaColor;
    FLinkOptions: TPdfControlLinkOptions;
    FHighlightTextRects: TPdfRectArray;
    FHighlightTexts: TObjectList;
    FFormOutputSelectedRects: TPdfRectArray;
    FFormFieldFocused: Boolean;
    FPageShadowSize: Integer;
    FPageShadowColor: TAlphaColor;
    FPageShadowPadding: Integer;
    FPageBorderColor: TAlphaColor;
    FHorzScrollPos: Integer;
    FVertScrollPos: Integer;
    FAniHorzScrollPos: Single;
    FAniVertScrollPos: Single;

    FOnWebLinkClick: TPdfControlWebLinkClickEvent;
    FOnAnnotationLinkClick: TPdfControlAnnotationLinkClickEvent;
    FOnPageChange: TNotifyEvent;
    FOnPaint: TNotifyEvent;
    FOnPrintDocument: TNotifyEvent;

    procedure SetAniHorzScrollPos(const Value: Single);
    procedure SetAniVertScrollPos(const Value: Single);


    {$IFDEF MSWINDOWS}
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMHScroll(var Message: TWMHScroll); message WM_HSCROLL;
    {$ENDIF MSWINDOWS}
    {$IFDEF USE_PRINTCLIENT_WORKAROUND}
    procedure WMPrintClient(var Message: TWMPrintClient); message WM_PRINTCLIENT;
    {$ENDIF USE_PRINTCLIENT_WORKAROUND}

    procedure GetPageWebLinks;
    function GetCurrentPage: TPdfPage;
    function GetPageCount: Integer;
    procedure SetPageIndex(Value: Integer);
    function InternSetPageIndex(Value: Integer; ScrollTransition, InverseScrollTransition: Boolean): Boolean;
    procedure SetRotation(const Value: TPdfPageRotation);
    function SetSelStopCharIndex(X, Y: Single): Boolean;
    function GetSelText: string;
    function GetSelLength: Integer;
    function GetSelStart: Integer;
    procedure SetSelection(Active: Boolean; StartIndex, StopIndex: Integer);
    procedure SetScaleMode(const Value: TPdfControlScaleMode);
    procedure SetPageBorderColor(const Value: TAlphaColor);
    procedure SetPageShadowColor(const Value: TAlphaColor);
    procedure SetPageShadowPadding(const Value: Integer);
    procedure SetPageShadowSize(const Value: Integer);
    procedure AdjustDrawPos;
    procedure UpdatePageDrawInfo;
    procedure GetWidthHeight(PageWidth, PageHeight: Double; DpiX, DpiY, MaxWidth, MaxHeight: Integer; var W, H: Integer);
    procedure SetPageColor(const Value: TAlphaColor);
    procedure SetDrawOptions(const Value: TPdfPageRenderOptions);
    procedure InvalidateRectDiffs(const OldRects, NewRects: TPdfControlRectArray);
    procedure InvalidatePdfRectDiffs(const OldRects, NewRects: TPdfRectArray);
    procedure StopScrollTimer;
    procedure DocumentLoaded;
    procedure DrawSelection(ACanvas: TCanvas; Page: TPdfPage);
    procedure DrawHighlightText(ACanvas: TCanvas; Page: TPdfPage);
    procedure DrawBorderAndShadow(ACanvas: TCanvas);
    function InternPageToDevice(Page: TPdfPage; PageRect: TPdfRect; ANormalize: Boolean): TRectF;
    procedure SetZoomPercentage(Value: Integer);
    procedure DrawPage(ACanvas: TCanvas; Page: TPdfPage; DirectDrawPage: Boolean);
    procedure CalcHighlightTextRects;
    procedure InitDocument;
    function ShellOpenFileName(const FileName: string; Launch: Boolean): Boolean;

    procedure FormInvalidate(Document: TPdfDocument; Page: TPdfPage; const PageRect: TPdfRect);
    procedure FormOutputSelectedRect(Document: TPdfDocument; Page: TPdfPage; const PageRect: TPdfRect);
    procedure FormGetCurrentPage(Document: TPdfDocument; var Page: TPdfPage);
    procedure FormFieldFocus(Document: TPdfDocument; Value: PWideChar; ValueLen: Integer; FieldFocused: Boolean);
    procedure ExecuteNamedAction(Document: TPdfDocument; NamedAction: TPdfNamedActionType);

    procedure DrawAlphaRects(ACanvas: TCanvas; Page: TPdfPage; const Rects: TPdfRectArray; Color: TAlphaColor);
    procedure DrawAlphaSelection(ACanvas: TCanvas; Page: TPdfPage; const Rects: TPdfRectArray);
    procedure DrawFormOutputSelectedRects(ACanvas: TCanvas; Page: TPdfPage);
    procedure SetColor(const Value: TAlphaColor);
    function GetColor: TAlphaColor;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
    procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;

    function LinkHandlingNeeded: Boolean;
    function IsClickableLinkAt(X, Y: Integer): Boolean;
    procedure WebLinkClick(const Url: string); virtual;
    procedure AnnotationLinkClick(LinkInfo: TPdfLinkInfo); virtual;
    procedure PageChange; virtual;
    procedure PageContentChanged(Closing: Boolean);
    procedure PageLayoutChanged;
    function IsPageValid: Boolean;
    function GetSelectionRects: TPdfControlRectArray;
//    procedure DestroyWnd; override;

    property DrawX: Integer read FDrawX;
    property DrawY: Integer read FDrawY;
    property DrawWidth: Integer read FDrawWidth;
    property DrawHeight: Integer read FDrawHeight;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { InvalidatePage forces the page to be rendered again and invalidates the control. }
    procedure InvalidatePage;
    { PrintDocument uses OnPrintDocument to print. If OnPrintDocument is not assigned it does nothing. }
    procedure PrintDocument;

    procedure OpenWithDocument(Document: TPdfDocument); // takes ownership
    procedure LoadFromCustom(ReadFunc: TPdfDocumentCustomReadProc; Size: LongWord; Param: Pointer; const Password: UTF8String = '');
    procedure LoadFromActiveStream(Stream: TStream; const Password: UTF8String = ''); // Stream must not be released until the document is closed
    procedure LoadFromActiveBuffer(Buffer: Pointer; Size: Int64; const Password: UTF8String = ''); // Buffer must not be released until the document is closed
    procedure LoadFromBytes(const Bytes: TBytes; const Password: UTF8String = ''); overload; // The content of the Bytes array must not be changed until the document is closed
    procedure LoadFromBytes(const Bytes: TBytes; Index: Integer; Count: Integer; const Password: UTF8String = ''); overload; // The content of the Bytes array must not be changed until the document is closed
    procedure LoadFromStream(Stream: TStream; const Password: UTF8String = '');
    procedure LoadFromFile(const FileName: string; const Password: UTF8String = ''; LoadOption: TPdfDocumentLoadOption = dloDefault);
    procedure Close;

    function DeviceToPage(DeviceX, DeviceY: Integer): TPdfPoint; overload;
    function DeviceToPage(DeviceRect: TRect): TPdfRect; overload;
    function PageToDevice(PageX, PageY: Double): TPoint; overload;
    function PageToDevice(PageRect: TPdfRect): TRect; overload;
    function GetPageRect: TRect;

    procedure CopyFormTextToClipboard;
    procedure CutFormTextToClipboard;
    procedure PasteFormTextFromClipboard;
    procedure SelectAllFormText;

    procedure CopyToClipboard;
    procedure ClearSelection;
    procedure SelectAll;
    procedure SelectText(CharIndex, Count: Integer);
    function SelectWord(CharIndex: Integer): Boolean; // includes symbols like Chrome
    function SelectLine(CharIndex: Integer): Boolean;

    function GetTextInRect(const R: TRect): string;
    { HightlightText() highlights all occurences of the specified text and clears previously
      hightlighted texts. }
    procedure HightlightText(const SearchText: string; MatchCase, MatchWholeWord: Boolean);
    { AddHightlightText() highlights all occurences of the specified text but keeps previously
      hightlighted texts. }
    procedure AddHightlightText(const SearchText: string; MatchCase, MatchWholeWord: Boolean);
    procedure ClearHighlightText;

    function IsWebLinkAt(X, Y: Integer): Boolean; overload;
    function IsWebLinkAt(X, Y: Integer; var Url: string): Boolean; overload;
    function IsUriAnnotationLinkAt(X, Y: Integer): Boolean;
    function IsAnnotationLinkAt(X, Y: Integer): Boolean;
    function GetAnnotationLinkAt(X, Y: Integer): TPdfAnnotation;

    function GotoNextPage(ScrollTransition: Boolean = False): Boolean;
    function GotoPrevPage(ScrollTransition: Boolean = False): Boolean;
    function ScrollContent(XOffset, YOffset: Integer; Smooth: Boolean = False): Boolean; virtual;
    function ScrollContentTo(X, Y: Integer; Smooth: Boolean = False): Boolean;
    function GotoDestination(const LinkGotoDestination: TPdfLinkGotoDestination): Boolean;

    property Document: TPdfDocument read FDocument;
    property CurrentPage: TPdfPage read GetCurrentPage;

    property PageCount: Integer read GetPageCount;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property SelStart: Integer read GetSelStart; // in CharIndex, not TextIndex (Length(SelText) may not be SelLength)
    property SelLength: Integer read GetSelLength; // in CharIndex, not TextIndex (Length(SelText) may not be SelLength)
    property SelText: string read GetSelText;

    property Canvas;
    property Color: TAlphaColor read GetColor write SetColor;
  published
    property ScaleMode: TPdfControlScaleMode read FScaleMode write SetScaleMode default smFitAuto;
    property ZoomPercentage: Integer read FZoomPercentage write SetZoomPercentage default 100;
    property PageColor: TAlphaColor read FPageColor write SetPageColor default TAlphaColors.White;
    property Rotation: TPdfPageRotation read FRotation write SetRotation default prNormal;
    property BufferedPageDraw: Boolean read FBufferedPageDraw write FBufferedPageDraw default True;
    property AllowUserTextSelection: Boolean read FAllowUserTextSelection write FAllowUserTextSelection default True;
    property AllowUserPageChange: Boolean read FAllowUserPageChange write FAllowUserPageChange default True; // PgDn/PgUp
    property AllowFormEvents: Boolean read FAllowFormEvents write FAllowFormEvents default True;
    property DrawOptions: TPdfPageRenderOptions read FDrawOptions write SetDrawOptions default cPdfControlDefaultDrawOptions;
    property SmoothScroll: Boolean read FSmoothScroll write FSmoothScroll default False;
    property ScrollTimer: Boolean read FScrollTimer write FScrollTimer default True;
    property ChangePageOnMouseScrolling: Boolean read FChangePageOnMouseScrolling write FChangePageOnMouseScrolling default False;
    property LinkOptions: TPdfControlLinkOptions read FLinkOptions write FLinkOptions default cPdfControlDefaultLinkOptions;

    property AniHorzScrollPos: Single read FAniHorzScrollPos write SetAniHorzScrollPos;
    property AniVertScrollPos: Single read FAniVertScrollPos write SetAniVertScrollPos;

    property PageBorderColor: TAlphaColor read FPageBorderColor write SetPageBorderColor default TAlphaColors.Null;
    property PageShadowColor: TAlphaColor read FPageShadowColor write SetPageShadowColor default TAlphaColors.Null;
    property PageShadowSize: Integer read FPageShadowSize write SetPageShadowSize default 4;
    property PageShadowPadding: Integer read FPageShadowPadding write SetPageShadowPadding default 44;

    { OnWebLinkClick is only called for WebLinks (URLs parsed from the document text). If OnAnnotationLinkClick is
      not assigned, OnWebLinkClick is also called URI link annontations for backward compatibility reasons. }
    property OnWebLinkClick: TPdfControlWebLinkClickEvent read FOnWebLinkClick write FOnWebLinkClick;
    { OnAnnotationLinkClick is called for all link annotation but not for WebLinks. }
    property OnAnnotationLinkClick: TPdfControlAnnotationLinkClickEvent read FOnAnnotationLinkClick write FOnAnnotationLinkClick;
    { OnPageChange is called if the current page is switched. }
    property OnPageChange: TNotifyEvent read FOnPageChange write FOnPageChange;
    { OnPrintDocument is called from PrintDocument }
    property OnPrintDocument: TNotifyEvent read FOnPrintDocument write FOnPrintDocument;

    property Align;
    property Anchors;
//    property Color default clGray;
//    property Constraints;
//    property DragCursor;
//    property DragKind;
    property DragMode;
    property Enabled;
//    property Font;
//    property ParentBackground default False;
//    property ParentColor default False;
//    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
//    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnKeyDown;
//    property OnKeyPress;
    property OnKeyUp;
    {$IFNDEF FPC}
//    property OnMouseActivate;
    {$ENDIF ~FPC}
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
//    property OnStartDock;
//    property OnStartDrag;
    {$IFDEF VCL_HAS_TOUCH}
    property Touch;
    property OnGesture;
    {$ENDIF VCL_HAS_TOUCH}
  end;

  TPdfDocumentVclPrinter = class(TPdfDocumentPrinter)
  private
    FBeginDocCalled: Boolean;
    FPagePrinted: Boolean;
  protected
    function PrinterStartDoc(const AJobTitle: string): Boolean; override;
    procedure PrinterEndDoc; override;
    procedure PrinterStartPage; override;
    procedure PrinterEndPage; override;
    function GetPrinterDC: HDC; override;
  public
    { If AShowPrintDialog is false PrintDocument prints the document to the default printer.
      If AShowPrintDialog is true the print dialog is shown and the user can select the
      printer, page range and number of copies (if supported by the printer driver).
      Returns true if the page was send to the printer driver. }
    class function PrintDocument(ADocument: TPdfDocument; const AJobTitle: string;
      AShowPrintDialog: Boolean = True; AllowPageRange: Boolean = True;
      AParentWnd: HWND = 0): Boolean; static;
  end;

implementation

uses
  Math, System.Character, FMX.Printer, FMX.Platform, System.Rtti, FMX.Ani;

const
  cScrollTimerId = 1;
  cTrippleClickTimerId = 2;
  cScrollTimerInterval = 50;
  cDefaultScrollOffset = 25;

type
  THighlightTextInfo = class(TObject)
  private
    FText: string;
    FMatchCase: Boolean;
    FMatchWholeWord: Boolean;
  public
    constructor Create(const AText: string; AMatchCase, AMatchWholeWord: Boolean);
    function IsSame(const AText: string; AMatchCase, AMatchWholeWord: Boolean): Boolean;

    property Text: string read FText;
    property MatchCase: Boolean read FMatchCase;
    property MatchWholeWord: Boolean read FMatchWholeWord;
  end;

function IsWhitespace(Ch: Char): Boolean;
begin
  {$IFDEF FPC}
  Result := TCharacter.IsWhiteSpace(Ch);
  {$ELSE}
    {$IF CompilerVersion >= 25.0} // XE4
  Result := Ch.IsWhiteSpace;
    {$ELSE}
  Result := TCharacter.IsWhiteSpace(Ch);
    {$IFEND}
  {$ENDIF FPC}
end;

{$IFDEF MSWINDOWS}
function VclAbortProc(Prn: HDC; Error: Integer): Bool; stdcall;
begin
  if Assigned(Application) then Application.ProcessMessages;
  Result := not Printer.Aborted;
end;

function FastVclAbortProc(Prn: HDC; Error: Integer): Bool; stdcall;
begin
  Result := not Printer.Aborted;
end;
{$ENDIF MSWINDOWS}


{ THighlightTextInfo }

constructor THighlightTextInfo.Create(const AText: string; AMatchCase, AMatchWholeWord: Boolean);
begin
  inherited Create;
  FText := AText;
  FMatchCase := AMatchCase;
  FMatchWholeWord := AMatchWholeWord;
end;

function THighlightTextInfo.IsSame(const AText: string; AMatchCase, AMatchWholeWord: Boolean): Boolean;
begin
  Result := (AMatchCase = FMatchCase) and
            (AMatchWholeWord = FMatchWholeWord) and
            (AText = FText);
end;

{ TPdfDocumentVclPrinter }

function TPdfDocumentVclPrinter.PrinterStartDoc(const AJobTitle: string): Boolean;
begin
  Result := False;
  FPagePrinted := False;
  if not Printer.Printing then
  begin
    if AJobTitle <> '' then
      Printer.Title := AJobTitle;
    Printer.BeginDoc;
    FBeginDocCalled := Printer.Printing;
    Result := FBeginDocCalled;
  end;
  if Result and Printer.Printing then
  begin
    // The Printers.AbortProc function calls ProcessMessages. That not only slows down the performance
    // but it also allows the user to do things in the UI.
    SetAbortProc(GetPrinterDC, @FastVclAbortProc);
  end;
end;

procedure TPdfDocumentVclPrinter.PrinterEndDoc;
begin
  if Printer.Printing then
  begin
    SetAbortProc(GetPrinterDC, @VclAbortProc); // restore default behavior
    if FBeginDocCalled then
      Printer.EndDoc;
  end;
end;

procedure TPdfDocumentVclPrinter.PrinterStartPage;
begin
  // Printer has only "NewPage" and the very first page doesn't need a NewPage call because
  // Printer.BeginDoc already called Windows.StartPage.
  if (Printer.PageNumber > 1) or FPagePrinted then
    Printer.NewPage;
end;

procedure TPdfDocumentVclPrinter.PrinterEndPage;
begin
  FPagePrinted := True;
  // The VCL uses "NewPage". For the very last page Printer.EndDoc calls Windows.EndPage.
end;

function TPdfDocumentVclPrinter.GetPrinterDC: HDC;
begin
//  Result := Printer.Canvas.Handle;
end;

{$IFDEF MSWINDOWS}
class function TPdfDocumentVclPrinter.PrintDocument(ADocument: TPdfDocument;
  const AJobTitle: string; AShowPrintDialog, AllowPageRange: Boolean; AParentWnd: HWND): Boolean;
var
  PdfPrinter: TPdfDocumentVclPrinter;
  FromPage, ToPage: Integer;
begin
  Result := False;
  if ADocument = nil then
    Exit;

  FromPage := 1;
  ToPage := ADocument.PageCount;
    
  if AShowPrintDialog then
  begin
    // TPrintDialog is a VCL component, not available in FMX.
    // In FMX, printing is handled differently.
    // For now, we'll just skip the dialog.
    Result := True; 
  end;

  PdfPrinter := TPdfDocumentVclPrinter.Create;
  try
    if PdfPrinter.BeginPrint(AJobTitle) then
    begin
      try
        Result := PdfPrinter.Print(ADocument, FromPage - 1, ToPage - 1);
      finally
        PdfPrinter.EndPrint;
      end;
    end;
  finally
    PdfPrinter.Free;
  end;
end;
{$ENDIF MSWINDOWS}


{ TPdfControl }

constructor TPdfControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
//  ControlStyle := ControlStyle + [csOpaque];

  FScaleMode := smFitAuto;
  FZoomPercentage := 100;
  FPageColor := TAlphaColors.White;
  FRotation := prNormal;
  FAllowUserTextSelection := True;
  FAllowUserPageChange := True;
  FAllowFormEvents := True;
  FDrawOptions := cPdfControlDefaultDrawOptions;
  FScrollTimer := True;
  FBufferedPageDraw := True;
  FLinkOptions := cPdfControlDefaultLinkOptions;

  FPageBorderColor := TAlphaColors.Null;
  FPageShadowColor := TAlphaColors.Null;
  FPageShadowSize := 4;
  FPageShadowPadding := 44;
  FHorzScrollPos := 0;
  FVertScrollPos := 0;
  FAniHorzScrollPos := 0;
  FAniVertScrollPos := 0;

  FDocument := TPdfDocument.Create;
  InitDocument;

//  ParentDoubleBuffered := False;
//  ParentBackground := False;
//  ParentColor := False;
  TabStop := True;
//  Color := clGray;
  Width := 130;
  Height := 180;
end;

destructor TPdfControl.Destroy;
begin
  FPageBitmap.Free;
  FreeAndNil(FWebLinkInfo);	
  FDocument.Free;
  inherited Destroy;
end;

procedure TPdfControl.InitDocument;
begin
  FDocument.OnFormInvalidate := FormInvalidate;
  FDocument.OnFormOutputSelectedRect := FormOutputSelectedRect;
  FDocument.OnFormGetCurrentPage := FormGetCurrentPage;
  FDocument.OnFormFieldFocus := FormFieldFocus;
  FDocument.OnExecuteNamedAction := ExecuteNamedAction;
end;

procedure TPdfControl.SetColor(const Value: TAlphaColor);
begin
  if FPageColor <> Value then
  begin
    FPageColor := Value;
    Repaint;
  end;
end;

function TPdfControl.GetColor: TAlphaColor;
begin
  Result := FPageColor;
end;

{$IFDEF USE_PRINTCLIENT_WORKAROUND}
procedure TPdfControl.WMPrintClient(var Message: TWMPrintClient);
// Emulate Delphi 2010's TControlState.csPrintClient
var
  LastPrintClient: Boolean;
begin
  LastPrintClient := FPrintClient;
  try
    FPrintClient := True;
    inherited;
  finally
    FPrintClient := LastPrintClient;
  end;
end;
{$ENDIF USE_PRINTCLIENT_WORKAROUND}

procedure TPdfControl.DrawAlphaSelection(ACanvas: TCanvas; Page: TPdfPage; const Rects: TPdfRectArray);
begin
  DrawAlphaRects(ACanvas, Page, Rects, TAlphaColorRec.Seagreen); // Just a default selection-like color
end;

procedure TPdfControl.DrawAlphaRects(ACanvas: TCanvas; Page: TPdfPage; const Rects: TPdfRectArray; Color: TAlphaColor);
var
  Count: Integer;
  I: Integer;
  R: TRectF;
begin
  Count := Length(Rects);
  if Count > 0 then
  begin
    ACanvas.Fill.Color := Color;
    ACanvas.Fill.Kind := TBrushKind.Solid;
    for I := 0 to Count - 1 do
    begin
      R := InternPageToDevice(Page, Rects[I], True);
      ACanvas.FillRect(R, 0, 0, [], 0.5);
    end;
  end;
end;

procedure TPdfControl.DrawSelection(ACanvas: TCanvas; Page: TPdfPage);
var
  Count: Integer;
  I: Integer;
  Rects: TPdfRectArray;
begin
  Count := Page.GetTextRectCount(SelStart, SelLength);
  if Count > 0 then
  begin
    SetLength(Rects, Count);
    for I := 0 to Count - 1 do
      Rects[I] := Page.GetTextRect(I);
    DrawAlphaSelection(ACanvas, Page, Rects);
  end;
end;

procedure TPdfControl.DrawFormOutputSelectedRects(ACanvas: TCanvas; Page: TPdfPage);
begin
  DrawAlphaSelection(ACanvas, Page, FFormOutputSelectedRects);
end;

procedure TPdfControl.DrawHighlightText(ACanvas: TCanvas; Page: TPdfPage);
begin
  // FMX uses TAlphaColor, we can use a similar orange
  DrawAlphaRects(ACanvas, Page, FHighlightTextRects, TAlphaColorRec.Orange);
end;

procedure TPdfControl.DrawBorderAndShadow(ACanvas: TCanvas);
begin
  // Draw page borders
  if PageBorderColor <> TAlphaColors.Null then
  begin
    ACanvas.Stroke.Color := PageBorderColor;
    ACanvas.Stroke.Kind := TBrushKind.Solid;
    ACanvas.DrawRect(RectF(FDrawX, FDrawY, FDrawX + FDrawWidth, FDrawY + FDrawHeight), 0, 0, [], 1);
  end;

  // Draw page shadow
  if (PageShadowColor <> TAlphaColors.Null) and (PageShadowSize > 0) then
  begin
    ACanvas.Fill.Color := PageShadowColor;
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.FillRect(RectF(FDrawX + FDrawWidth, FDrawY + PageShadowSize,
                           FDrawX + FDrawWidth + PageShadowSize, FDrawY + FDrawHeight + PageShadowSize), 0, 0, [], 1);
    ACanvas.FillRect(RectF(FDrawX + PageShadowSize, FDrawY + FDrawHeight,
                           FDrawX + FDrawWidth + PageShadowSize, FDrawY + FDrawHeight + PageShadowSize), 0, 0, [], 1);
  end;
end;

procedure TPdfControl.DrawPage(ACanvas: TCanvas; Page: TPdfPage; DirectDrawPage: Boolean);

  procedure DrawToBitmap(ABitmap: TBitmap; Page: TPdfPage);
  var
    Data: TBitmapData;
    PdfBmp: TPdfBitmap;
    ColorRef: TColorRef;
  begin
    ColorRef := (TAlphaColorRec(PageColor).B shl 16) or (TAlphaColorRec(PageColor).G shl 8) or TAlphaColorRec(PageColor).R;
    if ABitmap.Map(TMapAccess.Write, Data) then
    try
      // Create a PDFium bitmap wrapper for the FMX bitmap data
      PdfBmp := TPdfBitmap.Create(ABitmap.Width, ABitmap.Height, bfBGRA, Data.Data, Data.Pitch);
      try
        Page.Draw(PdfBmp, 0, 0, ABitmap.Width, ABitmap.Height, Rotation, FDrawOptions, ColorRef);
      finally
        PdfBmp.Free;
      end;
    finally
      ABitmap.Unmap(Data);
    end;
  end;

begin
  if DirectDrawPage then
  begin
    FreeAndNil(FPageBitmap);
    FRenderedPageIndex := -1;
    // For direct draw in FMX, we still probably want a temporary bitmap if we can't draw directly to canvas
    // But PDFium needs a buffer. Let's use FPageBitmap anyway or a local one.
  end;

  if (FPageBitmap = nil) or (FPageBitmap.Width <> FDrawWidth) or (FPageBitmap.Height <> FDrawHeight) then
  begin
    FRenderedPageIndex := -1;
    if FPageBitmap = nil then
      FPageBitmap := TBitmap.Create;
    FPageBitmap.SetSize(FDrawWidth, FDrawHeight);
  end;

  if FRenderedPageIndex <> PageIndex then
  begin
    FRenderedPageIndex := PageIndex;
    DrawToBitmap(FPageBitmap, Page);
  end;

  ACanvas.DrawBitmap(FPageBitmap, RectF(0, 0, FPageBitmap.Width, FPageBitmap.Height),
                     RectF(FDrawX, FDrawY, FDrawX + FDrawWidth, FDrawY + FDrawHeight), 1);
end;

procedure TPdfControl.Paint;
var
  Page: TPdfPage;
begin
  if IsPageValid then
  begin
    // Draw background
    Canvas.Fill.Color := Color;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.FillRect(RectF(0, 0, Width, FDrawY), 0, 0, [], 1);                                      // top bar
    Canvas.FillRect(RectF(0, FDrawY, FDrawX, FDrawY + FDrawHeight), 0, 0, [], 1);                  // left bar
    Canvas.FillRect(RectF(FDrawX + FDrawWidth, FDrawY, Width, FDrawY + FDrawHeight), 0, 0, [], 1); // right bar
    Canvas.FillRect(RectF(0, FDrawY + FDrawHeight, Width, Height), 0, 0, [], 1);                   // bottom bar

    // Draw the page
    Page := CurrentPage;
    DrawPage(Canvas, Page, False);

    // Draw overlays
    if FSelectionActive then
      DrawSelection(Canvas, Page);

    DrawFormOutputSelectedRects(Canvas, Page);
    DrawHighlightText(Canvas, Page);
    DrawBorderAndShadow(Canvas);

    // User painting
    if Assigned(FOnPaint) then
      FOnPaint(Self);
  end
  else
  begin
    // empty page
    FreeAndNil(FPageBitmap);
    Canvas.Fill.Color := Color;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.FillRect(LocalRect, 0, 0, [], 1);
    DrawBorderAndShadow(Canvas);
    if Assigned(FOnPaint) then
      FOnPaint(Self);
  end;
end;

procedure TPdfControl.PageContentChanged(Closing: Boolean);
begin
  FSelStartCharIndex := 0;
  FSelStopCharIndex := 0;
  FSelectionActive := False;
  CalcHighlightTextRects;
  GetPageWebLinks;
  PageLayoutChanged;
  if not Closing then
    PageChange;
end;

procedure TPdfControl.PageLayoutChanged;
begin
  FRenderedPageIndex := -1;
  UpdatePageDrawInfo;
  Repaint;
end;

procedure TPdfControl.InvalidatePage;
begin
  FRenderedPageIndex := -1;
  Repaint;
end;

procedure TPdfControl.PrintDocument;
begin
  if Document.Active then
  begin
    if Assigned(FOnPrintDocument) then
      FOnPrintDocument(Self);
    // TPdfDocumentVclPrinter is VCL-specific, FMX needs a different approach
  end;
end;

function TPdfControl.GetCurrentPage: TPdfPage;
begin
  if IsPageValid then
    Result := FDocument.Pages[PageIndex]
  else
    Result := nil;
end;

function TPdfControl.GetPageCount: Integer;
begin
  Result := FDocument.PageCount;
end;

procedure TPdfControl.SetPageIndex(Value: Integer);
begin
  InternSetPageIndex(Value, False, False);
end;

function TPdfControl.InternSetPageIndex(Value: Integer; ScrollTransition, InverseScrollTransition: Boolean): Boolean;
begin
  if Value >= PageCount then
    Value := PageCount - 1;
  if Value < 0 then
    Value := 0;

  if Value <> FPageIndex then
  begin
    ClearSelection;
    // Close the previous page to keep memory usage low (especially for large PDF files)
    if (FPageIndex >= 0) and (FPageIndex < PageCount) and FDocument.IsPageLoaded(FPageIndex) and
       not FDocument.Pages[FPageIndex].Annotations.AnnotationsLoaded then // Issue #28: Don't close the page if annotations are loaded
    begin
      FDocument.Pages[FPageIndex].Close;
    end;
    FPageIndex := Value;
    // Simplified scrolling for FMX
    PageContentChanged(False);
    Result := True;
  end
  else
    Result := False;
end;

function TPdfControl.GotoNextPage(ScrollTransition: Boolean): Boolean;
begin
  Result := PageIndex < PageCount - 1;
  if Result then
  begin
    InternSetPageIndex(PageIndex + 1, ScrollTransition, False);
    ScrollContentTo(0, 0);
  end;
end;

function TPdfControl.GotoPrevPage(ScrollTransition: Boolean): Boolean;
begin
  Result := PageIndex > 0;
  if Result then
  begin
    InternSetPageIndex(PageIndex - 1, ScrollTransition, False);
    ScrollContentTo(0, 0);
  end;
end;

procedure TPdfControl.PageChange;
begin
  if Assigned(FOnPageChange) then
    FOnPageChange(Self);
end;

function TPdfControl.IsPageValid: Boolean;
begin
  Result := FDocument.Active and (PageIndex < PageCount);
end;

procedure TPdfControl.DocumentLoaded;
begin
  FPageIndex := 0;
  PageContentChanged(False);
end;

procedure TPdfControl.OpenWithDocument(Document: TPdfDocument);
begin
  Close;
  if Document = nil then
    Exit;

  FreeAndNil(FDocument);
  FDocument := Document;
  InitDocument;
end;

procedure TPdfControl.LoadFromCustom(ReadFunc: TPdfDocumentCustomReadProc; Size: LongWord;
  Param: Pointer; const Password: UTF8String);
begin
  try
    FDocument.LoadFromCustom(ReadFunc, Size, Param, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromActiveStream(Stream: TStream; const Password: UTF8String);
begin
  try
    FDocument.LoadFromActiveStream(Stream, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromActiveBuffer(Buffer: Pointer; Size: Int64; const Password: UTF8String);
begin
  try
    FDocument.LoadFromActiveBuffer(Buffer, Size, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromBytes(const Bytes: TBytes; Index, Count: Integer;
  const Password: UTF8String);
begin
  try
    FDocument.LoadFromBytes(Bytes, Index, Count, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromBytes(const Bytes: TBytes; const Password: UTF8String);
begin
  try
    FDocument.LoadFromBytes(Bytes, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromStream(Stream: TStream; const Password: UTF8String);
begin
  try
    FDocument.LoadFromStream(Stream, Password);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.LoadFromFile(const FileName: string; const Password: UTF8String;
  LoadOption: TPdfDocumentLoadOption);
begin
  try
    FDocument.LoadFromFile(FileName, Password, LoadOption);
  finally
    DocumentLoaded;
  end;
end;

procedure TPdfControl.Close;
begin
  FDocument.Close;
  FPageIndex := 0;
  FFormFieldFocused := False;
  PageContentChanged(True);
end;



procedure TPdfControl.Resize;
begin
  UpdatePageDrawInfo;
  inherited Resize;
end;

procedure TPdfControl.SetScaleMode(const Value: TPdfControlScaleMode);
begin
  if Value <> FScaleMode then
  begin
    FScaleMode := Value;
    UpdatePageDrawInfo;
    PageLayoutChanged;
  end;
end;

procedure TPdfControl.SetZoomPercentage(Value: Integer);
begin
  if Value < 1 then
    Value := 1
  else if Value > 10000 then
    Value := 10000;
  if Value <> FZoomPercentage then
  begin
    FZoomPercentage := Value;
    PageLayoutChanged;
  end;
end;

procedure TPdfControl.SetPageColor(const Value: TAlphaColor);
begin
  if Value <> FPageColor then
  begin
    FPageColor := Value;
    InvalidatePage;
  end;
end;

procedure TPdfControl.SetDrawOptions(const Value: TPdfPageRenderOptions);
begin
  if Value <> FDrawOptions then
  begin
    FDrawOptions := Value;
    InvalidatePage;
  end;
end;

procedure TPdfControl.SetRotation(const Value: TPdfPageRotation);
begin
  if Value <> FRotation then
  begin
    FRotation := Value;
    PageLayoutChanged;
  end;
end;

procedure TPdfControl.SetPageBorderColor(const Value: TAlphaColor);
begin
  if Value <> FPageBorderColor then
  begin
    FPageBorderColor := Value;
    InvalidatePage;
  end;
end;

procedure TPdfControl.SetPageShadowColor(const Value: TAlphaColor);
begin
  if Value <> FPageShadowColor then
  begin
    FPageShadowColor := Value;
    InvalidatePage;
  end;
end;

procedure TPdfControl.SetPageShadowPadding(const Value: Integer);
begin
  if Value <> FPageShadowPadding then
  begin
    FPageShadowPadding := Value;
    InvalidatePage;
  end;
end;

procedure TPdfControl.SetPageShadowSize(const Value: Integer);
begin
  if Value <> FPageShadowSize then
  begin
    FPageShadowSize := Value;
    InvalidatePage;
  end;
end;

function TPdfControl.GetPageRect: TRect;
begin
  Result := Rect(FDrawX, FDrawY, FDrawX + FDrawWidth, FDrawY + FDrawHeight);
end;

function TPdfControl.DeviceToPage(DeviceX, DeviceY: Integer): TPdfPoint;
var
  Page: TPdfPage;
begin
  Page := CurrentPage;
  if Page <> nil then
    Result := Page.DeviceToPage(FDrawX, FDrawY, FDrawWidth, FDrawHeight, DeviceX, DeviceY, Rotation)
  else
    Result := TPdfPoint.Empty;
end;

function TPdfControl.DeviceToPage(DeviceRect: TRect): TPdfRect;
var
  Page: TPdfPage;
begin
  Page := CurrentPage;
  if Page <> nil then
    Result := Page.DeviceToPage(FDrawX, FDrawY, FDrawWidth, FDrawHeight, DeviceRect, Rotation)
  else
    Result := TPdfRect.Empty;
end;

function TPdfControl.PageToDevice(PageX, PageY: Double): TPoint;
var
  Page: TPdfPage;
begin
  Page := CurrentPage;
  if Page <> nil then
    Result := Page.PageToDevice(FDrawX, FDrawY, FDrawWidth, FDrawHeight, PageX, PageY, Rotation)
  else
    Result := Point(0, 0);
end;

function TPdfControl.PageToDevice(PageRect: TPdfRect): TRect;
var
  Page: TPdfPage;
begin
  Page := CurrentPage;
  if Page <> nil then
    Result := Page.PageToDevice(FDrawX, FDrawY, FDrawWidth, FDrawHeight, PageRect, Rotation)
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPdfControl.InternPageToDevice(Page: TPdfPage; PageRect: TPdfRect; ANormalize: Boolean): TRectF;
var
  Value: Single;
begin
  Result := Page.PageToDevice(FDrawX, FDrawY, FDrawWidth, FDrawHeight, PageRect, Rotation);
  if ANormalize then
  begin
    if Result.Left > Result.Right then
    begin
      Value := Result.Right;
      Result.Right := Result.Left;
      Result.Left := Value;
    end;
    if Result.Top > Result.Bottom then
    begin
      Value := Result.Bottom;
      Result.Bottom := Result.Top;
      Result.Top := Value;
    end;
  end;
end;

function TPdfControl.SetSelStopCharIndex(X, Y: Single): Boolean;
var
  PagePt: TPdfPoint;
  CharIndex: Integer;
  Active: Boolean;
  R: TRectF;
  Page: TPdfPage;
begin
  Page := CurrentPage;
  if Page <> nil then
  begin
    PagePt := DeviceToPage(Round(X), Round(Y));
    CharIndex := Page.GetCharIndexAt(PagePt.X, PagePt.Y, MAXWORD, MAXWORD);
    Result := CharIndex >= 0;
    if not Result then
      CharIndex := FSelStopCharIndex;

    if FSelStartCharIndex <> CharIndex then
      Active := True
    else
    begin
      R := InternPageToDevice(Page, Page.GetCharBox(FSelStartCharIndex), True);
      Active := R.Contains(PointF(X, Y));
    end;
    SetSelection(Active, FSelStartCharIndex, CharIndex);
  end
  else
    Result := False;
end;

procedure TPdfControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  PagePt: TPdfPoint;
  CharIndex: Integer;
  Page: TPdfPage;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = TMouseButton.mbLeft then
  begin
    StopScrollTimer;
    SetFocus;
    FMousePressed := True;
    FMouseDownPt := Point(Round(X), Round(Y)); // used to find out if the selection must be cleared or not
  end;

  Page := CurrentPage;
  if Page <> nil then
  begin
    if AllowFormEvents then
    begin
      PagePt := DeviceToPage(Round(X), Round(Y));
      if Button = TMouseButton.mbLeft then
      begin
        if Page.FormEventLButtonDown(Shift, PagePt.X, PagePt.Y) then
          Exit;
      end
      else if Button = TMouseButton.mbRight then
      begin
        if Page.FormEventFocus(Shift, PagePt.X, PagePt.Y) then
          Exit;
        if Page.FormEventRButtonDown(Shift, PagePt.X, PagePt.Y) then
          Exit;
      end;
    end;

    if AllowUserTextSelection and not FFormFieldFocused then
    begin
      if Button = TMouseButton.mbLeft then
      begin
        PagePt := DeviceToPage(Round(X), Round(Y));
        CharIndex := Page.GetCharIndexAt(PagePt.X, PagePt.Y, MAXWORD, MAXWORD);
        begin
          FCheckForTrippleClick := False;
          SetSelection(False, CharIndex, CharIndex);
        end;
      end;
    end;
  end;
end;

procedure TPdfControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  PagePt: TPdfPoint;
  Url: string;
  Page: TPdfPage;
  LinkAnnotation: TPdfAnnotation;
  LinkInfo: TPdfLinkInfo;
begin
  inherited MouseUp(Button, Shift, X, Y);

  if AllowFormEvents and IsPageValid then
  begin
    PagePt := DeviceToPage(Round(X), Round(Y));
    Page := CurrentPage;
    if (Button = TMouseButton.mbLeft) and Page.FormEventLButtonUp(Shift, PagePt.X, PagePt.Y) then
    begin
      if FMousePressed and (Button = TMouseButton.mbLeft) then
      begin
        FMousePressed := False;
        StopScrollTimer;
      end;
      Exit;
    end;
    if (Button = TMouseButton.mbRight) and Page.FormEventRButtonUp(Shift, PagePt.X, PagePt.Y) then
      Exit;
  end;

  if FMousePressed then
  begin
    if Button = TMouseButton.mbLeft then
    begin
      FMousePressed := False;
      StopScrollTimer;
      if AllowUserTextSelection and not FFormFieldFocused then
        SetSelStopCharIndex(X, Y);
      if not FSelectionActive then
      begin
        if LinkHandlingNeeded then
        begin
          LinkAnnotation := GetAnnotationLinkAt(Round(X), Round(Y));
          LinkInfo := nil;
          if LinkAnnotation <> nil then
            LinkInfo := TPdfLinkInfo.Create(LinkAnnotation, '')
          else if IsWebLinkAt(Round(X), Round(Y), Url) then // If we have a Link Annotation and a WebLink, then the link annotation is prefered
          begin
            if loTreatWebLinkAsUriAnnotationLink in LinkOptions then
              LinkInfo := TPdfLinkInfo.Create(nil, Url)
            else
              WebLinkClick(Url);
          end;
          if LinkInfo <> nil then
          begin
            try
              AnnotationLinkClick(LinkInfo);
            finally
              LinkInfo.Free;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TPdfControl.MouseMove(Shift: TShiftState; X, Y: Single);
var
  PagePt: TPdfPoint;
  NewCursor: TCursor;
  Page: TPdfPage;
  Proceed: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  NewCursor := Cursor;
  try
    if AllowFormEvents and IsPageValid then
    begin
      PagePt := DeviceToPage(Round(X), Round(Y));
      Page := CurrentPage;
      if Page.FormEventMouseMove(Shift, PagePt.X, PagePt.Y) then
      begin
        Proceed := False;
        case Page.HasFormFieldAtPoint(PagePt.X, PagePt.Y) of
          fftUnknown:
            // Could be an annotation link with a URL
            Proceed := True;
          fftTextField:
            NewCursor := crIBeam;
          fftComboBox,
          fftSignature:
            NewCursor := crHandPoint;
        else
          NewCursor := crDefault;
        end;
        if not Proceed then
          Exit;
      end;
    end;

    if AllowUserTextSelection and not FFormFieldFocused then
    begin
      if FMousePressed then
      begin
        // Auto scroll
        if ((Y < 0) or (Y > Height)) or
           ((X < 0) or (X > Width)) then
        begin
          if ScrollTimer and not FScrollTimerActive then
          begin
            // SetTimer is Windows specific, FMX needs TTimer or similar
            // For now, let's just mark it active
            FScrollTimerActive := True;
          end;
        end
        else
          StopScrollTimer;

        if SetSelStopCharIndex(X, Y) then
        begin
          if NewCursor <> crIBeam then
          begin
            NewCursor := crIBeam;
            Cursor := NewCursor;
          end;
        end;
      end
      else
      begin
        if IsPageValid then
        begin
          PagePt := DeviceToPage(Round(X), Round(Y));
          if IsClickableLinkAt(Round(X), Round(Y)) then
            NewCursor := crHandPoint
          else if CurrentPage.GetCharIndexAt(PagePt.X, PagePt.Y, 5, 5) >= 0 then
            NewCursor := crIBeam
          else if Cursor <> crDefault then
            NewCursor := crDefault;
        end;
      end;
    end;
  finally
    if NewCursor <> Cursor then
      Cursor := NewCursor;
  end;
end;

// procedure TPdfControl.CMMouseleave(var Message: TMessage);
// begin
//   if (Cursor = crIBeam) or (Cursor = crHandPoint) then
//   begin
//     if AllowUserTextSelection or Assigned(FOnWebLinkClick) or Assigned(FOnAnnotationLinkClick) or (LinkOptions <> []) then
//       Cursor := crDefault;
//   end;
//   inherited;
// end;

function TPdfControl.GetTextInRect(const R: TRect): string;
begin
  if IsPageValid then
    Result := CurrentPage.GetTextAt(DeviceToPage(R))
  else
    Result := '';
end;

procedure TPdfControl.CopyToClipboard;
var
  ClipboardService: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, ClipboardService) then
    ClipboardService.SetClipboard(GetSelText);
end;

procedure TPdfControl.CopyFormTextToClipboard;
var
  ClipboardService: IFMXClipboardService;
  S: string;
begin
  if FFormFieldFocused and IsPageValid then
  begin
    S := CurrentPage.FormGetSelectedText;
    if (S <> '') and TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, ClipboardService) then
      ClipboardService.SetClipboard(S);
  end;
end;

procedure TPdfControl.CutFormTextToClipboard;
begin
  if FFormFieldFocused and IsPageValid then
  begin
    CopyFormTextToClipboard;
    CurrentPage.FormReplaceSelection('');
  end;
end;

procedure TPdfControl.PasteFormTextFromClipboard;
var
  ClipboardService: IFMXClipboardService;
  V: TValue;
begin
  if FFormFieldFocused and IsPageValid then
  begin
    if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, ClipboardService) then
    begin
      V := ClipboardService.GetClipboard;
      if not V.IsEmpty and V.IsType<string> then
        CurrentPage.FormReplaceSelection(V.AsString);
    end;
  end;
end;

procedure TPdfControl.SelectAllFormText;
begin
  if FFormFieldFocused and IsPageValid then
    CurrentPage.FormSelectAllText;
end;

function TPdfControl.GetSelText: string;
begin
  if FSelectionActive and IsPageValid then
    Result := CurrentPage.ReadText(SelStart, SelLength)
  else
    Result := '';
end;

function TPdfControl.GetSelLength: Integer;
begin
  if FSelectionActive and IsPageValid then
    Result := Abs(FSelStartCharIndex - FSelStopCharIndex) + 1
  else
    Result := 0;
end;

function TPdfControl.GetSelStart: Integer;
begin
  if FSelectionActive and IsPageValid then
    Result := Min(FSelStartCharIndex, FSelStopCharIndex)
  else
    Result := 0;
end;

function TPdfControl.GetSelectionRects: TPdfControlRectArray;
var
  Count: Integer;
  I: Integer;
  Page: TPdfPage;
  R: TRectF;
begin
  if FSelectionActive then
  begin
    Page := CurrentPage;
    if Page <> nil then
    begin
      Count := Page.GetTextRectCount(SelStart, SelLength);
      SetLength(Result, Count);
      for I := 0 to Count - 1 do
      begin
        R := InternPageToDevice(Page, Page.GetTextRect(I), True);
        Result[I] := Rect(Integer(Round(R.Left)), Integer(Round(R.Top)), Integer(Round(R.Right)), Integer(Round(R.Bottom)));
      end;
      Exit;
    end;
  end;
  Result := nil;
end;

procedure TPdfControl.InvalidateRectDiffs(const OldRects, NewRects: TPdfControlRectArray);

  function ContainsRect(const Rects: TPdfControlRectArray; const R: TRect): Boolean;
  var
    I: Integer;
  begin
    Result := True;
    for I := 0 to Length(Rects) - 1 do
      if (Rects[I].Left = R.Left) and (Rects[I].Top = R.Top) and (Rects[I].Right = R.Right) and (Rects[I].Bottom = R.Bottom) then
        Exit;
    Result := False;
  end;

var
  I: Integer;
begin
  for I := 0 to Length(OldRects) - 1 do
    if not ContainsRect(NewRects, OldRects[I]) then
      Repaint;

  for I := 0 to Length(NewRects) - 1 do
    if not ContainsRect(OldRects, NewRects[I]) then
      Repaint;
end;

procedure TPdfControl.InvalidatePdfRectDiffs(const OldRects, NewRects: TPdfRectArray);
var
  I: Integer;
  OldRs, NewRs: TPdfControlRectArray;
  Page: TPdfPage;
  RF: TRectF;
begin
  Page := CurrentPage;
  if (Page <> nil) then
  begin
    SetLength(OldRs, Length(OldRects));
    for I := 0 to Length(OldRects) - 1 do
    begin
      RF := InternPageToDevice(Page, OldRects[I], True);
      OldRs[I] := Rect(Integer(Round(RF.Left)), Integer(Round(RF.Top)), Integer(Round(RF.Right)), Integer(Round(RF.Bottom)));
    end;

    SetLength(NewRs, Length(NewRects));
    for I := 0 to Length(NewRects) - 1 do
    begin
      RF := InternPageToDevice(Page, NewRects[I], True);
      NewRs[I] := Rect(Integer(Round(RF.Left)), Integer(Round(RF.Top)), Integer(Round(RF.Right)), Integer(Round(RF.Bottom)));
    end;

    InvalidateRectDiffs(OldRs, NewRs);
  end;
end;
procedure TPdfControl.SetSelection(Active: Boolean; StartIndex, StopIndex: Integer);
var
  OldRects, NewRects: TPdfControlRectArray;
begin
  if (Active <> FSelectionActive) or (StartIndex <> FSelStartCharIndex) or (StopIndex <> FSelStopCharIndex) then
  begin
    OldRects := GetSelectionRects;

    FSelStartCharIndex := StartIndex;
    FSelStopCharIndex := StopIndex;
    FSelectionActive := Active and (FSelStartCharIndex >= 0) and (FSelStopCharIndex >= 0);

    NewRects := GetSelectionRects;
    InvalidateRectDiffs(OldRects, NewRects);
  end;
end;

procedure TPdfControl.ClearSelection;
begin
  SetSelection(False, 0, 0);
end;

procedure TPdfControl.SelectAll;
begin
  SelectText(0, -1);
end;

procedure TPdfControl.SelectText(CharIndex, Count: Integer);
begin
  if (Count = 0) or not IsPageValid then
    ClearSelection
  else
  begin
    if Count = -1 then
      SetSelection(True, 0, CurrentPage.GetCharCount - 1)
    else
      SetSelection(True, CharIndex, Min(CharIndex + Count - 1, CurrentPage.GetCharCount - 1));
  end;
end;

function TPdfControl.SelectWord(CharIndex: Integer): Boolean;
var
  Ch: WideChar;
  StartCharIndex, StopCharIndex, CharCount: Integer;
  Page: TPdfPage;
begin
  Result := False;
  Page := CurrentPage;
  if Page <> nil then
  begin
    ClearSelection;
    CharCount := Page.GetCharCount;
    if (CharIndex >= 0) and (CharIndex < CharCount) then
    begin
      while (CharIndex < CharCount) and IsWhiteSpace(Page.ReadChar(CharIndex)) do
        Inc(CharIndex);

      if CharIndex < CharCount then
      begin
        StartCharIndex := CharIndex - 1;
        while StartCharIndex >= 0 do
        begin
          Ch := Page.ReadChar(StartCharIndex);
          if IsWhiteSpace(Ch) then
            Break;
          Dec(StartCharIndex);
        end;
        Inc(StartCharIndex);

        StopCharIndex := CharIndex + 1;
        while StopCharIndex < CharCount do
        begin
          Ch := Page.ReadChar(StopCharIndex);
          if IsWhiteSpace(Ch) then
            Break;
          Inc(StopCharIndex);
        end;
        Dec(StopCharIndex);

        SetSelection(True, StartCharIndex, StopCharIndex);
        Result := True;
      end;
    end;
  end;
end;

function TPdfControl.SelectLine(CharIndex: Integer): Boolean;
var
  Ch: WideChar;
  StartCharIndex, StopCharIndex, CharCount: Integer;
  Page: TPdfPage;
begin
  Result := False;
  Page := CurrentPage;
  if Page <> nil then
  begin
    ClearSelection;
    CharCount := Page.GetCharCount;
    if (CharIndex >= 0) and (CharIndex < CharCount) then
    begin
      StartCharIndex := CharIndex - 1;
      while StartCharIndex >= 0 do
      begin
        Ch := Page.ReadChar(StartCharIndex);
        case Ch of
          #10, #13:
            Break;
        end;
        Dec(StartCharIndex);
      end;
      Inc(StartCharIndex);

      StopCharIndex := CharIndex + 1;
      while StopCharIndex < CharCount do
      begin
        Ch := Page.ReadChar(StopCharIndex);
        case Ch of
          #10, #13:
            Break;
        end;
        Inc(StopCharIndex);
      end;
      Dec(StopCharIndex);

      SetSelection(True, StartCharIndex, StopCharIndex);
      Result := True;
    end;
  end;
end;

// procedure TPdfControl.WMGetDlgCode(var Message: TWMGetDlgCode);
// begin
//   inherited;
//   Message.Result := Message.Result or DLGC_WANTARROWS or DLGC_WANTTAB;
// end;

procedure TPdfControl.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  XOffset, YOffset: Single;
begin
  inherited KeyDown(Key, KeyChar, Shift);
  
  if AllowFormEvents and IsPageValid then
  begin
    if CurrentPage.FormEventKeyDown(Key, Shift) then
    begin
       // PDFium doesn't handle Copy&Paste&Cut keyboard shortcuts in form fields
       // For FMX we might need a different way to trigger these, but let's keep the logic
       Exit;
    end;
  end;

  XOffset := 0;
  YOffset := 0;
  case Key of
    vkC:
      if AllowUserTextSelection then
      begin
        if ssCtrl in Shift then
        begin
          if FSelectionActive then
            CopyToClipboard;
          Key := 0;
        end
      end;

    vkA:
      if AllowUserTextSelection then
      begin
        if ssCtrl in Shift then
        begin
          SelectAll;
          Key := 0;
        end;
      end;

    vkLeft, vkRight:
      begin
        if ssShift in Shift then
          XOffset := cDefaultScrollOffset * 2
        else
          XOffset := cDefaultScrollOffset;
        if Key = vkLeft then
          XOffset := -XOffset;
      end;

    vkUp, vkDown:
      begin
        if ssShift in Shift then
          YOffset := cDefaultScrollOffset * 2
        else
          YOffset := cDefaultScrollOffset;
        if Key = vkUp then
          YOffset := -YOffset;
      end;

    vkPrior, vkNext:
      begin
        if AllowUserPageChange then
        begin
          if Key = vkNext then
            GotoNextPage(True)
          else
            GotoPrevPage(True);
        end;
      end;

    vkHome, vkEnd:
      begin
        if ssCtrl in Shift then
        begin
          if Key = vkHome then
            InternSetPageIndex(0, True, True)
          else
            InternSetPageIndex(PageCount - 1, True, True);
        end;
      end;
  end;

  if (XOffset <> 0) or (YOffset <> 0) then
  begin
    ScrollContent(Round(XOffset), Round(YOffset), SmoothScroll);
    Key := 0;
  end;
end;

procedure TPdfControl.KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if AllowFormEvents and IsPageValid
     and CurrentPage.FormEventKeyUp(Key, Shift) then
    Exit;
  inherited KeyUp(Key, KeyChar, Shift);
end;

procedure TPdfControl.GetPageWebLinks;
var
  Page: TPdfPage;
begin
  FreeAndNil(FWebLinkInfo);
  Page := CurrentPage;
  if Page <> nil then
    FWebLinkInfo := TPdfPageWebLinksInfo.Create(Page);
end;

function TPdfControl.LinkHandlingNeeded: Boolean;
begin
  // If an event handler is assigned, we need link handling
  Result := Assigned(FOnAnnotationLinkClick) or Assigned(FOnWebLinkClick);
  if not Result then
  begin
    // If no event handler is assigned, we may need link handling depending on the loAutoXXX options.
    Result := LinkOptions * cPdfControlAllAutoLinkOptions <> [];
  end;
end;

function TPdfControl.IsClickableLinkAt(X, Y: Integer): Boolean;
var
  LinkAnnotation: TPdfAnnotation;
begin
  Result := False;
  if LinkHandlingNeeded then
  begin
    LinkAnnotation := GetAnnotationLinkAt(X, Y);
    if LinkAnnotation <> nil then
    begin
      if Assigned(FOnAnnotationLinkClick) then
        Result := True
      else
      begin
        case LinkAnnotation.LinkType of
          altGoto:
            Result := loAutoGoto in LinkOptions;
          altRemoteGoto:
            Result := loAutoRemoteGotoReplaceDocument in LinkOptions;
          altURI:
            Result := (loAutoOpenURI in LinkOptions) or (loAlwaysDetectWebAndUriLink in LinkOptions) or Assigned(FOnWebLinkClick); // Fallback to OnWebLinkClick for URIs
          altLaunch:
            Result := loAutoLaunch in LinkOptions;
          altEmbeddedGoto:
            Result := loAutoEmbeddedGotoReplaceDocument in LinkOptions;
        else
          Result := False;
        end;
      end;
    end
    else if IsWebLinkAt(X, Y) then
    begin
      if Assigned(FOnWebLinkClick) or (loAlwaysDetectWebAndUriLink in LinkOptions) then
        Result := True
      else if Assigned(FOnAnnotationLinkClick) and (loTreatWebLinkAsUriAnnotationLink in LinkOptions) then
        Result := True
      else if not Assigned(FOnAnnotationLinkClick) and (loTreatWebLinkAsUriAnnotationLink in LinkOptions) and (loAutoOpenURI in LinkOptions) then
        Result := True;
    end;
  end;
end;

function TPdfControl.IsWebLinkAt(X, Y: Integer): Boolean;
var
  PdfPt: TPdfPoint;
begin
  if (FWebLinkInfo <> nil) and IsPageValid then
  begin
    PdfPt := DeviceToPage(X, Y);
    Result := FWebLinkInfo.IsWebLinkAt(PdfPt.X, PdfPt.Y);
  end
  else
    Result := False;
end;

function TPdfControl.IsWebLinkAt(X, Y: Integer; var Url: string): Boolean;
var
  PdfPt: TPdfPoint;
begin
  Url := '';
  if (FWebLinkInfo <> nil) and IsPageValid then
  begin
    PdfPt := DeviceToPage(X, Y);
    Result := FWebLinkInfo.IsWebLinkAt(PdfPt.X, PdfPt.Y, Url);
  end
  else
    Result := False;
end;

function TPdfControl.IsUriAnnotationLinkAt(X, Y: Integer): Boolean;
var
  PdfPt: TPdfPoint;
begin
  if IsPageValid then
  begin
    PdfPt := DeviceToPage(X, Y);
    Result := CurrentPage.IsUriLinkAtPoint(PdfPt.X, PdfPt.Y);
  end
  else
    Result := False;
end;

function TPdfControl.IsAnnotationLinkAt(X, Y: Integer): Boolean;
begin
  Result := GetAnnotationLinkAt(X, Y) <> nil;
end;

function TPdfControl.GetAnnotationLinkAt(X, Y: Integer): TPdfAnnotation;
var
  PdfPt: TPdfPoint;
begin
  if IsPageValid then
  begin
    PdfPt := DeviceToPage(X, Y);
    Result := CurrentPage.GetLinkAtPoint(PdfPt.X, PdfPt.Y);
  end
  else
    Result := nil;
end;

function TPdfControl.ShellOpenFileName(const FileName: string; Launch: Boolean): Boolean;
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  // Simplified for now, FMX doesn't have a direct ShellExecute wrapper but we can use Winapi.ShellAPI
  // or it might be better to use a cross-platform approach if available.
  {$ENDIF MSWINDOWS}
end;

procedure TPdfControl.WebLinkClick(const Url: string);
begin
  if Assigned(FOnWebLinkClick) then
    FOnWebLinkClick(Self, Url);
end;

function TPdfControl.GotoDestination(const LinkGotoDestination: TPdfLinkGotoDestination): Boolean;
var
  X, Y: Double;
  //Zoom: Integer;
  Pt: TPoint;
begin
  Result := False;
  if Document.Active then
  begin
    X := 0;
    Y := 0;
    //Zoom := 100;
    if LinkGotoDestination.XValid then
      X := LinkGotoDestination.X;
    if LinkGotoDestination.YValid then
      Y := LinkGotoDestination.Y;
    //if Dest.ZoomValid then
    //  Zoom := Int(Dest.Zoom);

    if (LinkGotoDestination.PageIndex >= 0) and (LinkGotoDestination.PageIndex < Document.PageCount) then
    begin
      Pt := PageToDevice(X, Y);

      PageIndex := LinkGotoDestination.PageIndex;
      //ZoomPercentage := Zoom;
      ScrollContentTo(Pt.X, Pt.Y);
      Result := True;
    end;
  end;
end;

procedure TPdfControl.AnnotationLinkClick(LinkInfo: TPdfLinkInfo);
var
  Handled: Boolean;
  Dest: TPdfLinkGotoDestination;
  FileName: string;
  RemoteDoc: TPdfDocument;
  DestValid: Boolean;
  AttachmentIndex: Integer;
begin
  Handled := False;
  if not Document.Active then
    Exit;

  if Assigned(FOnAnnotationLinkClick) then
    FOnAnnotationLinkClick(Self, LinkInfo, Handled)
  else if Assigned(FOnWebLinkClick) and (LinkInfo.LinkType = altURI) and not (loAutoOpenURI in LinkOptions) then
  begin
    WebLinkClick(LinkInfo.LinkUri);
    Exit;
  end;

  if not Handled and Document.Active then
  begin
    case LinkInfo.LinkType of
      altGoto:
        if loAutoGoto in LinkOptions then
        begin
          if LinkInfo.GetLinkGotoDestination(Dest) then
            GotoDestination(Dest);
        end;

      altRemoteGoto:
        if loAutoRemoteGotoReplaceDocument in LinkOptions then
        begin
          Dest := nil;
          RemoteDoc := TPdfDocument.Create;
          try
            // Open the remote document
            RemoteDoc.LoadFromFile(LinkInfo.LinkFileName);
            // Get the link destination from the remote document
            DestValid := LinkInfo.GetLinkGotoDestination(Dest, RemoteDoc);
          except
            RemoteDoc.Free;
            raise;
          end;
          if DestValid then
          begin
            // Replace the current document with the remote document
            OpenWithDocument(RemoteDoc);
            GotoDestination(Dest);
          end;
        end;

      altURI:
        if loAutoOpenURI in LinkOptions then
          ShellOpenFileName(LinkInfo.LinkUri, False);

      altLaunch:
        if loAutoLaunch in LinkOptions then
          ShellOpenFileName(LinkInfo.LinkFileName, True);

      altEmbeddedGoto:
        if loAutoEmbeddedGotoReplaceDocument in LinkOptions then
        begin
          FileName := LinkInfo.LinkFileName;
          AttachmentIndex := Document.Attachments.IndexOf(FileName);
          if AttachmentIndex <> -1 then
          begin
            // Same as RemoteGoto but with a byte array
            Dest := nil;
            RemoteDoc := TPdfDocument.Create;
            try
              // Open the embedded document
              RemoteDoc.LoadFromBytes(Document.Attachments[AttachmentIndex].GetContentAsBytes);
              // Get the link destination from the remote document
              DestValid := LinkInfo.GetLinkGotoDestination(Dest, RemoteDoc);
            except
              RemoteDoc.Free;
              raise;
            end;
            if DestValid then
            begin
              // Replace the current document with the remote document
              OpenWithDocument(RemoteDoc);
              GotoDestination(Dest);
            end;
          end;
        end;
    end;
  end;
end;

procedure TPdfControl.UpdatePageDrawInfo;
var
  Page: TPdfPage;
  MaxWidth, MaxHeight: Integer;
  W, H: Integer;
  PageWidth, PageHeight: Double;
begin
  Page := CurrentPage;
  if (Page <> nil) and (Page.Width > 0) and (Page.Height > 0) then
  begin
    // Take "Rotation" into account
    if Rotation in [prNormal, pr180] then
    begin
      PageWidth := Page.Width;
      PageHeight := Page.Height;
    end
    else
    begin
      PageHeight := Page.Width;
      PageWidth := Page.Height;
    end;

    MaxWidth := Round(Width);
    MaxHeight := Round(Height);
    
    // In FMX, we don't have GetDeviceCaps(LOGPIXELSX) directly on canvas.
    // We can use 96 as a default or use a service to get screen DPI.
    GetWidthHeight(PageWidth, PageHeight, 96, 96, MaxWidth, MaxHeight, W, H);

    FDrawWidth := W;
    FDrawHeight := H;
    AdjustDrawPos;
  end;
end;

procedure TPdfControl.GetWidthHeight(PageWidth, PageHeight: Double; DpiX, DpiY, MaxWidth, MaxHeight: Integer; var W, H: Integer);
  begin
    case ScaleMode of
      smFitAuto:
        begin
          W := Round(MaxHeight * (PageWidth / PageHeight));
          H := MaxHeight;
          if W > MaxWidth then
          begin
            W := MaxWidth;
            H := Round(MaxWidth * (PageHeight / PageWidth));
          end;
        end;

      smFitWidth:
        begin
          W := MaxWidth;
          H := Round(MaxWidth * (PageHeight / PageWidth));
        end;

      smFitHeight:
        begin
          W := Round(MaxHeight * (PageWidth / PageHeight));
          H := MaxHeight;
        end;

      smZoom: // PDFium's 100% is not AcrobatReader's 100%
        begin
          W := Round(PageWidth / 72 * DpiX * (ZoomPercentage / 100));
          H := Round(PageHeight / 72 * DpiY * (ZoomPercentage / 100));
        end;
    end;

    if (PageShadowColor <> TAlphaColors.Null) and (PageShadowSize > 0) and (PageShadowPadding > 0) then
    begin
      W := W - (PageShadowPadding + PageShadowSize);
      H := H - (PageShadowPadding + PageShadowSize);
    end;
  end;

procedure TPdfControl.AdjustDrawPos;
var
  X, Y: Integer;
begin
  X := Round((Width - FDrawWidth) / 2);
  Y := Round((Height - FDrawHeight) / 2);

  if FDrawWidth > Width then
    X := -FHorzScrollPos
  else
    FHorzScrollPos := 0;

  if FDrawHeight > Height then
    Y := -FVertScrollPos
  else
    FVertScrollPos := 0;

  if (FDrawX <> X) or (FDrawY <> Y) then
  begin
    FDrawX := X;
    FDrawY := Y;
    Repaint;
  end;
end;

procedure TPdfControl.SetAniHorzScrollPos(const Value: Single);
begin
  FAniHorzScrollPos := Value;
  FHorzScrollPos := Round(FAniHorzScrollPos);
  AdjustDrawPos;
end;

procedure TPdfControl.SetAniVertScrollPos(const Value: Single);
begin
  FAniVertScrollPos := Value;
  FVertScrollPos := Round(FAniVertScrollPos);
  AdjustDrawPos;
end;

function TPdfControl.ScrollContent(XOffset, YOffset: Integer; Smooth: Boolean): Boolean;
begin
  Result := ScrollContentTo(FHorzScrollPos + XOffset, FVertScrollPos + YOffset, Smooth);
end;

function TPdfControl.ScrollContentTo(X, Y: Integer; Smooth: Boolean): Boolean;
var
  MaxX, MaxY: Integer;
begin
  Result := False;
  if FDrawWidth > Width then
    MaxX := Round(FDrawWidth - Width)
  else
    MaxX := 0;

  if FDrawHeight > Height then
    MaxY := Round(FDrawHeight - Height)
  else
    MaxY := 0;

  if X < 0 then X := 0;
  if X > MaxX then X := MaxX;
  if Y < 0 then Y := 0;
  if Y > MaxY then Y := MaxY;

  if (X <> FHorzScrollPos) or (Y <> FVertScrollPos) then
  begin
    if Smooth then
    begin
      TAnimator.AnimateFloat(Self, 'AniHorzScrollPos', X, 0.2, TAnimationType.Out, TInterpolationType.Quadratic);
      TAnimator.AnimateFloat(Self, 'AniVertScrollPos', Y, 0.2, TAnimationType.Out, TInterpolationType.Quadratic);
    end
    else
    begin
      TAnimator.StopPropertyAnimation(Self, 'AniHorzScrollPos');
      TAnimator.StopPropertyAnimation(Self, 'AniVertScrollPos');
      FAniHorzScrollPos := X;
      FAniVertScrollPos := Y;
      FHorzScrollPos := X;
      FVertScrollPos := Y;
      AdjustDrawPos;
    end;
    Result := True;
  end;
end;



procedure TPdfControl.WMVScroll(var Message: TWMVScroll);
begin
end;

procedure TPdfControl.WMHScroll(var Message: TWMHScroll);
begin
end;

procedure TPdfControl.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  PagePt: TPdfPoint;
  P: TPointF;
begin
  P := ScreenToLocal(Screen.MousePos);
  inherited MouseWheel(Shift, WheelDelta, Handled);

  if not Handled then
  begin
    if IsPageValid and AllowFormEvents then
    begin
      PagePt := DeviceToPage(Round(P.X), Round(P.Y));
      if CurrentPage.FormEventMouseWheel(Shift, WheelDelta, PagePt.X, PagePt.Y) then
      begin
        Handled := True;
        Exit;
      end;
    end;

    if ssCtrl in Shift then
    begin
      if ScaleMode = smZoom then
      begin
        ZoomPercentage := ZoomPercentage + (WheelDelta div 120) * 5;
        Handled := True;
      end;
    end
    else
    begin
      if ssShift in Shift then
        Handled := ScrollContent(-WheelDelta, 0, FSmoothScroll)
      else
        Handled := ScrollContent(0, -WheelDelta, FSmoothScroll);

      if not Handled and FChangePageOnMouseScrolling then
      begin
        if WheelDelta < 0 then
          GotoNextPage()
        else if PageIndex > 0 then
        begin
          GotoPrevPage();
          ScrollContentTo(0, MaxInt);
        end;
        Handled := True;
      end;
    end;
  end;
end;

procedure TPdfControl.StopScrollTimer;
begin
  FScrollTimerActive := False;
end;

procedure TPdfControl.HightlightText(const SearchText: string; MatchCase, MatchWholeWord: Boolean);
begin
  if FHighlightTexts <> nil then
    FHighlightTexts.Clear;
  AddHightlightText(SearchText, MatchCase, MatchWholeWord);
end;

procedure TPdfControl.AddHightlightText(const SearchText: string; MatchCase, MatchWholeWord: Boolean);
var
  HLTextInfo: THighlightTextInfo;
  I: Integer;
begin
  if SearchText = '' then
    Exit;

  // Prevent duplicates
  if FHighlightTexts <> nil then
    for I := 0 to FHighlightTexts.Count - 1 do
      if (FHighlightTexts[I] as THighlightTextInfo).IsSame(SearchText, MatchCase, MatchWholeWord) then
        Exit;

  if FHighlightTexts = nil then
    FHighlightTexts := TObjectList.Create;
  HLTextInfo := THighlightTextInfo.Create(SearchText, MatchCase, MatchWholeWord);
  FHighlightTexts.Add(HLTextInfo);

  CalcHighlightTextRects;
end;

procedure TPdfControl.CalcHighlightTextRects;
var
  OldHighlightTextRects: TPdfRectArray;
  HLTextInfo: THighlightTextInfo;
  Page: TPdfPage;
  CharIndex, CharCount, I, Count, TextsIndex: Integer;
  Num: Integer;
begin
  OldHighlightTextRects := FHighlightTextRects;
  FHighlightTextRects := nil;
  if (FHighlightTexts <> nil) and (FHighlightTexts.Count > 0) and IsPageValid then
  begin
    Page := CurrentPage;
    Num := 0;
    for TextsIndex := 0 to FHighlightTexts.Count - 1 do
    begin
      HLTextInfo := FHighlightTexts[TextsIndex] as THighlightTextInfo;
      if HLTextInfo.Text <> '' then // prevent infinite loop in FPDFText_FindNext()
      begin
        if Page.BeginFind(HLTextInfo.Text, HLTextInfo.MatchCase, HLTextInfo.MatchWholeWord, False) then
        begin
          try
            while Page.FindNext(CharIndex, CharCount) do
            begin
              Count := Page.GetTextRectCount(CharIndex, CharCount);
              if Num + Count > Length(FHighlightTextRects) then
                SetLength(FHighlightTextRects, (Num + Count) * 2);
              for I := 0 to Count - 1 do
              begin
                FHighlightTextRects[Num] := Page.GetTextRect(I);
                Inc(Num);
              end;
            end;
          finally
            Page.EndFind;
          end;
        end;
      end;
    end;

    // truncate to the actual number
    if Num <> Length(FHighlightTextRects) then
      SetLength(FHighlightTextRects, Num);
  end;
  InvalidatePdfRectDiffs(OldHighlightTextRects, FHighlightTextRects);
end;

procedure TPdfControl.ClearHighlightText;
begin
  FreeAndNil(FHighlightTexts);
  InvalidatePdfRectDiffs(FHighlightTextRects, nil);
  FHighlightTextRects := nil;
end;

procedure TPdfControl.FormInvalidate(Document: TPdfDocument; Page: TPdfPage;
  const PageRect: TPdfRect);
begin
  FRenderedPageIndex := -1;
  FFormOutputSelectedRects := nil;
  Repaint;
end;

procedure TPdfControl.FormOutputSelectedRect(Document: TPdfDocument; Page: TPdfPage;
  const PageRect: TPdfRect);
begin
  SetLength(FFormOutputSelectedRects, Length(FFormOutputSelectedRects) + 1);
  FFormOutputSelectedRects[Length(FFormOutputSelectedRects) - 1] := PageRect;
end;

procedure TPdfControl.FormGetCurrentPage(Document: TPdfDocument; var Page: TPdfPage);
begin
  Page := CurrentPage;
end;

procedure TPdfControl.FormFieldFocus(Document: TPdfDocument; Value: PWideChar;
  ValueLen: Integer; FieldFocused: Boolean);
begin
  ClearSelection;
  FFormFieldFocused := FieldFocused;
end;

procedure TPdfControl.ExecuteNamedAction(Document: TPdfDocument; NamedAction: TPdfNamedActionType);
begin
  case NamedAction of
    naPrint:
      PrintDocument;
    naNextPage:
      PageIndex := PageIndex + 1;
    naPrevPage:
      PageIndex := PageIndex - 1;
    naFirstPage:
      PageIndex := 0;
    naLastPage:
      PageIndex := Document.PageCount - 1;
  end;
end;

end.

