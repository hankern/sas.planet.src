unit u_MapVersionConfig;

interface

uses
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_MapVersionInfo,
  i_MapVersionConfig,
  u_ConfigDataElementBase;

type
  TMapVersionConfig = class(TConfigDataElementBase, IMapVersionConfig)
  private
    FVersion: Variant;
    FStatic: IMapVersionInfo;
    function CreateStatic: IMapVersionInfo;
  protected
    procedure SetChanged; override;
    procedure DoReadConfig(AConfigData: IConfigDataProvider); override;
    procedure DoWriteConfig(AConfigData: IConfigDataWriteProvider); override;
  protected
    function GetVersion: Variant;
    procedure SetVersion(const AValue: Variant);

    function GetStatic: IMapVersionInfo;
  public
    constructor Create(ADefConfig: IMapVersionInfo);
  end;


implementation

uses
  u_MapVersionInfo;

{ TMapVersionConfig }

constructor TMapVersionConfig.Create(ADefConfig: IMapVersionInfo);
begin
  inherited Create;
  FVersion := ADefConfig.Version;
end;

function TMapVersionConfig.CreateStatic: IMapVersionInfo;
begin
  Result := TMapVersionInfo.Create(FVersion);
end;

procedure TMapVersionConfig.DoReadConfig(AConfigData: IConfigDataProvider);
begin
  inherited;
  if AConfigData <> nil then begin
    FVersion := AConfigData.ReadString('Version', FVersion);
    SetChanged;
  end;
end;

procedure TMapVersionConfig.DoWriteConfig(
  AConfigData: IConfigDataWriteProvider);
begin
  inherited;
  AConfigData.WriteString('Version', FVersion);
end;

function TMapVersionConfig.GetStatic: IMapVersionInfo;
begin
  Result := FStatic;
end;

function TMapVersionConfig.GetVersion: Variant;
begin
  LockRead;
  try
    Result := FVersion;
  finally
    UnlockRead;
  end;
end;

procedure TMapVersionConfig.SetChanged;
begin
  inherited;
  LockWrite;
  try
    FStatic := CreateStatic;
  finally
    UnlockWrite;
  end;
end;

procedure TMapVersionConfig.SetVersion(const AValue: Variant);
begin
  LockWrite;
  try
    if FVersion <> AValue then begin
      FVersion := AValue;
      SetChanged;
    end;
  finally
    UnlockWrite;
  end;
end;

end.
