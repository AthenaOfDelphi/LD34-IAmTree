unit classIAmTreeGameController;

interface

uses
  System.Classes,
  System.SysUtils,
  unitConstants,
  classMe,
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
  zgl_sound,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log,
  unitWasps,
  unitBees,
  classRootCritter,
  classFLyingCritter,
  classIAmTreeController;

type
  TIAmTreeGameController = class(TIAmTreeStateController)
  protected
    fMe : TMe;
    fRain: zglPPEmitter2D;
    fRootCritters : TList;
    fResources : TList;
    fSeason : integer;
    fSeasonTime : integer;
    fLevel : integer;
    fFlyingCritter : TFlyingCritter;

    (*
        if (fDebugParticles) then
    begin
      new(fRain);
      pengine2d_AddEmitter(emitRain,fRain);
    end
    else
    begin
      pengine2d_DelEmitter(fRain^.id);
      dispose(fRain);
    end;
    *)

    function addLeftToRightWasp(y:integer):TCritterWasp;
    function addRightToLeftWasp(y:integer):TCritterWasp;
    function addLeftToRightBee(y:integer):TCritterBee;
    function addRightToLeftBee(y:integer):TCritterBee;

    procedure flyingCritterDied(sender:TObject);
    procedure rootCritterDied(sender:TObject);

    procedure nextLevel;
    procedure nextSeason;
    procedure cleanupCritters;
  public
    constructor create(aParent:TIAmTreeController);
    destructor Destroy; override;

    procedure drawBeforeSprites; override;
    procedure drawBeforeParticles; override;
    procedure drawFinal; override;
    procedure drawCursor; override;

    procedure timer; override;
    procedure init; override;
  end;

implementation

uses
  unitGlobalResources, classResource;

constructor TIAmTreeGameController.create(aParent:TIAmTreeController);
begin
  inherited;

  fSeason:=SEASON_SPRING;
  fRootCritters:=TList.create;
  fResources:=TList.create;
  fLevel:=1;
end;

procedure TIamTreeGameController.nextLevel;
begin
  if (fMe.level<TREE_MAX_LEVEL) then
  begin
    fMe.levelUp;
    inc(fLevel);
    fSeason:=SEASON_SPRING;
    fSeasonTime:=SEASON_LENGTH;
    fMe.setSeason(fSeason);
  end
  else
  begin
    cleanupCritters;
    changeState(GAME_STATE_GAMEOVER_END);
  end;
end;

procedure TIAmTreeGameController.cleanupCritters;
var
  rootCritter : TRootCritter;
begin
  if (fFlyingCritter<>nil) then
  begin
    fParent.spriteEngine.DelSprite(fFlyingCritter.ID);
  end;

  while (fRootCritters.count>0) do
  begin
    rootCritter:=TRootCritter(fRootCritters[0]);
    rootCritter.unhookOnDeath;

    fParent.spriteEngine.delSprite(rootCritter.id);

    fRootCritters.delete(0);
  end;
end;

destructor TIAmTreeGameController.Destroy;
begin
  while (fRootCritters.count>0) do
  begin
    fParent.spriteEngine.DelSprite(TRootCritter(fRootCritters).ID);
    fRootCritters.delete(0);
  end;

  while (fResources.count>0) do
  begin
    TObject(fResources[0]).free;
    fResources.delete(0);
  end;

  fResources.free;
  fRootCritters.free;
end;

function TIAmTreeGameController.addLeftToRightWasp(y:integer):TCritterWasp;
var
  spriteId : integer;
begin
  spriteId:=fParent.spriteEngine.addSprite;
  result:=TCritterWasp_FlyingLeftToRight.createWithStartingY(fParent.spriteEngine,spriteId,y,flyingCritterDied);
  fParent.spriteEngine.list[spriteId]:=result;
end;

function TIAmTreeGameController.addRightToLeftWasp(y:integer):TCritterWasp;
var
  spriteId : integer;
begin
  spriteId:=fParent.spriteEngine.addSprite;
  result:=TCritterWasp_FlyingRightToLeft.createWithStartingY(fParent.spriteEngine,spriteId,y,flyingCritterDied);
  fParent.spriteEngine.list[spriteId]:=result;
end;

function TIAmTreeGameController.addLeftToRightBee(y:integer):TCritterBee;
var
  spriteId : integer;
begin
  spriteId:=fParent.spriteEngine.addSprite;
  result:=TCritterBee_FlyingLeftToRight.createWithStartingY(fParent.spriteEngine,spriteId,y,flyingCritterDied);
  fParent.spriteEngine.list[spriteId]:=result;
end;

function TIAmTreeGameController.addRightToLeftBee(y:integer):TCritterBee;
var
  spriteId : integer;
begin
  spriteId:=fParent.spriteEngine.addSprite;
  result:=TCritterBee_FlyingRightToLeft.createWithStartingY(fParent.spriteEngine,spriteId,y,flyingCritterDied);
  fParent.spriteEngine.list[spriteId]:=result;
end;

procedure TIAmTreeGameController.drawBeforeSprites;
var
  scoreString : string;
  levelString : string;
  loop : integer;

  x,w : integer;
begin
  case fSeason of
    SEASON_SPRING : ssprite2d_Draw( texBack_Spring, 0, 0, 800, 600, 0 );
    SEASON_SUMMER : ssprite2d_Draw( texBack_Summer, 0, 0, 800, 600, 0 );
    SEASON_AUTUMN : ssprite2d_Draw( texBack_Autumn, 0, 0, 800, 600, 0 );
  end;

  scoreString:='Score '+intToStr(fParent.persistentData.score);
  levelString:='Level '+intToStr(fLevel);

  text_Draw(fntGameSmall,SCREEN_WIDTH-8,8,UTF8String(scoreString),TEXT_HALIGN_RIGHT);
  text_Draw(fntGameSmall,8,8,UTF8String(levelString),TEXT_HALIGN_LEFT);

  w:=fSeasonTime div SEASON_LENGTH_SCALINGFACTOR;
  x:=(SCREEN_WIDTH-w) div 2;

  if (fSeasonTime<600) then
  begin
    pr2d_Rect( x, 8, w, 8, $FF0000 );
  end
  else
  begin
    pr2d_Rect( x, 8, w, 8, $FFFFFF );
  end;

  if (mouse_y>=TREE_BASE) then
  begin
    fx2d_setVCA($ff0000,$ff0000,$ff0000,$ff0000,255,255,255,255);
    text_Draw(fntGameSmall,0,SCREEN_HEIGHT-24,'Left - Food Beetle',TEXT_HALIGN_LEFT+TEXT_FX_VCA);
    fx2d_setVCA($0000ff,$0000ff,$0000ff,$0000ff,255,255,255,255);
    text_Draw(fntGameSmall,SCREEN_WIDTH,SCREEN_HEIGHT-24,'Right - Water Beetle',TEXT_HALIGN_RIGHT+TEXT_FX_VCA);
  end
  else
  begin
    if (fSeason=SEASON_SPRING) then
    begin
      text_draw(fntGameSmall,SCREEN_WIDTH div 2,SCREEN_HEIGHT-24,'Left - Flower Flirt',TEXT_HALIGN_CENTER);
    end
    else
    begin
      text_draw(fntGameSmall,SCREEN_WIDTH div 2,SCREEN_HEIGHT-24,'Left - Apple Away',TEXT_HALIGN_CENTER);
    end;
  end;

  (*
  fx2d_SetVCA( $FF0000, $00FF00, $0000FF, $FFFFFF, 255, 255, 255, 255 );
  text_Draw( fntMain, 400, 125, 'Gradient color for every symbol', TEXT_FX_VCA or TEXT_HALIGN_CENTER );
  *)
  fMe.draw;

  for loop:=0 to fResources.count-1 do
  begin
    TResource(fResources[loop]).draw;
  end;
end;

procedure TIAmTreeGameController.drawCursor;
var
  x,y : integer;
begin
  x:=mouse_x;
  y:=mouse_y;

  if (y>TREE_BASE) then
  begin
    y:=TREE_BASE;
  end;

  asprite2d_draw(texCursor,x-HALF_SPRITE_SIZE_CURSOR,y-HALF_SPRITE_SIZE_CURSOR,SPRITE_SIZE_CURSOR,SPRITE_SIZE_CURSOR,0,1);
end;

procedure TIAmTreeGameController.drawBeforeParticles;
begin
end;

procedure TIAmTreeGameController.drawFinal;
begin
  {$IFDEF DEBUG}

  if (fParent.debug) then
  begin
      text_Draw( fntDebug, 0, 32, 'A/S - Add wasps, K/L - Add bees');
      text_Draw( fntDebug, 0, 48, 'W - Play sound. Y - Level up');
      text_Draw( fntDebug, 0, 64, 'T - Next season');
      text_Draw( fntDebug, 0, 80, 'F - Add flower');
      text_Draw( fntDebug, 0, 96, 'F2 - Parts. b/box');
  end;
  {$ENDIF}
end;

procedure TIAmTreeGameController.timer;
var
  spriteId : integer;
  aRootCritter : TRootCritter;
  aResource : TResource;
  loop : integer;
  rsrcLoop : integer;
  cR : zglTRect;
  rR : zglTRect;
  aSprite : zglCSprite2D;
  anItem : TMyItem;
  y : integer;
begin
  fMe.timer;

  //------------------------------------------------------------------------------

  {$IFDEF DEBUG}
  if (fParent.debug) then
  begin
    if key_press(K_A) then
    begin
      if (fFlyingCritter=nil) then
      begin
        fFlyingCritter:=addLeftToRightWasp(fMe.getRandomCritterY);
      end;
    end;

    if key_press(K_S) then
    begin
      if (fFlyingCritter=nil) then
      begin
        fFlyingCritter:=addRightToLeftWasp(fMe.getRandomCritterY);
      end;
    end;

    if key_press(K_K) then
    begin
      if (fFlyingCritter=nil) then
      begin
        fFlyingCritter:=addLeftToRightBee(fMe.getRandomCritterY);
      end;
    end;

    if key_press(K_L) then
    begin
      if (fFlyingCritter=nil) then
      begin
        fFlyingCritter:=addRightToLeftBee(fMe.getRandomCritterY);
      end;
    end;

    if key_press(K_H) then
    begin
      if (fFlyingCritter<>nil) then
      begin
        if (fFlyingCritter is TCritterBee) then
        begin
          TCritterBee(fFlyingCritter).inLove:=true;
        end;
      end;
    end;

    if key_press(K_Y) then
    begin
      fMe.levelup;
    end;

    if key_press(K_W) then
    begin
      snd_play(sndWasp,false,0,0,0);
    end;

    if key_press(K_F) then
    begin
      if not fMe.full then
      begin
        fMe.addFLower;
      end;
    end;

    if key_press(K_T) then
    begin
      nextSeason;
    end;
  end;
  {$ENDIF}

  //------------------------------------------------------------------------------
  // Add root critters

  if (mouse_y>TREE_BASE) then
  begin
    if (fRootCritters.count<ROOTCRITTERS_MAX) then
    begin
      if (mouse_click(M_BLEFT)) then
      begin
        spriteId:=fParent.spriteEngine.addSprite;
        aRootCritter:=TRootCritter.createWithStartingX(fParent.spriteEngine,spriteId,mouse_x,fMe,true,rootCritterDied);
        fParent.spriteEngine.list[spriteId]:=aRootCritter;

        fRootCritters.add(aRootCritter);
      end
      else
      begin
        if (mouse_click(M_BRIGHT)) then
        begin
          spriteId:=fParent.spriteEngine.addSprite;
          aRootCritter:=TRootCritter.createWithStartingX(fParent.spriteEngine,spriteId,mouse_x,fMe,false,rootCritterDied);
          fParent.spriteEngine.list[spriteId]:=aRootCritter;

          fRootCritters.add(aRootCritter);
        end;
      end;
    end;
  end;

  //------------------------------------------------------------------------------
  // Add resources

  if (fResources.Count<MAX_RESOURCES) then
  begin
    if (random(1000)<=RESOURCE_ADD_FRAME_CHANCE) then
    begin
      aResource:=TResource.create(random(2)=1,random(SCREEN_WIDTH-SPRITE_SIZE_RESOURCES),TREE_BASE+SPRITE_SIZE_RESOURCES+random(SCREEN_HEIGHT-TREE_BASE-SPRITE_SIZE_RESOURCES*2));
      fResources.add(aResource);
    end;
  end;

  //------------------------------------------------------------------------------
  // Look for root critter collisions

  cr.w:=SPRITE_SIZE_ROOTCRITTERS;
  cr.h:=SPRITE_SIZE_ROOTCRITTERS;
  rr.w:=SPRITE_SIZE_RESOURCES;
  rr.h:=SPRITE_SIZE_RESOURCES;

  for loop:=0 to fRootCritters.count-1 do
  begin
    aRootCritter:=TRootCritter(fRootCritters[loop]);

    if (aRootCritter.canEat) then
    begin
      cR.x:=aRootCritter.x;
      cr.y:=aRootCritter.y;

      for rsrcLoop:=fResources.count-1 downto 0 do
      begin
        aResource:=TResource(fResources[rsrcLoop]);

        rR.x:=aResource.x;
        rR.y:=aResource.y;

        if (col2d_Rect(cR,rR)) then
        begin
          if (aResource.food) then
          begin
            aRootCritter.hitFood;
          end
          else
          begin
            aRootCritter.hitWater;
          end;

          fResources.delete(rsrcLoop);
          aResource.free;

          break;
        end;
      end;
    end;
  end;

  //------------------------------------------------------------------------------

  dec(fSeasonTime);
  if (fSeasonTime=0) then
  begin
    nextSeason;
  end;

  //------------------------------------------------------------------------------

  if (fParent.spriteEngine.count>0) then
  begin
    for loop:=1 to fParent.spriteEngine.count do
    begin
      aSprite:=fParent.spriteEngine.List[loop];

      if (aSprite is TFlyingCritter) then
      begin
        anItem:=fMe.flyingCritterHit(aSprite.x,aSprite.y,aSprite.W,aSprite.h);

        if (anItem<>nil) then
        begin
          if (fSeason=SEASON_SPRING) then
          begin
            if (aSprite is TCritterBee) then
            begin
              if (anItem.canSucceed) and (not TCritterBee(aSprite).inLove) then
              begin
                anItem.success;
                TCritterBee(aSprite).inLove:=true;
                fParent.persistentData.score:=fParent.persistentData.score+SCORE_POLINATION;
              end;
            end;
          end
          else
          begin
            if (aSprite is TCritterWasp) then
            begin
              if (anItem.canBeNerfed) then
              begin
                anItem.nerf;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  //------------------------------------------------------------------------------
  // Spawn flyers

  if (fFlyingCritter=nil) then
  begin
    if (random(1000)<=FLYINGCRITTER_SPAWN_CHANCE) then
    begin
      y:=fMe.getRandomCritterY;

      if (y>=0) then
      begin
        if (fSeason=SEASON_SPRING) or ((fSeason=SEASON_SUMMER) and (random(100)<=FLYINGCRITTER_BEECHANCE_IN_SUMMER)) then
        begin
          if (random(100)<=50) then
          begin
            fFlyingCritter:=addLeftToRightBee(y);
          end
          else
          begin
            fFlyingCritter:=addRightToLeftBee(y);
          end;
        end
        else
        begin
          if (random(100)<=50) then
          begin
            fFlyingCritter:=addLeftToRightWasp(y);
          end
          else
          begin
            fFlyingCritter:=addRightToLeftWasp(y);
          end;
        end;
      end;
    end;
  end;

end;

procedure TIAmTreeGameController.init;
begin
  fMe:=TMe.create(SCREEN_WIDTH div 2,0);
  fMe.setSeason(fSeason);
  fSeasonTime:=SEASON_LENGTH;
  fParent.persistentData.reset;
end;

procedure TIAmTreeGameController.nextSeason;
begin
  if (not fMe.hasItems) then
  begin
    cleanupCritters;
    changeState(GAME_STATE_GAMEOVER);
  end
  else
  begin
    if (fSeason=SEASON_AUTUMN) then
    begin
      // End of level
      fParent.persistentData.score:=fParent.persistentData.score+(fMe.itemCount*SCORE_APPLE);
      nextLevel;
    end
    else
    begin
      fSeason:=fSeason+1;
      fSeasonTime:=SEASON_LENGTH;
      fMe.setSeason(fSeason);
    end;
  end;
end;

procedure TIAmTreeGameController.flyingCritterDied(sender:TObject);
begin
  fFlyingCritter:=nil;
end;

procedure TIAmTreeGameController.rootCritterDied(sender:TObject);
var
  idxPos : integer;
begin
  idxPos:=fRootCritters.indexOf(sender);

  if (idxPos>=0) then
  begin
    fRootCritters.delete(idxPos);
  end;
end;

end.
