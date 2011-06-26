unit u_SimpleDownloader;

interface

uses
  ALHTTPCommon,
  ALHttpClient,
  ALWinInetHttpClient,
  Classes,
  SysUtils,
  SyncObjs,
  i_InetConfig,
  i_ProxySettings,
  i_SimpleDownloader;

type
  TSimpleDownloaderThread = class (TThread)
    private
      FUrl: string;
      FAcceptEncoding: string;
      FRequestHead: string;
      FRequestBuf: TMemoryStream;
      FOnDownload: TSimpleDownloaderEvent;
      FSimpleDownloader: ISimpleDownloader;
      FResponseBuf: TMemoryStream;
      FContentType: string;
      FResponseHead: string;
      FResponseCode: Cardinal;
      procedure OnDownload;
    protected
      procedure Execute; override;
    public
      constructor Create(
        AUrl: string;
        AAcceptEncoding: string;
        ARequestHead: string;
        ARequestBuf: TMemoryStream;
        AOnDownload: TSimpleDownloaderEvent;
        ASimpleDownloader: ISimpleDownloader
      );
      destructor Destroy; override;
  end;

  TSimpleDownloader = class (TInterfacedObject, ISimpleDownloader)
  private
    FHttpClient: TALWinInetHTTPClient;
    FResponseHeader: TALHTTPResponseHeader;
    FInetConfig: IInetConfig;
    FDownloaderCS: TCriticalSection;
  public
    constructor Create(AInetConfig: IInetConfig);
    destructor Destroy; override;
    function GetFromInternet(
      AUrl: string;
      AAcceptEncoding: string;
      ARequestHead: string;
      ARequestBuf: TMemoryStream;
      AResponseBuf: TMemoryStream;
      out AContentType: string;
      out AResponseHead: string
    ): Cardinal;
    procedure GetFromInternetAsync(
      AUrl: string;
      AAcceptEncoding: string;
      ARequestHead: string;
      ARequestBuf: TMemoryStream;
      AOnDownload: TSimpleDownloaderEvent
    );
  end;

implementation

{ TSimpleDownloaderThread }

constructor TSimpleDownloaderThread.Create(
  AUrl: string;
  AAcceptEncoding: string;
  ARequestHead: string;
  ARequestBuf: TMemoryStream;
  AOnDownload: TSimpleDownloaderEvent;
  ASimpleDownloader: ISimpleDownloader
);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FUrl := AUrl;
  FAcceptEncoding := AAcceptEncoding;
  FRequestHead := ARequestHead;
  FRequestBuf := ARequestBuf;
  FOnDownload := AOnDownload;
  FSimpleDownloader := ASimpleDownloader;
  FResponseBuf := TMemoryStream.Create;
  FContentType := '';
  FResponseHead := '';
  FResponseCode := 0;
  Resume;
end;

destructor TSimpleDownloaderThread.Destroy;
begin
  FreeAndNil(FResponseBuf);
  inherited Destroy;
end;

procedure TSimpleDownloaderThread.Execute;
begin
  try
    try
      if FSimpleDownloader <> nil then begin
        FResponseCode := FSimpleDownloader.GetFromInternet(
          FUrl,
          FAcceptEncoding,
          FRequestHead,
          FRequestBuf,
          FResponseBuf,
          FContentType,
          FResponseHead
        );
      end;
    finally
      if Assigned(FOnDownload) then begin
        Synchronize(Self, OnDownload);
      end;
    end;
  finally
    Terminate;
  end;
end;

procedure TSimpleDownloaderThread.OnDownload;
begin
  FOnDownload(
    Self,
    FResponseCode,
    FContentType,
    FResponseHead,
    FResponseBuf
  );
end;

{ TSimpleDownloader }

constructor TSimpleDownloader.Create(AInetConfig: IInetConfig);
begin
  inherited Create;
  FInetConfig := AInetConfig;
  FDownloaderCS := TCriticalSection.Create;
end;

destructor TSimpleDownloader.Destroy;
begin
  try
    if Assigned(FHttpClient) then begin
      FreeAndNil(FHttpClient);
    end;
    if Assigned(FResponseHeader) then begin
      FreeAndNil(FResponseHeader);
    end;
    if Assigned(FDownloaderCS) then begin
      FreeAndNil(FDownloaderCS);
    end;
  finally
    inherited Destroy;
  end;
end;

function TSimpleDownloader.GetFromInternet(
  AUrl: string;
  AAcceptEncoding: string;
  ARequestHead: string;
  ARequestBuf: TMemoryStream;
  AResponseBuf: TMemoryStream;
  out AContentType: string;
  out AResponseHead: string
): Cardinal;
var
  VInternetConfigStatic: IInetConfigStatic;
  VProxyConfigStatic: IProxyConfigStatic;
  VTimeOut: Cardinal;
begin
  FDownloaderCS.Acquire;
  try
    Result := 0;
    AResponseBuf.Clear;
    AContentType := '';
    AResponseHead := '';
    if AUrl <> '' then begin
      if not Assigned(FHttpClient) then begin
        FHttpClient := TALWinInetHTTPClient.Create(nil);
      end;
      if not Assigned(FResponseHeader) then begin
        FResponseHeader := TALHTTPResponseHeader.Create;
      end;
      if Assigned(FHttpClient) and Assigned(FResponseHeader) then
      try
        FResponseHeader.Clear;

        VInternetConfigStatic := FInetConfig.GetStatic;

        FHttpClient.RequestHeader.UserAgent := VInternetConfigStatic.UserAgentString;

        if AAcceptEncoding <> '' then begin
          FHttpClient.RequestHeader.Accept := AAcceptEncoding;
        end else begin
          FHttpClient.RequestHeader.Accept := '*/*';
        end;

        if ARequestHead <> '' then begin
          FHttpClient.RequestHeader.RawHeaderText := ARequestHead;
        end;

        VTimeOut := VInternetConfigStatic.TimeOut;
        FHttpClient.ConnectTimeout := VTimeOut;
        FHttpClient.SendTimeout := VTimeOut;
        FHttpClient.ReceiveTimeout := VTimeOut;

        FHttpClient.InternetOptions := [  wHttpIo_No_cache_write,
                                          wHttpIo_Pragma_nocache,
                                          wHttpIo_No_cookies,
                                          wHttpIo_Keep_connection
                                       ];

        VProxyConfigStatic := VInternetConfigStatic.ProxyConfigStatic;
        if Assigned(VProxyConfigStatic) then begin
          if VProxyConfigStatic.UseIESettings then begin
            FHttpClient.AccessType := wHttpAt_Preconfig
          end else begin
            if VProxyConfigStatic.UseProxy then begin
              FHttpClient.AccessType := wHttpAt_Proxy;
              FHttpClient.ProxyParams.ProxyServer := Copy(VProxyConfigStatic.Host, 0, Pos(':', VProxyConfigStatic.Host) - 1);
              FHttpClient.ProxyParams.ProxyPort := StrToInt(Copy(VProxyConfigStatic.Host, Pos(':', VProxyConfigStatic.Host) + 1));
              if VProxyConfigStatic.UseLogin then begin
                FHttpClient.ProxyParams.ProxyUserName := VProxyConfigStatic.Login;
                FHttpClient.ProxyParams.ProxyPassword := VProxyConfigStatic.Password;
              end;
            end else begin
              FHttpClient.AccessType := wHttpAt_Direct;
            end;
          end;
        end;

        try
          if Assigned(ARequestBuf) then begin
            ARequestBuf.Position := 0;
            FHttpClient.Post(AUrl, ARequestBuf, AResponseBuf, FResponseHeader);
          end else begin
            FHttpClient.Get(AUrl, AResponseBuf, FResponseHeader);
          end;
        except
          on E: EALHTTPClientException do begin
            if E.StatusCode = 0 then begin
              raise Exception.Create(E.Message); // Unknown connection Error
            end else begin
              Result := E.StatusCode;            // Http Error
            end;
          end;
        end;

      finally
        if Assigned(FResponseHeader) then begin
          if FResponseHeader.RawHeaderText <> '' then begin
            AContentType := FResponseHeader.ContentType;
            AResponseHead := FResponseHeader.RawHeaderText;
            if Result = 0 then begin
              Result := StrToIntDef(FResponseHeader.StatusCode, 0);
            end;
          end;
        end;
      end;
    end;
  finally
    FDownloaderCS.Release;
  end;
end;

procedure TSimpleDownloader.GetFromInternetAsync(
  AUrl: string;
  AAcceptEncoding: string;
  ARequestHead: string;
  ARequestBuf: TMemoryStream;
  AOnDownload: TSimpleDownloaderEvent
);
begin
  TSimpleDownloaderThread.Create(
    AUrl,
    AAcceptEncoding,
    ARequestHead,
    ARequestBuf,
    AOnDownload,
    Self
  );
end;

end.
