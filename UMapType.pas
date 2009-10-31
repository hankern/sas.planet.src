unit UMapType;

interface

uses
  Windows,
  Forms,
  sysutils,
  Classes,
  IniFiles,
  Dialogs,
  Graphics,
  StdCtrls,
  ComCtrls,
  SyncObjs,
  Menus,
  math,
  ExtCtrls,
  Uprogress,
  TBX,
  VCLZip,
  GR32,
  t_GeoTypes,
  i_ICoordConverter,
  u_TileDownloaderBase,
  u_UrlGenerator,
  UResStrings;

type
 TMapType = class
   protected
    FUrlGenerator : TUrlGenerator;
    TileRect:TRect;
    pos: integer;
    filename: string;
    function GetCoordConverter: ICoordConverter;
   public
    id: integer;
    guids: string;
    zmpfilename:string;
    active:boolean;
    info:string;
    showinfo:boolean;
    ShowOnSmMap:boolean;
    asLayer:boolean;
    name: string;
    Icon24Name,Icon18Name:string;
    HotKey:TShortCut;
    DefHotKey:TShortCut;
    URLBase: string;
    DefURLBase: string;
    UseDwn,Usestick,UseGenPrevious,Usedel,Usesave:boolean;
    UseSubDomain:boolean;
    UseAntiBan:integer;
    Sleep,DefSleep:Integer;
    separator:boolean;
    Defseparator:boolean;
    DelAfterShow:boolean;
    GetURLScript:string;
    projection:byte;
    cachetype:byte;
    defcachetype:byte;
    CONTENT_TYPE:string;
    STATUS_CODE:string;
    BanIfLen:integer;
    radiusa,radiusb,exct:extended;
    ext,ParentSubMenu:string;
    DefParentSubMenu:string;
    NSmItem,TBItem,NLayerParamsItem,TBFillingItem:TTBXItem;
    TBSubMenuItem:TTBXSubmenuItem;
    NDwnItem,NDelItem:TMenuItem;
    NameInCache:string;
    DefNameInCache:string;
    bmp18,bmp24:TBitmap;
    FCoordConverter : ICoordConverter;
    //��� ������ � ������
    ban_pg_ld: Boolean;

    function GetLink(x,y:longint;Azoom:byte):string;overload;
    function GetLink(AXY: TPoint;Azoom:byte):string;overload;

    procedure LoadMapTypeFromZipFile(AZipFileName : string; pnum : Integer);

    procedure SaveTileDownload(x,y:longint;Azoom:byte; ATileStream:TCustomMemoryStream; ty: string); overload;
    procedure SaveTileDownload(AXY: TPoint;Azoom:byte; ATileStream:TCustomMemoryStream; ty: string); overload;
    function CheckIsBan(AXY: TPoint; AZoom: byte; StatusCode: Cardinal; ty: string; fileBuf: TMemoryStream): Boolean;


    function GetTileFileName(x,y:longint;Azoom:byte):string; overload;
    function GetTileFileName(AXY: TPoint;Azoom:byte):string; overload;

    function TileExists(x,y:longint;Azoom:byte): Boolean; overload;
    function TileExists(AXY: TPoint;Azoom:byte): Boolean; overload;

    function TileNotExistsOnServer(x,y:longint;Azoom:byte): Boolean; overload;
    function TileNotExistsOnServer(AXY: TPoint;Azoom:byte): Boolean; overload;

    function LoadTile(btm:Tobject; x,y:longint;Azoom:byte; caching:boolean):boolean;
    function LoadTileFromPreZ(spr:TBitmap32;x,y:integer;Azoom:byte; caching:boolean):boolean;

    function DeleteTile(x,y:longint; Azoom:byte): Boolean; overload;
    function DeleteTile(AXY: TPoint; Azoom:byte): Boolean; overload;

    procedure SaveTileSimple(x,y:longint;Azoom:byte; btm:TObject);
    procedure SaveTileNotExists(x,y:longint;Azoom:byte);
    function TileLoadDate(x,y:longint;Azoom:byte): TDateTime;
    function TileSize(x,y:longint;Azoom:byte): integer;
    function TileExportToFile(x,y:longint;Azoom:byte; AFileName: string; OverWrite: boolean): boolean;

    // ������ ����� ���������� �� ����� �� ������ AZoom ������� ������ ASourceZoom
    // ������ ��������� ��������� �� ��������� IsStop �� ����� �� ����������
    function LoadFillingMap(btm:TBitmap32; x,y:longint;Azoom:byte;ASourceZoom: byte; IsStop: PBoolean):boolean;

    function GetShortFolderName: string;

    function IncDownloadedAndCheckAntiBan: Boolean;
    procedure addDwnforban;
    procedure ExecOnBan(ALastUrl: string);
    function DownloadTile(AXY: TPoint; AZoom: byte; ACheckTileSize: Boolean; AOldTileSize: Integer; out AUrl: string; out AContentType: string; fileBuf:TMemoryStream): TDownloadTileResult;

    property GeoConvert: ICoordConverter read GetCoordConverter;

    constructor Create;
    destructor Destroy; override;
  private
    FDownloadTilesCount: Longint;
    FInitDownloadCS: TCriticalSection;
    FDownloader: TTileDownloaderBase;
    function LoadFile(btm:Tobject; APath: string; caching:boolean):boolean;
    procedure CreateDirIfNotExists(APath:string);
    procedure SaveTileInCache(btm:TObject;path:string);
    function GetBasePath: string;
    function GetDownloader: TTileDownloaderBase;
  end;
var
  MapType:array of TMapType;
  MapsEdit:boolean;
  sat_map_both:TMapType;
  GMiniMapPopupMenu: TTBXPopupMenu;

  procedure LoadMaps;
  procedure SaveMaps;
  procedure CreateMapUI;
  function GetMapFromID(id:string):TMapType;

implementation

uses
  pngimage,
  IJL,
  jpeg,
  gifimage,
  GR32_Resamplers,
  VCLUnZip,
  u_GlobalState,
  Usettings,
  unit1,
  UGeoFun,
  UFillingMap,
  UIMGFun,
  DateUtils,
  ImgMaker,
  UKmlParse,
  u_MiniMap,
  u_CoordConverterMercatorOnSphere,
  u_CoordConverterMercatorOnEllipsoid,
  u_CoordConverterSimpleLonLat;

function GetMapFromID(id:string):TMapType;
var i:integer;
begin
 for i:=0 to length(MapType)-1 do
  if MapType[i].guids=id then begin
                               result:=MapType[i];
                               exit;
                              end;
 result:=nil;
end;

procedure CreateMapUI;
var i,j:integer;
begin
 FSettings.MapList.Clear;
 Fmain.MapIcons24.Clear;
 Fmain.MapIcons18.Clear;
 Fmain.TBSMB.Clear;
 Fmain.NSMB.Clear;
 Fmain.ldm.Clear;
 Fmain.dlm.Clear;
 Fmain.NLayerParams.Clear;
 Fmain.NSubMenuSmItem.Clear;
 for i:=0 to Fmain.NLayerSel.Count-1 do Fmain.NLayerSel.Items[0].Free;
 for i:=0 to Fmain.TBLayerSel.Count-1 do Fmain.TBLayerSel.Items[0].Free;
 for i:=0 to Fmain.TBFillingTypeMap.Count-2 do Fmain.TBFillingTypeMap.Items[1].Free;
 for i:=0 to GMiniMapPopupMenu.Items.Count-3 do GMiniMapPopupMenu.Items.Items[2].Free;

 GMiniMap.maptype:=nil;
 fillingmaptype:=nil;
 i:=length(MapType)-1;
 if i>0 then
 for i:=0 to length(MapType)-1 do
  With MapType[i] do
  begin
   TBItem:=TTBXItem.Create(Fmain.TBSMB);
   if ParentSubMenu=''
    then if asLayer then Fmain.TBLayerSel.Add(TBItem)
                    else Fmain.TBSMB.Add(TBItem)
    else begin
          j:=0;
          While MapType[j].ParentSubMenu<>ParentSubMenu do inc(j);
          TBSubMenuItem:=TTBXSubmenuItem.Create(Fmain.TBSMB);
          TBSubMenuItem.caption:=ParentSubMenu;
          TBSubMenuItem.Images:=Fmain.MapIcons18;
          if j=i then
          begin
          if asLayer then Fmain.TBLayerSel.Add(TBSubMenuItem)
                     else Fmain.TBSMB.Add(TBSubMenuItem);
          end;
          MapType[j].TBSubMenuItem.Add(TBItem);
         end;
   Fmain.MapIcons24.AddMasked(bmp24,RGB(255,0,255));
   Fmain.MapIcons18.AddMasked(bmp18,RGB(255,0,255));
   TBItem.Name:='TBMapN'+inttostr(id);
   TBItem.ShortCut:=HotKey;
   TBItem.ImageIndex:=i;
   TBItem.Caption:=name;
   TBItem.OnAdjustFont:=Fmain.AdjustFont;
   TBItem.OnClick:=Fmain.TBmap1Click;

   TBFillingItem:=TTBXItem.Create(Fmain.TBFillingTypeMap);
   TBFillingItem.name:='TBMapFM'+inttostr(id);
   TBFillingItem.ImageIndex:=i;
   TBFillingItem.Caption:=name;
   TBFillingItem.OnAdjustFont:=Fmain.AdjustFont;
   TBFillingItem.OnClick:=Fmain.TBfillMapAsMainClick;
   Fmain.TBFillingTypeMap.Add(TBFillingItem);

   if ext<>'.kml' then
    begin
     if not(asLayer) then begin
                           NSmItem:=TTBXITem.Create(GMiniMapPopupMenu);
                           GMiniMapPopupMenu.Items.Add(NSmItem)
                          end
                     else begin
                           NSmItem:=TTBXITem.Create(Fmain.NSubMenuSmItem);
                           Fmain.NSubMenuSmItem.Add(NSmItem);
                          end;
     NSmItem.Name:='NSmMapN'+inttostr(id);
     NSmItem.ImageIndex:=i;
     NSmItem.Caption:=name;
     NSmItem.OnAdjustFont:=Fmain.AdjustFont;
     NSmItem.OnClick:=Fmain.NMMtype_0Click;
     if ShowOnSmMap then NSmItem.Checked:=true;
    end;
   if asLayer then
    begin
     NDwnItem:=TMenuItem.Create(nil);
     NDwnItem.Caption:=name;
     NDwnItem.ImageIndex:=i;
     NDwnItem.OnClick:=Fmain.N21Click;
     Fmain.ldm.Add(NDwnItem);
     NDelItem:=TMenuItem.Create(nil);
     NDelItem.Caption:=name;
     NDelItem.ImageIndex:=i;
     NDelItem.OnClick:=Fmain.NDelClick;
     Fmain.dlm.Add(NDelItem);
     NLayerParamsItem:=TTBXItem.Create(Fmain.NLayerParams);
     NLayerParamsItem.Caption:=name;
     NLayerParamsItem.ImageIndex:=i;
     NLayerParamsItem.OnClick:=Fmain.NMapParamsClick;
     Fmain.NLayerParams.Add(NLayerParamsItem);
    end;
   if (asLayer)and(active) then TBItem.Checked:=true;
   if separator then
    begin
     TBItem.Parent.Add(TTBXSeparatorItem.Create(Fmain.TBSMB));
     if NSmItem<>NIL  then  NSmItem.Parent.Add(TTBXSeparatorItem.Create(Fmain.NSubMenuSmItem));
     TBFillingItem.Parent.Add(TTBXSeparatorItem.Create(Fmain.NSubMenuSmItem));
    end;
   if (active)and(MapType[i].asLayer=false) then sat_map_both:=MapType[i];
   if (ShowOnSmMap)and(not(asLayer)) then GMiniMap.maptype:=MapType[i];
   TBItem.Tag:=Longint(MapType[i]);
   TBFillingItem.Tag:=Longint(MapType[i]);
   if ext<>'.kml' then NSmItem.Tag:=Longint(MapType[i]);
   if asLayer then
    begin
     NDwnItem.Tag:=longint(MapType[i]);
     NDelItem.Tag:=longint(MapType[i]);
     NLayerParamsItem.Tag:=longint(MapType[i]);
    end;
   FSettings.MapList.AddItem(MapType[i].name,nil);
   FSettings.MapList.Items.Item[i].Data:=MapType[i];
   FSettings.MapList.Items.Item[i].SubItems.Add(MapType[i].NameInCache);
   if MapType[i].asLayer then FSettings.MapList.Items.Item[i].SubItems.Add(SAS_STR_Layers+'\'+MapType[i].ParentSubMenu)
                         else FSettings.MapList.Items.Item[i].SubItems.Add(SAS_STR_Maps+'\'+MapType[i].ParentSubMenu);
   FSettings.MapList.Items.Item[i].SubItems.Add(ShortCutToText(MapType[i].HotKey));
   FSettings.MapList.Items.Item[i].SubItems.Add(MapType[i].filename);
  end;
 if FSettings.MapList.Items.Count>0 then FSettings.MapList.Items.Item[0].Selected:=true;
 if GMiniMap.maptype=nil then Fmain.NMMtype_0.Checked:=true;
 if (sat_map_both=nil)and(MapType[0]<>nil) then sat_map_both:=MapType[0];
end;

procedure LoadMaps;
var  Ini: TMeminifile;
     i,j,k,pnum: integer;
     startdir : string;
     SearchRec: TSearchRec;
     MTb:TMapType;
begin
 SetLength(MapType,0);
 CreateDir(GState.MapsPath);
 Ini:=TMeminiFile.Create(GState.ProgramPath+'Maps\Maps.ini');
 i:=0;
 pnum:=0;
 startdir:=GState.MapsPath;
 if FindFirst(startdir+'*.zmp', faAnyFile, SearchRec) = 0 then
  repeat
   inc(i);
  until FindNext(SearchRec) <> 0;
 SysUtils.FindClose(SearchRec);
 SetLength(MapType,i);
 if FindFirst(startdir+'*.zmp', faAnyFile, SearchRec) = 0 then
  repeat
   if (SearchRec.Attr and faDirectory) = faDirectory then continue;
   MapType[pnum]:=TMapType.Create;
   MapType[pnum].zmpfilename:=SearchRec.Name;
   MapType[pnum].LoadMapTypeFromZipFile(startdir+SearchRec.Name, pnum);
   MapType[pnum].ban_pg_ld := true;
   if Ini.SectionExists(MapType[pnum].GUIDs)
    then With MapType[pnum] do
          begin
           id:=Ini.ReadInteger(GUIDs,'pnum',0);
           active:=ini.ReadBool(GUIDs,'active',false);
           ShowOnSmMap:=ini.ReadBool(GUIDs,'ShowOnSmMap',true);
           URLBase:=ini.ReadString(GUIDs,'URLBase',URLBase);
           CacheType:=ini.ReadInteger(GUIDs,'CacheType',cachetype);
           NameInCache:=ini.ReadString(GUIDs,'NameInCache',NameInCache);
           HotKey:=ini.ReadInteger(GUIDs,'HotKey',HotKey);
           ParentSubMenu:=ini.ReadString(GUIDs,'ParentSubMenu',ParentSubMenu);
           Sleep:=ini.ReadInteger(GUIDs,'Sleep',Sleep);
           separator:=ini.ReadBool(GUIDs,'separator',separator);
          end
    else With MapType[pnum] do
          begin
           showinfo:=true;
           if pos < 0 then pos := i;
           id := pos;
           dec(i);
           active:=false;
           ShowOnSmMap:=false;
          end;
   inc(pnum);
  until FindNext(SearchRec) <> 0;
 SysUtils.FindClose(SearchRec);
 ini.Free;

 k := length(MapType) shr 1;
 while k>0 do
  begin
   for i:=0 to length(MapType)-k-1 do
    begin
      j:=i;
      while (j>=0)and(MapType[j].id>MapType[j+k].id) do
      begin
        MTb:=MapType[j];
        MapType[j]:=MapType[j+k];
        MapType[j+k]:=MTb;
        if j>k then Dec(j,k)
               else j:=0;
      end;
    end;
   k:=k shr 1;
  end;
 MTb:=nil;
 MTb.Free;
 for i:=0 to length(MapType)-1 do begin MapType[i].id:=i+1; end;
end;

procedure SaveMaps;
var  Ini: TMeminifile;
       i: integer;
begin
 Ini:=TMeminiFile.Create(GState.ProgramPath+'Maps\Maps.ini');
 for i:=0 to length(MapType)-1 do
       begin
         ini.WriteInteger(MapType[i].guids,'pnum',MapType[i].id);
         ini.WriteBool(MapType[i].guids,'active',MapType[i].active);
         ini.WriteBool(MapType[i].guids,'ShowOnSmMap',MapType[i].ShowOnSmMap);
         if MapType[i].URLBase<>MapType[i].DefURLBase then
          ini.WriteString(MapType[i].guids,'URLBase',MapType[i].URLBase)
          else Ini.DeleteKey(MapType[i].guids,'URLBase');
         if MapType[i].HotKey<>MapType[i].DefHotKey then
          ini.WriteInteger(MapType[i].guids,'HotKey',MapType[i].HotKey)
          else Ini.DeleteKey(MapType[i].guids,'HotKey');
         if MapType[i].cachetype<>MapType[i].defcachetype then
          ini.WriteInteger(MapType[i].guids,'CacheType',MapType[i].CacheType)
          else Ini.DeleteKey(MapType[i].guids,'CacheType');
         if MapType[i].separator<>MapType[i].Defseparator then
          ini.WriteBool(MapType[i].guids,'separator',MapType[i].separator)
          else Ini.DeleteKey(MapType[i].guids,'separator');
         if MapType[i].NameInCache<>MapType[i].DefNameInCache then
          ini.WriteString(MapType[i].guids,'NameInCache',MapType[i].NameInCache)
          else Ini.DeleteKey(MapType[i].guids,'NameInCache');
         if MapType[i].Sleep<>MapType[i].DefSleep then
          ini.WriteInteger(MapType[i].guids,'Sleep',MapType[i].sleep)
          else Ini.DeleteKey(MapType[i].guids,'Sleep');
         if MapType[i].ParentSubMenu<>MapType[i].DefParentSubMenu then
          ini.WriteString(MapType[i].guids,'ParentSubMenu',MapType[i].ParentSubMenu)
          else Ini.DeleteKey(MapType[i].guids,'ParentSubMenu');
       end;
 Ini.UpdateFile;
 ini.Free;
end;

procedure TMapType.LoadMapTypeFromZipFile(AZipFileName: string; pnum : Integer);
var
  MapParams:TMemoryStream;
  AZipFile:TFileStream;
  ParamsTempFile : String;
  iniparams: TMeminifile;
  GUID:TGUID;
  guidstr : string;
  bfloat:string;
  bb:array [1..2048] of char;
  NumRead : integer;
  UnZip:TVCLZip;
  b:double;
begin
  if AZipFileName = '' then begin
    raise Exception.Create('������ ��� ����� � ����������� �����');
  end;
  if not FileExists(AZipFileName) then begin
    raise Exception.Create('���� ' + AZipFileName + ' �� ������');
  end;
  filename := AZipFileName;
  UnZip:=TVCLZip.Create(nil);
  try
    AZipFile:=TFileStream.Create(AZipFileName,fmOpenRead or fmShareDenyNone);
    UnZip.ZipName:=AZipFileName;
    MapParams:=TMemoryStream.Create;
    try
      UnZip.UnZip;
      UnZip.UnZipToStream(MapParams,'params.txt');
      ParamsTempFile := c_GetTempPath+'params.~txt';
      MapParams.SaveToFile(ParamsTempFile);
      iniparams:=TMemIniFile.Create(ParamsTempFile);
    finally
      FreeAndNil(MapParams);
    end;
    try
      guidstr:=iniparams.ReadString('PARAMS','ID',GUIDToString(GUID));
      name:=iniparams.ReadString('PARAMS','name','map#'+inttostr(pnum));
      name:=iniparams.ReadString('PARAMS','name_'+inttostr(GState.Localization),name);


      MapParams:=TMemoryStream.Create;
      try
      if (UnZip.UnZipToStream(MapParams,'info_'+inttostr(GState.Localization)+'.txt')>0)or(UnZip.UnZipToStream(MapParams,'info.txt')>0) then
       begin
        SetLength(info,MapParams.size);
        MapParams.Position:=0;
        MapParams.ReadBuffer(info[1],MapParams.size);
       end;
      finally
        FreeAndNil(MapParams);
      end;

      MapParams:=TMemoryStream.Create;
      try
        UnZip.UnZipToStream(MapParams,'GetUrlScript.txt');
        MapParams.Position:=0;
        repeat
          NumRead:=MapParams.Read(bb,SizeOf(bb));
          GetURLScript:=GetURLScript+copy(bb,1, NumRead);
        until (NumRead = 0);
      finally
        FreeAndNil(MapParams);
      end;
      bmp24:=TBitmap.create;
      MapParams:=TMemoryStream.Create;
      try
        try
          UnZip.UnZipToStream(MapParams,'24.bmp');
          MapParams.Position:=0;
          bmp24.LoadFromStream(MapParams);
        except
          bmp24.Canvas.FillRect(bmp24.Canvas.ClipRect); bmp24.Width:=24; bmp24.Height:=24; bmp24.Canvas.TextOut(7,3,copy(name,1,1))
        end;
      finally
        FreeAndNil(MapParams);
      end;
      bmp18:=TBitmap.create;
      MapParams:=TMemoryStream.Create;
      try
        try
          UnZip.UnZipToStream(MapParams,'18.bmp');
          MapParams.Position:=0;
          bmp18.LoadFromStream(MapParams);
        except
          bmp18.Canvas.FillRect(bmp18.Canvas.ClipRect); bmp18.Width:=18; bmp18.Height:=18; bmp18.Canvas.TextOut(3,2,copy(name,1,1))
        end;
      finally
        FreeAndNil(MapParams);
      end;
      GUIDs:=iniparams.ReadString('PARAMS','GUID',GUIDstr);
      asLayer:=iniparams.ReadBool('PARAMS','asLayer',false);
      URLBase:=iniparams.ReadString('PARAMS','DefURLBase','http://maps.google.com/');
      DefUrlBase:=URLBase;
      TileRect.Left:=iniparams.ReadInteger('PARAMS','TileRLeft',0);
      TileRect.Top:=iniparams.ReadInteger('PARAMS','TileRTop',0);
      TileRect.Right:=iniparams.ReadInteger('PARAMS','TileRRight',0);
      TileRect.Bottom:=iniparams.ReadInteger('PARAMS','TileRBottom',0);
      UseDwn:=iniparams.ReadBool('PARAMS','UseDwn',true);
      Usestick:=iniparams.ReadBool('PARAMS','Usestick',true);
      UseGenPrevious:=iniparams.ReadBool('PARAMS','UseGenPrevious',true);
      Usedel:=iniparams.ReadBool('PARAMS','Usedel',true);
      DelAfterShow:=iniparams.ReadBool('PARAMS','DelAfterShow',false);
      Usesave:=iniparams.ReadBool('PARAMS','Usesave',true);
      UseAntiBan:=iniparams.ReadInteger('PARAMS','UseAntiBan',0);
      CacheType:=iniparams.ReadInteger('PARAMS','CacheType',0);
      DefCacheType:=CacheType;
      Sleep:=iniparams.ReadInteger('PARAMS','Sleep',0);
      DefSleep:=Sleep;
      BanIfLen:=iniparams.ReadInteger('PARAMS','BanIfLen',0);
      CONTENT_TYPE:=iniparams.ReadString('PARAMS','ContentType','image\jpg');
      STATUS_CODE:=iniparams.ReadString('PARAMS','ValidStatusCode','200');
      Ext:=LowerCase(iniparams.ReadString('PARAMS','Ext','.jpg'));
      NameInCache:=iniparams.ReadString('PARAMS','NameInCache','Sat');
      DefNameInCache:=NameInCache;
      projection:=iniparams.ReadInteger('PARAMS','projection',1);
      bfloat:=iniparams.ReadString('PARAMS','sradiusa','6378137');
      radiusa:=str2r(bfloat);
      bfloat:=iniparams.ReadString('PARAMS','sradiusb',FloatToStr(radiusa));
      radiusb:=str2r(bfloat);
      HotKey:=iniparams.ReadInteger('PARAMS','DefHotKey',0);
      DefHotKey:=HotKey;
      ParentSubMenu:=iniparams.ReadString('PARAMS','ParentSubMenu','');
      ParentSubMenu:=iniparams.ReadString('PARAMS','ParentSubMenu_'+inttostr(GState.Localization),ParentSubMenu);
      DefParentSubMenu:=ParentSubMenu;
      separator:=iniparams.ReadBool('PARAMS','separator',false);
      Defseparator:=separator;
      exct:=sqrt(radiusa*radiusa-radiusb*radiusb)/radiusa;
      pos:=iniparams.ReadInteger('PARAMS','pnum',-1);
      case projection of
        1: FCoordConverter := TCoordConverterMercatorOnSphere.Create(radiusa);
        2: FCoordConverter := TCoordConverterMercatorOnEllipsoid.Create(Exct,radiusa,radiusb);
        3: FCoordConverter := TCoordConverterSimpleLonLat.Create(radiusa);
        else raise Exception.Create('��������� ��� �������� ����� ' + IntToStr(projection));
      end;
      try
      FUrlGenerator := TUrlGenerator.Create('procedure Return(Data: string); begin ResultURL := Data; end; ' + GetURLScript, FCoordConverter);
      FUrlGenerator.GetURLBase := URLBase;
      //GetLink(0,0,0);
      except
        on E: Exception do begin
          ShowMessage('������ ������� ����� '+name+' :'+#13#10+ E.Message);
        end;
       else
        ShowMessage('������ ������� ����� '+name+' :'+#13#10+'����������� ������');
      end;
    finally
      FreeAndNil(iniparams);
    end;
  finally
    FreeAndNil(AZipFile);
    FreeAndNil(UnZip);
  end;
end;

function TMapType.GetLink(AXY: TPoint; Azoom: byte): string;
begin
  if (FUrlGenerator = nil) then result:='';
  FCoordConverter.CheckTilePosStrict(AXY, Azoom, True);
  FUrlGenerator.GetURLBase:=URLBase;
  Result:=FUrlGenerator.GenLink(AXY.X, AXY.Y, Azoom);
end;

function TMapType.GetLink(x,y:Integer;Azoom:byte): string;
begin
  Result := Self.GetLink(FCoordConverter.PixelPos2TilePos(Point(x, y), Azoom - 1), Azoom - 1)
end;

function TMapType.GetBasePath: string;
var
  ct:byte;
begin
 if (CacheType=0) then ct:=GState.DefCache
                       else ct:=CacheType;
 result := NameInCache;
 if (length(result)<2)or((result[2]<>'\')and(system.pos(':',result)=0)) then begin
   case ct of
     1:
     begin
       result:=GState.OldCpath_ + Result;
     end;
     2:
     begin
      result:=GState.NewCpath_+Result;
     end;
     3:
     begin
       result:=GState.ESCpath_+Result;
     end;
     4,41:
     begin
      result:=GState.GMTilespath_+Result;
     end;
     5:
     begin
      result:=GState.GECachepath_+Result;
     end;
   end;
 end;
 if (length(result)<2)or((result[2]<>'\')and(system.pos(':',result)=0))
   then result:=GState.ProgramPath+result;
end;

function TMapType.GetTileFileName(AXY: TPoint; Azoom: byte): string;
begin
  Result := Self.GetTileFileName(AXY.X shl 8, AXY.Y shl 8, Azoom + 1);
end;

function TMapType.GetTileFileName(x, y: Integer; Azoom: byte): string;
function full(int,z:integer):string;
var s,s1:string;
    i:byte;
begin
 result:='';
 s:=inttostr(int);
 s1:=inttostr(zoom[z] div 256);
 for i:=length(s) to length(s1)-1 do result:=result+'0';
 result:=result+s;
end;
var os,prer:TPoint;
    i,ct:byte;
    sbuf,name:String;
begin

 if (CacheType=0) then ct:=GState.DefCache
                       else ct:=CacheType;
 if x>=0 then x:=x mod zoom[Azoom]
         else x:=zoom[Azoom]+(x mod zoom[Azoom]);
 Result := GetBasePath;
 case ct of
 1:
 begin
   sbuf:=Format('%.*d', [2, Azoom]);
   result:=result+'\'+sbuf+'\t';
   os.X:=zoom[Azoom]shr 1;
   os.Y:=zoom[Azoom]shr 1;
   prer:=os;
   for i:=2 to Azoom do
    begin
    prer.X:=prer.X shr 1;
    prer.Y:=prer.Y shr 1;
    if x<os.X
     then begin
           os.X:=os.X-prer.X;
           if y<os.y then begin
                            os.Y:=os.Y-prer.Y;
                            result:=result+'q';
                           end
                      else begin
                            os.Y:=os.Y+prer.Y;
                            result:=result+'t';
                           end;
          end
     else begin
           os.X:=os.X+prer.X;
           if y<os.y then begin
                           os.Y:=os.Y-prer.Y;
                           result:=result+'r';
                          end
                     else begin
                           os.Y:=os.Y+prer.Y;
                           result:=result+'s';
                          end;
         end;
    end;
  result:=result + ext;
 end;
 2:
 begin
  x:=x shr 8;
  y:=y shr 8;
  result:=result+format('\z%d\%d\x%d\%d\y%d',[Azoom,x shr 10,x,y shr 10,y])+ext;
 end;
 3:
 begin
   sbuf:=Format('%.*d', [2, Azoom]);
   name:=sbuf+'-'+full(x shr 8,Azoom)+'-'+full(y shr 8,Azoom);
   if Azoom<7
    then result:=result+'\'+sbuf+'\'
    else if Azoom<11
          then result:=result+'\'+sbuf+'\'+Chr(59+Azoom)+
                       full((x shr 8)shr 5,Azoom-5)+full((y shr 8)shr 5,Azoom-5)+'\'
          else result:=result+'\'+'10'+'-'+full((x shr (Azoom-10))shr 8,10)+'-'+
                       full((y shr (Azoom-10))shr 8,10)+'\'+sbuf+'\'+Chr(59+Azoom)+
                       full((x shr 8)shr 5,Azoom-5)+full((y shr 8)shr 5,Azoom-5)+'\';
   result:=result+name+ext;
 end;
 4,41:
 begin
  x:=x shr 8;
  y:=y shr 8;
  if ct=4 then result:=result+format('\z%d\%d\%d'+ext,[Azoom-1,Y,X])
          else result:=result+format('\z%d\%d_%d'+ext,[Azoom-1,Y,X]);
 end;
 5:
 begin
  result:=result+'\dbCache.dat';
 end;
 end;
end;

function TMapType.TileExists(AXY: TPoint; Azoom: byte): Boolean;
var
  VPath: String;
begin
  if ((CacheType=0)and(GState.DefCache=5))or(CacheType=5) then begin
    result:=GETileExists(GetBasePath+'\dbCache.dat.index', AXY.X, AXY.Y, Azoom + 1,self);
  end else begin
    VPath := GetTileFileName(AXY, Azoom);
    Result := Fileexists(VPath);
  end;
end;

function TMapType.TileExists(x, y: Integer; Azoom: byte): Boolean;
begin
  Result := Self.TileExists(FCoordConverter.PixelPos2TilePos(Point(x, y), Azoom - 1), Azoom - 1);
end;

function GetFileSize(namefile: string): Integer;
var
  InfoFile: TSearchRec;
begin
  if FindFirst(namefile, faAnyFile, InfoFile) <> 0 then begin
    Result := -1;
  end else begin
    Result := InfoFile.Size;
  end;
  SysUtils.FindClose(InfoFile);
end;

function LoadGIF(FileName: string; Btm: TBitmap32): boolean;
var gif:TGIFImage;
    p:PColor32;
    c:TColor32;
    h,w:integer;
begin
 try
   result:=true;
   gif:=TGIFImage.Create;
   gif.LoadFromFile(FileName);
   Btm.DrawMode:=dmOpaque;
   If (gif.isTransparent) then begin
     c:=Color32(gif.Images[0].GraphicControlExtension.TransparentColor);
     gif.Images[0].GraphicControlExtension.Transparent:=false;
     Btm.Assign(gif);
     p := @Btm.Bits[0];
     for H:=0 to Btm.Height-1 do
      for W:=0 to Btm.Width-1 do
       begin
        if p^=c then p^:=$00000000;
        inc(p);
       end;
   end else begin
     Btm.Assign(gif);
   end;
   gif.Free;
 except
   result:=false;
 end;
end;

function LoadPNG(FileName: string; Btm: TBitmap32): boolean;
var png:TPNGObject;
begin
 try
   result:=true;
   png:=TPNGObject.Create;
   png.LoadFromFile(FileName);
   Btm.DrawMode:=dmOpaque;
   PNGintoBitmap32(btm,png);
   png.Free;
 except
   result:=false;
 end;
end;

function LoadJPG32(FileName: string; Btm: TBitmap32): boolean;
  procedure RGBA2BGRA2(pData : Pointer; Width, Height : Integer);
  var W, H : Integer;
      p : PIntegerArray;
  begin
    p := PIntegerArray(pData);
    for H := 0 to Height-1 do begin
      for W := 0 to Width-1 do begin
        p^[W]:=(p^[W] and $FF000000)or((p^[W] and $00FF0000) shr 16)or(p^[W] and $0000FF00)or((p^[W] and $000000FF) shl 16);
      end;
      inc(p,width)
    end;
  end;
var
  iWidth, iHeight, iNChannels : Integer;
  iStatus : Integer;
  jcprops : TJPEG_CORE_PROPERTIES;
begin
 try
    result:=true;
    iStatus := ijlInit(@jcprops);
    if iStatus < 0 then
     begin
      result:=false;
      exit;
     end;

    jcprops.JPGFile := PChar(FileName);
    iStatus := ijlRead(@jcprops,IJL_JFILE_READPARAMS);
    if iStatus < 0 then
     begin
      result:=false;
      exit;
     end;
    iWidth := jcprops.JPGWidth;
    iHeight := jcprops.JPGHeight;
    iNChannels := 4;
    Btm.SetSize(iWidth,iHeight);
    jcprops.DIBWidth := iWidth;
    jcprops.DIBHeight := iHeight;
    jcprops.DIBChannels := iNChannels;
    jcprops.DIBColor := IJL_RGBA_FPX;
    jcprops.DIBPadBytes := ((((iWidth*iNChannels)+3) div 4)*4)-(iWidth*iNChannels);
    jcprops.DIBBytes := PByte(Btm.Bits);

    if (jcprops.JPGChannels = 3) then
      jcprops.JPGColor := IJL_YCBCR
    else if (jcprops.JPGChannels = 4) then
      jcprops.JPGColor := IJL_YCBCRA_FPX
    else if (jcprops.JPGChannels = 1) then
      jcprops.JPGColor := IJL_G
    else
    begin
      jcprops.DIBColor := TIJL_COLOR (IJL_OTHER);
      jcprops.JPGColor := TIJL_COLOR (IJL_OTHER);
    end;
    iStatus := ijlRead(@jcprops,IJL_JFILE_READWHOLEIMAGE);
    if iStatus < 0 then
     begin
      result:=false;
      exit;
     end;
    RGBA2BGRA2(jcprops.DIBBytes,iWidth,iHeight);
    ijlFree(@jcprops);
  except
    on E: Exception do
    begin
      result:=false;
      ijlFree(@jcprops);
    end;
  end;
end;

function TMapType.LoadTileFromPreZ(spr:TBitmap32;x,y:integer;Azoom:byte; caching:boolean):boolean;
var i,c_x,c_y,dZ:integer;
    bmp:TBitmap32;
    VTileExists: Boolean;
    key:string;
begin
 result:=false;
 if (not(GState.UsePrevZoom) and (asLayer=false)) or
    (not(GState.UsePrevZoomLayer) and (asLayer=true)) then begin
   spr.Clear(SetAlpha(Color32(clSilver),0));
   exit;
 end;
 VTileExists := false;
 for i:=(Azoom-1) downto 1 do
  begin
   dZ:=(Azoom-i);
   if TileExists(x shr dZ,y shr dZ,i) then begin
    VTileExists := true;
    break;
   end;
  end;
 if not(VTileExists)or(dZ>8) then
  begin
   spr.Clear(SetAlpha(Color32(clSilver),0));
   exit;
  end;
 key:=guids+'-'+inttostr(x shr 8)+'-'+inttostr(y shr 8)+'-'+inttostr(Azoom);
 if (not caching)or(not GState.MainFileCache.TryLoadFileFromCache(TBitmap32(spr), key)) then begin
   bmp:=TBitmap32.Create;
   if not(LoadTile(bmp,x shr dZ,y shr dZ, Azoom - dZ,true))then
    begin
     spr.Clear(SetAlpha(Color32(clSilver),0));
     bmp.Free;
     exit;
    end;
   bmp.Resampler := CreateResampler(GState.Resampling);
   c_x:=((x-(x mod 256))shr dZ)mod 256;
   c_y:=((y-(y mod 256))shr dZ)mod 256;
   try
    spr.Draw(bounds(-c_x shl dZ,-c_y shl dZ,256 shl dZ,256 shl dZ),bounds(0,0,256,256),bmp);
    GState.MainFileCache.AddTileToCache(TBitmap32(spr), key );
   except
   end;
   bmp.Free;
 end;
 result:=true;
end;

function TMapType.LoadTile(btm: Tobject; x,y:longint;Azoom:byte;
  caching: boolean): boolean;
var path: string;
begin
  path := GetTileFileName(x, y, Azoom);
  if ((CacheType=0)and(GState.DefCache=5))or(CacheType=5) then begin
    if (not caching)or(not GState.MainFileCache.TryLoadFileFromCache(TBitmap32(btm), guids+'-'+inttostr(x shr 8)+'-'+inttostr(y shr 8)+'-'+inttostr(Azoom))) then begin
      result:=GetGETile(TBitmap32(btm),GetBasePath+'\dbCache.dat',x shr 8,y shr 8,Azoom, Self);
      if ((result)and(caching)) then GState.MainFileCache.AddTileToCache(TBitmap32(btm), guids+'-'+inttostr(x shr 8)+'-'+inttostr(y shr 8)+'-'+inttostr(Azoom) );
    end else begin
      result:=true;
    end;
  end else
  result:= LoadFile(btm, path, caching);
end;

function TMapType.DeleteTile(AXY: TPoint; Azoom: byte): Boolean;
var
  VPath: string;
begin
  try
    VPath := GetTileFileName(AXY, Azoom);
    result := DeleteFile(PChar(VPath));
  except
    Result := false;
  end;
end;

function TMapType.DeleteTile(x, y: Integer; Azoom: byte): Boolean;
begin
  Result := Self.DeleteTile(x shr 8, y shr 8, Azoom - 1);
end;

function TMapType.LoadFile(btm: Tobject; APath: string; caching:boolean): boolean;
begin
  Result := false;
  if GetFileSize(Apath)=0 then begin
    exit;
  end;
  try
    if (btm is TBitmap32) then begin
      if (not caching)or(not GState.MainFileCache.TryLoadFileFromCache(TBitmap32(btm), Apath)) then begin
        if ExtractFileExt(Apath)='.jpg' then begin
          if not(LoadJPG32(Apath,TBitmap32(btm))) then begin
            result:=false;
            exit;
          end;
        end else
        if ExtractFileExt(Apath)='.png' then begin
          if not(LoadPNG(Apath,TBitmap32(btm))) then begin
            result:=false;
            exit;
          end;
        end else
        if ExtractFileExt(Apath)='.gif' then begin
          if not(LoadGif(Apath,TBitmap32(btm))) then begin
            result:=false;
            exit;
          end;
        end else begin
          TBitmap32(btm).LoadFromFile(Apath);
        end;
        result:=true;
        if (caching) then GState.MainFileCache.AddTileToCache(TBitmap32(btm), Apath);
      end
    end else begin
      if (btm is TPicture) then
        TPicture(btm).LoadFromFile(Apath)
      else if (btm is TJPEGimage) then
        TJPEGimage(btm).LoadFromFile(Apath)
      else if (btm is TPNGObject) then begin
       if not(caching) then begin
         TPNGObject(btm).LoadFromFile(Apath)
       end else begin
         if not GState.MainFileCache.TryLoadFileFromCache(btm, Apath) then begin
          TPNGObject(btm).LoadFromFile(Apath);
          GState.MainFileCache.AddTileToCache(btm, Apath);
         end;
       end
      end
      else if (btm is TKML) then
        TKML(btm).LoadFromFile(Apath)
      else if (btm is TGraphic) then
        TGraphic(btm).LoadFromFile(Apath);
    end;
    result:=true;
  except
  end;
end;

function TMapType.TileNotExistsOnServer(AXY: TPoint; Azoom: byte): Boolean;
var
  VPath: String;
begin
  VPath := GetTileFileName(AXY, Azoom);
  Result := Fileexists(ChangeFileExt(VPath, '.tne'));
end;

function TMapType.TileNotExistsOnServer(x, y: Integer;
  Azoom: byte): Boolean;
begin
  Result := Self.TileNotExistsOnServer(x shr 8, y shr 8, Azoom - 1);
end;

procedure TMapType.CreateDirIfNotExists(APath:string);
var i:integer;
begin
 i := LastDelimiter('\', Apath);
 Apath:=copy(Apath, 1, i);
 if not(DirectoryExists(Apath)) then ForceDirectories(Apath);
end;

procedure TMapType.SaveTileDownload(AXY: TPoint; Azoom: byte;
  ATileStream: TCustomMemoryStream; ty: string);
begin
  Self.SaveTileDownload(AXY.X shl 8, AXY.Y shl 8, Azoom + 1, ATileStream, ty);
end;


procedure TMapType.SaveTileDownload(x, y: Integer; Azoom: byte;
  ATileStream: TCustomMemoryStream; ty: string);
var
  VPath: String;
    jpg:TJPEGImage;
    btm:TBitmap;
    png:TBitmap32;
    btmSrc:TBitmap32;
    btmDest:TBitmap32;
    UnZip:TVCLUnZip;
begin
  VPath := GetTileFileName(x, y, Azoom);

  CreateDirIfNotExists(VPath);
  DeleteFile(copy(Vpath,1,length(Vpath)-3)+'tne');
  if ((copy(ty,1,8)='text/xml')or(ty='application/vnd.google-earth.kmz'))and(ext='.kml')then begin
    try
      UnZip:=TVCLUnZip.Create(Fmain);
      UnZip.ArchiveStream:=TMemoryStream.Create;
      ATileStream.SaveToStream(UnZip.ArchiveStream);
      UnZip.ReadZip;
      ATileStream.Position:=0;
      UnZip.UnZipToStream(ATileStream,UnZip.Filename[0]);
      UnZip.Free;
      SaveTileInCache(ATileStream,Vpath);
      ban_pg_ld:=true;
    except
      try
        SaveTileInCache(ATileStream,Vpath);
      except
      end;
    end;
  end;

  SaveTileInCache(ATileStream,Vpath);
  if (TileRect.Left<>0)or(TileRect.Top<>0)or
    (TileRect.Right<>0)or(TileRect.Bottom<>0) then begin
    btmsrc:=TBitmap32.Create;
    btmDest:=TBitmap32.Create;
    try
      btmSrc.Resampler:=TLinearResampler.Create;
      if LoadFile(btmsrc,Vpath,false) then begin
        btmDest.SetSize(256,256);
        btmdest.Draw(bounds(0,0,256,256),TileRect,btmSrc);
        SaveTileInCache(btmDest,Vpath);
      end;
    except
    end;
    btmSrc.Free;
    btmDest.Free;
  end;

  ban_pg_ld:=true;
  if (ty='image/png')and(ext='.jpg') then begin
    btm:=TBitmap.Create;
    png:=TBitmap32.Create;
    jpg:=TJPEGImage.Create;
    RenameFile(Vpath,copy(Vpath,1,length(Vpath)-4)+'.png');
    if LoadFile(png,copy(Vpath,1,length(Vpath)-4)+'.png',false) then begin
      btm.Assign(png);
      jpg.Assign(btm);
      SaveTileInCache(jpg,Vpath);
      DeleteFile(copy(Vpath,1,length(Vpath)-4)+'.png');
      btm.Free;
      jpg.Free;
      png.Free;
    end;
  end;
  GState.MainFileCache.DeleteFileFromCache(Vpath);
end;

procedure TMapType.SaveTileInCache(btm:TObject;path:string);
var
    Jpg_ex:TJpegImage;
    png_ex:TPNGObject;
    Gif_ex:TGIFImage;
    btm_ex:TBitmap;
begin
 if (btm is TBitmap32) then
  begin
   btm_ex:=TBitmap.Create;
   btm_ex.Assign(btm as TBitmap32);
   if UpperCase(ExtractFileExt(path))='.JPG' then
    begin
     Jpg_ex:=TJpegImage.Create;
     Jpg_ex.CompressionQuality:=85;
     Jpg_ex.Assign(btm_ex);
     Jpg_ex.SaveToFile(path);
     Jpg_ex.Free;
    end;
   if UpperCase(ExtractFileExt(path))='.GIF' then
    begin
     Gif_ex:=TGifImage.Create;
     Gif_ex.Assign(btm_ex);
     Gif_ex.SaveToFile(path);
     Gif_ex.Free;
    end;
   if UpperCase(ExtractFileExt(path))='.PNG' then
    begin
     PNG_ex:=TPNGObject.Create;
     PNG_ex.Assign(btm_ex);
     PNG_ex.SaveToFile(path);
     PNG_ex.Free;
    end;
   if UpperCase(ExtractFileExt(path))='.BMP' then btm_ex.SaveToFile(path);
   btm_ex.Free;
  end;
 if (btm is TJPEGimage) then TJPEGimage(btm).SaveToFile(path) else
 if (btm is TPNGObject) then TPNGObject(btm).SaveToFile(path) else
 if (btm is TMemoryStream) then TMemoryStream(btm).SaveToFile(path) else
 if (btm is TPicture) then TPicture(btm).SaveToFile(path);
end;


function TMapType.TileLoadDate(x, y: Integer; Azoom: byte): TDateTime;
var
  VPath: String;
begin
  VPath := GetTileFileName(x, y, Azoom);
  Result := FileDateToDateTime(FileAge(VPath));
end;

function TMapType.TileSize(x, y: Integer; Azoom: byte): integer;
var
  VPath: String;
begin
  VPath := GetTileFileName(x, y, Azoom);
  Result := GetFileSize(VPath);
end;

procedure TMapType.SaveTileNotExists(x, y: Integer; Azoom: byte);
var
  VPath: String;
  F:textfile;
begin
  VPath := GetTileFileName(x, y, Azoom);
 if not(FileExists(copy(Vpath,1,length(Vpath)-3)+'tne')) then
  begin
   CreateDirIfNotExists(copy(Vpath,1,length(Vpath)-3)+'tne');
   AssignFile(f,copy(Vpath,1,length(Vpath)-3)+'tne');
   Rewrite(F);
   Writeln(f,DateTimeToStr(now));
   CloseFile(f);
  end;
end;

procedure TMapType.SaveTileSimple(x, y: Integer; Azoom: byte;
  btm:TObject);
var
  VPath: String;
begin
  VPath := GetTileFileName(x, y, Azoom);
  CreateDirIfNotExists(VPath);
  DeleteFile(copy(Vpath,1,length(Vpath)-3)+'tne');
  SaveTileInCache(btm,Vpath);
end;

function TMapType.TileExportToFile(x, y: Integer; Azoom: byte;
  AFileName: string; OverWrite: boolean): boolean;
var
  VPath: String;
begin
  VPath := GetTileFileName(x, y, Azoom);
  CreateDirIfNotExists(AFileName);
  Result := CopyFile(PChar(VPath), PChar(AFileName), not OverWrite);
end;

function TMapType.LoadFillingMap(btm: TBitmap32; x, y: Integer; Azoom,
  ASourceZoom: byte; IsStop: PBoolean): boolean;
begin
  //TODO: ����� ���� ������� ���������� ���� �������
end;

function TMapType.GetShortFolderName: string;
begin
  Result := ExtractFileName(ExtractFileDir(IncludeTrailingPathDelimiter(NameInCache)));
end;


function TMapType.GetCoordConverter: ICoordConverter;
begin
 if Self=nil
  then Result:= nil
  else Result:= FCoordConverter;
end;

function TMapType.CheckIsBan(AXY: TPoint; AZoom: byte;
  StatusCode: Cardinal; ty: string; fileBuf: TMemoryStream): Boolean;
begin
  Result := false;
  if (ty <> Content_type)
    and(fileBuf.Size <> 0)
    and(BanIfLen <> 0)
    and(fileBuf.Size < (BanIfLen + 50))
    and(fileBuf.Size >(BanIfLen-50)) then
  begin
    result := true;
  end;
end;

function TMapType.IncDownloadedAndCheckAntiBan: Boolean;
var
  cnt: Integer;
begin
  cnt := InterlockedIncrement(FDownloadTilesCount);
  if (UseAntiBan > 1) then begin
    Result := (cnt mod UseAntiBan) = 0;
  end else begin
    Result := (UseAntiBan > 0) and  (cnt = 1);
  end;
end;

procedure TMapType.addDwnforban;
begin
  if (UseAntiBan>0) then begin
    Fmain.WebBrowser1.Navigate('http://maps.google.com/?ie=UTF8&ll='+inttostr(random(100)-50)+','+inttostr(random(300)-150)+'&spn=1,1&t=k&z=8');
  end;
end;

procedure TMapType.ExecOnBan(ALastUrl: string);
begin
  if ban_pg_ld then begin
    Fmain.ShowCaptcha(ALastUrl);
    ban_pg_ld:=false;
  end;
end;

constructor TMapType.Create;
begin
  FInitDownloadCS := TCriticalSection.Create;
end;

destructor TMapType.Destroy;
begin
  FreeAndNil(FInitDownloadCS);
  inherited;
end;

function TMapType.GetDownloader: TTileDownloaderBase;
begin
  if FDownloader = nil then begin
    FInitDownloadCS.Acquire;
    try
      if FDownloader = nil then begin
        FDownloader := TTileDownloaderBase.Create(CONTENT_TYPE, 1, GState.InetConnect);
        FDownloader.SleepOnResetConnection := Sleep;
      end;
    finally
      FInitDownloadCS.Release;
    end;
  end;
  Result := FDownloader;
end;

function TMapType.DownloadTile(AXY: TPoint; AZoom: byte;
  ACheckTileSize: Boolean; AOldTileSize: Integer;
  out AUrl: string; out AContentType: string;
  fileBuf: TMemoryStream): TDownloadTileResult;
var
  StatusCode: Cardinal;
begin
  AUrl := GetLink(AXY.X, AXY.Y, AZoom);
  Result := GetDownloader.DownloadTile(AUrl, ACheckTileSize, AOldTileSize, fileBuf, StatusCode, AContentType);
  if CheckIsBan(AXY, AZoom, StatusCode, AContentType, fileBuf) then begin
    result := dtrBanError;
  end;
end;



end.
