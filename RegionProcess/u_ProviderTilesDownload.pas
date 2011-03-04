unit u_ProviderTilesDownload;

interface

uses
  Windows,
  Forms,
  t_GeoTypes,
  u_ExportProviderAbstract,
  fr_TilesDownload;

type
  TProviderTilesDownload = class(TExportProviderAbstract)
  private
    FFrame: TfrTilesDownload;
  public
    destructor Destroy; override;
    function GetCaption: string; override;
    procedure InitFrame(Azoom: byte; APolygon: TArrayOfDoublePoint); override;
    procedure Show; override;
    procedure Hide; override;
    procedure RefreshTranslation; override;
    procedure StartProcess(APolygon: TArrayOfDoublePoint); override;
  end;


implementation

uses
  SysUtils,
  i_ILogSimple,
  i_ILogForTaskThread,
  u_LogForTaskThread,
  u_ThreadDownloadTiles,
  Unit1,
  UProgress,
  UResStrings,
  UMapType;

{ TProviderTilesDownload }

destructor TProviderTilesDownload.Destroy;
begin
  FreeAndNil(FFrame);
  inherited;
end;

function TProviderTilesDownload.GetCaption: string;
begin
  Result := SAS_STR_OperationDownloadCaption;
end;

procedure TProviderTilesDownload.InitFrame(Azoom: byte; APolygon: TArrayOfDoublePoint);
begin
  if FFrame = nil then begin
    FFrame := TfrTilesDownload.Create(nil);
    FFrame.Visible := False;
    FFrame.Parent := FParent;
  end;
  FFrame.Init(Azoom,APolygon);
end;

procedure TProviderTilesDownload.RefreshTranslation;
begin
  inherited;
  if FFrame <> nil then begin
    FFrame.RefreshTranslation;
  end;
end;

procedure TProviderTilesDownload.Hide;
begin
  inherited;
  if FFrame <> nil then begin
    if FFrame.Visible then begin
      FFrame.Hide;
    end;
  end;
end;

procedure TProviderTilesDownload.Show;
begin
  inherited;
  if FFrame <> nil then begin
    if not FFrame.Visible then begin
      FFrame.Show;
    end;
  end;
end;

procedure TProviderTilesDownload.StartProcess(APolygon: TArrayOfDoublePoint);
var
  smb:TMapType;
  VZoom: byte;
  VLog: TLogForTaskThread;
  VSimpleLog: ILogSimple;
  VThreadLog:ILogForTaskThread;
  VThread: TThreadDownloadTiles;
begin
  smb:=TMapType(FFrame.cbbMap.Items.Objects[FFrame.cbbMap.ItemIndex]);
  VZoom := FFrame.cbbZoom.ItemIndex;
  VLog := TLogForTaskThread.Create(5000, 0);
  VSimpleLog := VLog;
  VThreadLog := VLog;
  VThread := TThreadDownloadTiles.Create(
    VSimpleLog,
    APolygon,
    FFrame.chkReplace.Checked,
    FFrame.chkReplaceIfDifSize.Checked,
    FFrame.chkReplaceOlder.Checked,
    FFrame.chkTryLoadIfTNE.Checked,
    VZoom,
    smb,
    FFrame.dtpReplaceOlderDate.DateTime
  );
  TFProgress.Create(Application, VThread, VThreadLog, Fmain.OnMapUpdate);
end;

end.

