unit classMe;

interface

uses
  System.SysUtils,
  classes,
  zglSpriteEngine,
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_keyboard,
  zgl_mouse,
  zgl_render_2d,
  zgl_fx,
  zgl_textures,
  zgl_textures_png,
  zgl_textures_jpg,
  zgl_sprite_2d,
  zgl_primitives_2d,
  zgl_particles_2d,
  zgl_collision_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log,
  zgl_sound,
  unitConstants;

type
  (*
    This class represents the a Tree... me... I AM TREE!!!



  *)

  TMyItem = class;

  TMe = class(TObject)
  protected
    fLevel : integer;

    fSegments : array[1..6] of integer;
    fItems : array[1..6,1..2] of TMyItem;
    fCurrentItems : integer;
    fMaxItems : integer;
    fItemList : TList;
    fActionItem : TMyItem;
    fSeason : integer;

    fCleanup : TList;

    fResourceTime : integer;

    fTreeState : integer; // 0 = dead, 1 = brown, 2 = yellow, 3 = green

    fFoodLevel : integer;
    fWaterLevel : integer;

    fCenterX : integer;
    fYOffset : integer;

    fRequiredFoodLevel : integer;
    fRequiredWaterLevel : integer;

    procedure setLevel(newLevel:integer);
    function getFull:boolean;
    procedure resetItems;

    function itemUnderMouse:TMyItem;
    procedure cleanup;
    procedure processResources;


  public
    constructor create(centerX,yOffset:integer);
    destructor Destroy; override;

    procedure draw;
    procedure timer;

    function levelUp:boolean;
    procedure reset;

    procedure actionEnded;

    function flyingCritterHit(x,y,w,h:single):TMyItem;

    function getRandomCritterY:integer;

    procedure addFlower;

    procedure addWater;
    procedure addFood;

    function hasItems:boolean;

    procedure itemRemoved(anItem:TMyItem);

    procedure setSeason(aSeason:integer);

    property full:boolean read getFull;
    property centerX:integer read fCenterX;

    property itemCount:integer read fCurrentItems;

    property level:integer read fLevel;
  end;

  TMyItem = class(TObject)
  protected
    fX : integer;
    fY : integer;
    fCenterY : integer;
    fCenterX : integer;
    fTheTree : TMe;

    fSegment : integer;
    fWhich : integer;

    fState : integer;
    fStateTime : integer;
    fSize : single;
    fSizeChange : single;

    fNerfed : boolean;
    fSuccess : boolean;

    fEmitter : zglPPEmitter2D;

    procedure clearEmitter;
    procedure emit(anEmitter:zglPEmitter2d;itemSize:integer);

    procedure getBoundingBox(var r:zglTRect); virtual;

    //------------------------------------------------------------------------------

    procedure setState(newState:integer); virtual; abstract;
    procedure stateTimeExpired; virtual; abstract;
    function getIdle:boolean; virtual; abstract;
    function getActioned:boolean; virtual; abstract;

    //------------------------------------------------------------------------------

  public
    constructor create(theTree:TMe;x,y:integer;s,w:integer);
    destructor Destroy; override;

    procedure nerf; virtual;
    procedure timer; virtual;

    //------------------------------------------------------------------------------

    procedure action; virtual; abstract;
    procedure success; virtual;
    procedure draw; virtual; abstract;

    function mouseHit(x,y:integer):boolean;
    function collision(x,y,w,h:single):boolean;
    function canSucceed:boolean; virtual;
    function canBeNerfed:boolean; virtual;

    //------------------------------------------------------------------------------

    property wasNerfed:boolean read fNerfed;
    property wasSuccessful:boolean read fSuccess;
    property idle:boolean read getIdle;
    property actioned:boolean read getActioned;

    property x:integer read fX;
    property y:integer read fY;

    property centerX:integer read fCenterX;
    property centerY:integer read fCenterY;

    property segment:integer read fSegment;
    property which:integer read fWhich;
  end;


(*



                                    *
                             *     ***
                      *     ***     .
             *       ***     .     RND
   *        ***       .     RND     -     <- Level -4 rows
  ***        .       RND    RND    RND
   .         |        |      |      |

                             ^Cannot have the same random item


   1         2        3      4      5+


*)


implementation

uses
  classMyApple,
  classMyFlower,
  unitGlobalResources;

function TMe.hasItems:boolean;
begin
  result:=(fCurrentItems>0);
end;

function TMe.flyingCritterHit(x,y,w,h:single):TMyItem;
var
  loop : integer;
begin
  result:=nil;
  for loop:=0 to fItemList.count-1 do
  begin
    if (TMyItem(fItemList[loop]).collision(x,y,w,h)) then
    begin
      result:=TMyItem(fItemList[loop]);
      break;
    end;
  end;
end;

procedure TMe.itemRemoved(anItem:TMyItem);
var
  idxPos : integer;
begin
  idxPos:=fItemList.indexOf(anItem);
  if (idxPos>=0) then
  begin
    fItemList.delete(idxPos);
  end;
  fItems[anItem.segment,anItem.which]:=nil;

  fCleanup.add(anItem);

  dec(fCurrentItems);
  if (fCurrentItems<0) then
  begin
    fCurrentItems:=0;
  end;
end;

function TMe.getRandomCritterY:integer;
var
  anItem : TMyItem;
  idx : integer;
begin
  result:=-1;

  if (fItemList.count>0) then
  begin
    repeat
      idx:=random(fItemList.count);
    until (idx>=0) and (idx<fItemList.count);

    anItem:=TMyItem(fItemList[idx]);
    result:=anItem.centerY;
  end;
end;

procedure TMe.setSeason(aSeason:integer);
var
  anItem : TMyItem;
  segment : integer;
  which : integer;
  aNewItem : TMyItem;
begin
  if (aSeason<>fSeason) then
  begin
    fSeason:=aSeason;

    if (fSeason=SEASON_SPRING) then
    begin
      resetItems;
    end
    else
    begin
      if (fSeason=SEASON_SUMMER) then
      begin
        fItemList.clear;

        for segment:=1 to fLevel do
        begin
          for which:=1 to MAX_APPLES_PER_SEGMENT do
          begin
            if (fItems[segment,which]<>nil) then
            begin
              anItem:=TMyItem(fItems[segment,which]);

              if (anItem.wasSuccessful) then
              begin
                aNewItem:=TMyApple.create(self,anItem.x,anItem.y,segment,which);
                fItems[segment,which]:=aNewItem;
                fItemList.add(aNewItem);
              end
              else
              begin
                fItems[segment,which]:=nil;
                dec(fCurrentItems);
              end;

              anItem.free;
            end;
          end;
        end;
      end
      else
      begin
        if (fSeason=SEASON_AUTUMN) then
        begin
        end;
      end;
    end;
  end;
end;

procedure TMe.processResources;
var
  foodPercent : single;
  waterPercent : single;
  minPercent : single;
  resourceNeeded : integer;
  segment,which : integer;
begin
  foodPercent:=(fFoodLevel/fRequiredFoodLevel)*100;
  waterPercent:=(fWaterLevel/fRequiredWaterLevel)*100;

  minPercent:=foodPercent;
  if (waterPercent<minPercent) then
  begin
    minPercent:=waterPercent;
  end;

  if (minPercent<TREE_RESOURCE_PERCENT_BAD) then
  begin
    fTreeState:=TREE_STATE_DEAD;
  end
  else
  begin
    if (minPercent>=TREE_RESOURCE_PERCENT_BAD) and (minPercent<TREE_RESOURCE_PERCENT_OK) then
    begin
      fTreeState:=TREE_STATE_BAD;
    end
    else
    begin
      if (minPercent>=TREE_RESOURCE_PERCENT_OK) and (minPercent<TREE_RESOURCE_PERCENT_GOOD) then
      begin
        fTreeState:=TREE_STATE_OK;
      end
      else
      begin
        fTreeState:=TREE_STATE_GOOD;
      end;
    end;
  end;

  if (fTreeState<>TREE_STATE_DEAD) then
  begin
    if (fWaterLevel>0) then
    begin
      resourceNeeded:=(WATER_PER_TREE+(WATER_PER_ITEM*fCurrentItems));
      if (fSeason=SEASON_SUMMER) then
      begin
        resourceNeeded:=round(resourceNeeded*SEASON_SUMMER_WATERBOOST);
      end;

      fWaterLevel:=fWaterLevel-resourceNeeded;

      if (fWaterLevel<0) then
      begin
        fWaterLevel:=0;
      end;
    end;
    if (fFoodLevel>0) then
    begin
      resourceNeeded:=(FOOD_PER_TREE+(FOOD_PER_ITEM*fCurrentItems));

      if (fSeason=SEASON_SPRING) then
      begin
        resourceNeeded:=round(resourceNeeded*SEASON_SPRING_FOODBOOST);
      end;
      if (fSeason=SEASON_SUMMER) then
      begin
        resourceNeeded:=round(resourceNeeded*SEASON_SUMMER_FOODBOOST);
      end;

      fFoodLevel:=fFoodLevel-resourceNeeded;

      if (fFoodLevel<0) then
      begin
        fFoodLevel:=0;
      end;
    end;
  end;

  if (fTreeState in [TREE_STATE_DEAD,TREE_STATE_BAD]) then
  begin
    if (fItemList.count>0) then
    begin
      segment:=1+random(fLevel);
      which:=1+random(MAX_APPLES_PER_SEGMENT);

      if (fItems[segment,which]<>nil) then
      begin
        fItems[segment,which].nerf;
      end;
    end;
  end
  else
  begin
    if (fTreeState in [TREE_STATE_GOOD]) and (fSeason=SEASON_SPRING) then
    begin
      if not full then
      begin
        if (random(1000)<=SPRINGTIME_ADD_FLOWER_CHANCE) then
        begin
          addFlower;
        end;
      end;
    end;
  end;
end;

constructor TMe.create(centerX,yOffset:integer);
begin
  inherited create;

  fCenterX:=centerX;
  fYOffset:=yOffset;
  fSeason:=SEASON_SPRING;
  fItemList:=TList.create;
  fActionItem:=nil;
  fCleanup:=TList.create;

  fResourceTime:=TREE_RESOURCE_PROCESSING_FRAMES;

  reset;
end;

procedure TMe.addWater;
begin
  fWaterLevel:=fWaterLevel+WATER_ADD_BASE+random(WATER_ADD_RANDOM_MAX);
end;

procedure TMe.addFood;
begin
  fFoodLevel:=fFoodLevel+FOOD_ADD_BASE+random(FOOD_ADD_RANDOM_MAX);
end;

procedure TMe.cleanup;
begin
  while (fCleanup.count>0) do
  begin
    TObject(fCLeanup[0]).free;
    fCleanup.delete(0);
  end;
end;

destructor TMe.destroy;
begin
  while (fItemList.count>0) do
  begin
    TObject(fItemList[0]).free;
    fItemList.delete(0);
  end;

  fItemList.free;

  cleanup;

  fCleanup.free;

  inherited;
end;

function TMe.getFull:boolean;
begin
  result:=(fCurrentItems>=fMaxItems);
end;

procedure TMe.draw;
var
  loop : integer;
  sx : integer;
  sy : integer;
  foodText : string;
  waterText : string;
  textY : single;
begin
  sx:=fCenterX-HALF_SPRITE_SIZE;
  sy:=TREE_BASE-SPRITE_SIZE+fYOffset;

  for loop:=1 to TREE_MAX_LEVEL do
  begin
    if (fSegments[loop]<>0) then
    begin
      asprite2d_Draw( texTree,sx,sy,SPRITE_SIZE,SPRITE_SIZE,0,TREE_LEAVES_SPRITES[fSegments[loop],fTreeState]);
      asprite2d_Draw( texTree,sx,sy,SPRITE_SIZE,SPRITE_SIZE,0,TREE_WOOD_SPRITES[fSegments[loop]]);
    end;

    sy:=sy-SPRITE_SIZE;
  end;

  for loop:=0 to fItemList.count-1 do
  begin
    TMyItem(fItemList[loop]).draw;
  end;

  foodText:=format('F:%d',[fFoodLevel]);
  waterText:=format('W:%d',[fWaterLevel]);

  textY:=TREE_BASE+fYOffset-(fLevel*SPRITE_SIZE)-text_GetHeight(fntScore,text_getWidth(fntScore,UTF8String(foodText)),UTF8String(foodText))-2;

  if (fFoodLevel>fRequiredFoodLevel) then
  begin
    fx2d_SetVCA( $00FF00, $007F00, $007F00, $00FF00, 255, 255, 255, 255 );
  end
  else
  begin
    fx2d_SetVCA( $FF0000, $7f0000, $7f0000, $FF0000, 255, 255, 255, 255 );
  end;

  text_Draw(fntScore,fCenterX,textY,UTF8String(foodText),TEXT_FX_VCA or TEXT_HALIGN_CENTER);

  if (fWaterLevel>fRequiredWaterLevel) then
  begin
    fx2d_SetVCA( $00FF00, $007F00, $007F00, $00FF00, 255, 255, 255, 255 );
  end
  else
  begin
    fx2d_SetVCA( $FF0000, $7F0000, $7F0000, $ff0000, 255, 255, 255, 255 );
  end;

  textY:=textY-text_GetHeight(fntScore,text_getWidth(fntScore,UTF8String(foodText)),UTF8String(foodText));

  text_Draw(fntScore,fCenterX,textY,UTF8String(waterText),TEXT_FX_VCA or TEXT_HALIGN_CENTER);
end;

function TMe.itemUnderMouse:TMyItem;
var
  loop : integer;
  anItem : TMyItem;
begin
  result:=nil;

  for loop:=0 to fItemList.count-1 do
  begin
    anItem:=fItemList[loop];

    if (anItem.mouseHit(mouse_x,mouse_y)) then
    begin
      result:=anItem;
      break;
    end;
  end;

end;

procedure TMe.timer;
var
  loop : integer;
  anItem : TMyItem;
begin
  for loop:=0 to fItemList.count-1 do
  begin
    TMyItem(fItemList[loop]).timer;
  end;

  if (mouse_click(M_BLEFT)) then
  begin
    if (fActionItem=nil) then
    begin
      anItem:=itemUnderMouse;

      if (anItem<>nil) then
      begin
        fActionItem:=anItem;
        fActionItem.action;
      end;
    end;
  end;

  dec(fResourceTime);
  if (fResourceTime=0) then
  begin
    processResources;
    fResourceTime:=TREE_RESOURCE_PROCESSING_FRAMES;
  end;

  cleanup;
end;

procedure TMe.actionEnded;
begin
  fActionItem:=nil;
end;

function TMe.levelUp:boolean;
begin
  if (fLevel<TREE_MAX_LEVEL) then
  begin
    setLevel(fLevel+1);
    result:=true;
  end
  else
  begin
    result:=false;
  end;
end;

procedure TMe.resetItems;
var
  loop : integer;
  itemLoop : integer;
begin
  for loop:=1 to TREE_MAX_LEVEL do
  begin
    for itemLoop:=1 to MAX_APPLES_PER_SEGMENT do
    begin
      if (assigned(fItems[loop,itemLoop])) then
      begin
        fItems[loop,itemLoop].free;
      end;

      fItems[loop,itemLoop]:=nil;
    end;
  end;

  fItemList.clear;
  fCurrentItems:=0;
end;

procedure TMe.reset;
begin
  fLevel:=0;
  fTreeState:=TREE_STATE_DEAD;
  fCurrentItems:=0;
  fMaxItems:=0;
  fFoodLevel:=0;
  fWaterLevel:=0;

  setLevel(1);
end;

procedure TMe.addFlower;
var
  segment : integer;
  which : integer;
  placed : boolean;
begin
  // Note... this is bad... call this with a full tree and it will end with an infiniloop!!!

  if (fTreeState=TREE_STATE_GOOD) then
  begin
    placed:=false;
    repeat
      segment:=random(fLevel)+1;

      if (APPLES_PER_SEGMENT[fSegments[segment]]>0) then
      begin
        repeat
          which:=1+random(APPLES_PER_SEGMENT[fSegments[segment]]);
        until (which<=APPLES_PER_SEGMENT[fSegments[segment]]);

        if (fItems[segment,which]=nil) then
        begin
          placed:=true;
          fItems[segment,which]:=TMyFlower.create(self,round(fCenterX-HALF_SPRITE_SIZE+APPLE_POSITIONS[fSegments[segment],which].x),round(TREE_BASE-(SPRITE_SIZE*segment)+fYOffset+APPLE_POSITIONS[fSegments[segment],which].Y),segment,which);
          fItemList.add(fItems[segment,which]);
        end;
      end;
    until placed;

    inc(fCurrentItems);
  end;
end;

procedure TMe.setLevel(newLevel: integer);
var
  loop : integer;
begin
  resetItems;

  if (newLevel>fLevel) then
  begin
    if (newLevel=1) then
    begin
      fSegments[1]:=TREE_SEGMENT_SAPLING;
    end
    else
    begin
      if (newLevel=2) then
      begin
        fSegments[1]:=TREE_SEGMENT_TRUNK;
        fSegments[2]:=TREE_SEGMENT_TOP;
      end
      else
      begin
        fSegments[newLevel]:=fSegments[newLevel-1];
        repeat
          if (fLevel>4) then
          begin
            fSegments[newLevel-1]:=TREE_SEGMENT_LEFTY+RANDOM(3);
          end
          else
          begin
            fSegments[newLevel-1]:=TREE_SEGMENT_LEFTY+RANDOM(2);
          end;
        until (fSegments[newLevel-1]<>fSegments[newLevel-2]);
      end;
    end;

    fLevel:=newLevel;

    fMaxItems:=0;
    for loop:=1 to fLevel do
    begin
      fMaxItems:=fMaxItems+APPLES_PER_SEGMENT[fSegments[loop]];
    end;
    if (fCurrentItems>fMaxItems) then
    begin
      raise exception.create('Internal error, tree has more items than it can hold!');
    end;

    fRequiredWaterLevel:=fLevel*100;
    fRequiredFoodLevel:=fLevel*100; // maxApples;
  end;
end;

//------------------------------------------------------------------------------

{ TMyItem }

procedure TMyItem.clearEmitter;
begin
  if (assigned(fEmitter^)) then
  begin
    pengine2d_DelEmitter(fEmitter^.id);
    fEmitter^:=nil;
  end;
end;

constructor TMyItem.create(theTree:TMe;x,y:integer;s,w:integer);
begin
  inherited create;

  fX:=x;
  fY:=y;
  fCenterY:=y+SPRITE_SIZE_TREEPARTS div 2;
  fCenterX:=x+SPRITE_SIZE_TREEPARTS div 2;

  fSegment:=s;
  fWhich:=w;

  fTheTree:=theTree;

  fNerfed:=false;
  fSuccess:=false;

  fSize:=0;
  fSizeChange:=0;

  new(fEmitter);
end;

function TMyItem.mouseHit(x,y:integer):boolean;
var
  r : zglTRect;
begin
  getBoundingBox(r);
  result:=col2d_PointInRect(x,y,r);
end;

destructor TMyItem.destroy;
begin
  clearEmitter;

  dispose(fEmitter);

  inherited;
end;

procedure TMyItem.emit(anEmitter:zglPEmitter2d;itemSize:integer);
begin
  clearEmitter;
  pengine2d_AddEmitter(anEmitter,fEmitter,fX+(itemSize div 2),fY+(itemSize div 2));
end;

procedure TMyItem.nerf;
begin
  fNerfed:=true;
end;

procedure TMyItem.success;
begin
  fSuccess:=true;
end;

procedure TMyItem.timer;
begin
  fSize:=fSize+fSizeChange;

  if (fStateTime>0) then
  begin
    dec(fStateTime);

    if (fStateTime=0) then
    begin
      stateTimeExpired;
    end;
  end;
end;

procedure TMyItem.getBoundingBox(var r:zglTRect);
begin
  r.x:=fX;
  r.y:=fY;
  r.w:=SPRITE_SIZE_TREEPARTS;
  r.h:=SPRITE_SIZE_TREEPARTS;
end;

function TMyItem.collision(x,y,w,h:single):boolean;
var
  r1,r2 : zglTRect;
begin
  getBoundingBox(r1);

  r2.x:=x;
  r2.y:=y;
  r2.w:=w;
  r2.h:=h;

  result:=col2d_Rect(r1,r2);
end;

function TMyItem.canSucceed:boolean;
begin
  result:=true;
end;

function TMyItem.canBeNerfed:boolean;
begin
  result:=false;
end;


end.
