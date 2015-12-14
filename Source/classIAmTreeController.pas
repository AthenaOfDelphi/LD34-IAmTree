unit classIAmTreeController;

interface

{$I zglCustomConfig.cfg}

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
  zgl_sound,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log;

type
  //------------------------------------------------------------------------------
  // Forward defitions

  TIAmTreeStateController = class;

  //------------------------------------------------------------------------------
  // Persitent data store - This object is retained when the controller is changed

  TIAmTreeStatePersistentData = class(TObject)
  protected
    fScore : integer;
    fTime : integer;
    fStateTime : integer;
  public
    constructor create;

    procedure reset;
    procedure stateChanged;
    procedure timer;

    property score:integer read fScore write fScore;
    property time:integer read fTime write fTime;
    property stateTime:integer read fStateTIme write fStateTime;
  end;

  //------------------------------------------------------------------------------
  // Main controller

  TIAmTreeController = class(TObject)
  protected
    fSpriteEngine : zglCSEngine2D;
    fParticles : zglTPEngine2D;

    fGameState : integer;

    fDebug : boolean;
    fDebugParticles : boolean;

    fRetiredController : TIAmTreeStateController; // Store for cleanup in timer loop
    fController : TIAmTreeStateController;
    fPersistentData : TIAmTreeStatePersistentData;

    procedure handleStateChange(sender:TObject;newState:integer);
    procedure loadResources;

  public
    constructor create;
    destructor Destroy; override;

    procedure run;

    procedure draw;
    procedure timer;
    procedure init;
    procedure update(dt:double);

    property spriteEngine:zglCSEngine2D read fSpriteEngine;
    property debug:boolean read fDebug;
    property persistentData:TIAmTreeStatePersistentData read fPersistentData;
  end;

  //------------------------------------------------------------------------------
  // Sub state controller definition

  TChangeStateEvent = procedure(sender:TObject;newState:integer) of object;

  TIAmTreeStateController = class(TObject)
  protected
    fParent : TIAmTreeController;
    fOnChangeState : TChangeStateEvent;

    procedure changeState(newState:integer);
  public
    constructor create(aParent:TIAmTreeController);

    procedure drawBeforeSprites; virtual; abstract; // Occurs before Sprite engine
    procedure drawBeforeParticles; virtual; abstract; // Occurs after Sprite engine, before particle engine
    procedure drawFinal; virtual; abstract; // Occurs after everything else
    procedure drawCursor; virtual;

    procedure timer; virtual; abstract;
    procedure init; virtual; abstract;

    property onChangeState:TChangeStateEvent read fOnChangeState write fOnChangeState;
  end;

implementation

uses
  classIAmTreeIntroController,
  classIAmTreeMenuController,
  classIAmTreeGameController,
  classIAmTreeGameOverController,
  unitGlobalResources;

//------------------------------------------------------------------------------

{ TIAmTreeController }

procedure TIAmTreeController.handleStateChange(sender:TObject;newState:integer);
begin
  if (newState<>fGameState) then
  begin
    fRetiredController:=fController;
    fGameState:=newState;

    case newState of
      GAME_STATE_INTRO : begin
        fController:=TIAmTreeIntroCOntroller.create(self);
      end;
      GAME_STATE_MAINMENU : begin
        fController:=TIAmTreeMenuController.create(self);
      end;
      GAME_STATE_INGAME : begin
        fController:=TIAmTreeGameController.create(self);
      end;
      GAME_STATE_GAMEOVER,
      GAME_STATE_GAMEOVER_END : begin
        fController:=TIAmTreeGameOverController.create(self);

        TIAmTreeGameOverController(fController).thePlayerFailed:=(fGameState=GAME_STATE_GAMEOVER);
      end;
    end;

    fPersistentData.stateChanged;

    fController.onChangeState:=self.handleStateChange;
    fController.init;
  end;
end;

procedure TIAmTreeController.loadResources;
begin
  texTree:=tex_loadFromFile('.\data\tree.png');
  tex_setFrameSize(texTree,SPRITE_SIZE,SPRITE_SIZE);
  texCritters:=tex_loadFromFile('.\data\critters.png');
  tex_setFrameSize(texCritters,SPRITE_SIZE,SPRITE_SIZE);
  texTreeParts:=tex_loadFromFile('.\data\treeparts.png');
  tex_setFrameSize(texTreeParts,SPRITE_SIZE_TREEPARTS,SPRITE_SIZE_TREEPARTS);
  texRootCritters:=tex_loadFromFile('.\data\rootitems.png');
  tex_setFrameSize(texRootCritters,SPRITE_SIZE_ROOTCRITTERS,SPRITE_SIZE_ROOTCRITTERS);
  texCursor:=tex_loadFromFile('.\data\cursor.png');
  tex_setFrameSize(texCursor,SPRITE_SIZE_CURSOR,SPRITE_SIZE_CURSOR);


  texBack_Spring:=tex_loadFromFile('.\data\back_spring.png');
  texBack_Summer:=tex_loadFromFile('.\data\back_summer.png');
  texBack_Autumn:=tex_loadFromFile('.\data\back_autumn.png');

  fntGameLarge:=font_loadFromFile('.\data\gamefont_big.zfi');
  fntGameSmall:=font_loadFromFile('.\data\gamefont_small.zfi');
  fntDebug:=font_loadFromFile('.\data\debugfont.zfi');
  fntScore:=font_loadFromFile('.\data\scorefont.zfi');

  sndWasp:=snd_loadFromFile('.\data\wasp.wav');
  sndBee:=snd_loadFromFile('.\data\bee.wav');

  emitRain:=emitter2d_LoadFromFile('.\data\particle_rain.zei');
  emitHeartFlower:=emitter2d_loadFromFile('.\data\particle_heart_flower.zei');
  emitHeartBee:=emitter2d_loadFromFile('.\data\particle_heart_bee.zei');
  emitAppleEaten:=emitter2d_loadFromFile('.\data\particle_apple_eaten.zei');
  emitAppleScored:=emitter2d_loadFromFile('.\data\particle_apple_scored.zei');
  emitFoodCritterDead:=emitter2d_loadFromFile('.\data\particle_foodcritter_dead.zei');
  emitWaterCritterDead:=emitter2d_loadFromFile('.\data\particle_watercritter_dead.zei');
end;

constructor TIAmTreeController.create;
begin
  inherited;

  fRetiredController:=nil;
  fController:=nil;
  fPersistentData:=TIAmTreeStatePersistentData.create;
  fGameState:=GAME_STATE_NONE;

  {$IFNDEF USE_ZENGL_STATIC}
  if not zglLoad( libZenGL ) Then exit;
  {$ENDIF}

  fDebug:=false;
  fDebugParticles:=false;

  randomize();

  wnd_SetCaption( 'Ludum Dare #34 - I am tree - Copyright 2015 © Christina Louise Warne (aka AthenaOfDelphi)');

  {$IFDEF DEBUG}
  scr_SetOptions( SCREEN_WIDTH, SCREEN_HEIGHT, REFRESH_MAXIMUM, FALSE, FALSE);
  {$ELSE}
  zgl_Enable( CORRECT_RESOLUTION );
  scr_CorrectResolution(SCREEN_WIDTH, SCREEN_HEIGHT);
  scr_SetOptions( zgl_Get( DESKTOP_WIDTH ), zgl_Get( DESKTOP_HEIGHT ), REFRESH_MAXIMUM, TRUE, FALSE );
  {$ENDIF}
end;

procedure TIAmTreeController.run;
begin
  zgl_Init();
end;

destructor TIAmTreeController.destroy;
begin
  fSpriteEngine.free;
  fController.free;
  fPersistentData.free;
  inherited;
end;

procedure TIAmTreeController.draw;
{$IFDEF DEBUG}
var
  loop : integer;
{$ENDIF}
begin
  batch2d_Begin();

  fController.drawBeforeSprites;

  fSpriteEngine.Draw();

  fController.drawBeforeParticles;

  pengine2d_Draw();

  {$IFDEF DEBUG}
  if fDebug then
  begin
    pr2d_Rect( 0, 0, 256, 256, $000000, 200, PR2D_FILL );
    text_Draw( fntDebug, 0, 0, 'FPS: ' + u_IntToStr( zgl_Get( RENDER_FPS ) ) );
    text_Draw( fntDebug, 0, 16, 'Sprites: ' + u_IntToStr( fSpriteEngine.Count ) );
  end;

  if fDebugParticles then
  begin
    for loop:=0 to fParticles.Count.Emitters-1 do
    begin
      with fParticles.List[loop].BBox do
      begin
        pr2d_Rect( MinX,MinY,MaxX-MinX,MaxY-MinY,$FF0000,255);
      end;
    end;
  end;
  {$ENDIF}

  fController.drawFinal;

  fController.drawCursor;

  batch2d_End();
end;

procedure TIAmTreeController.init;
begin
  snd_Init();

  loadResources;

  fSpriteEngine:=zglCSEngine2D.Create();
  pengine2d_Set( @fParticles );

  handleStateChange(self,GAME_STATE_INITIAL);
end;

procedure TIAmTreeController.timer;
begin
  if (fRetiredController<>nil) then
  begin
    fRetiredController.free;
    fRetiredController:=nil;
  end;

  fPersistentData.timer;

  fController.timer;

  fSpriteEngine.Proc();

  {$IFDEF DEBUG}
  if key_press(K_F1) then
  begin
    fDebug:=not fDebug;
  end;

  if key_press(K_F2) then
  begin
    fDebugParticles:=not fDebugParticles;
  end;
  {$ENDIF}

  if key_press(K_ESCAPE) then
  begin
    zgl_Exit();
  end;

  key_ClearState();
  mouse_ClearState();
end;

procedure TIAmTreeController.update(dt:double);
begin
  pengine2d_Proc( dt );
end;

//------------------------------------------------------------------------------

{ TIAmTreeStateController }

procedure TIAmTreeStateController.changeState(newState: integer);
begin
  assert(assigned(fOnChangeState),self.className+'.changeState - State change event handler not hooked');
  fOnChangeState(self,newState);
end;

constructor TIAmTreeStateController.create(aParent:TIAmTreeController);
begin
  inherited create;

  fParent:=aParent;
  fOnChangeState:=nil;
end;

procedure TIAmTreeStateController.drawCursor;
begin
  asprite2d_Draw(texCursor,mouse_x-HALF_SPRITE_SIZE_CURSOR,mouse_y-HALF_SPRITE_SIZE_CURSOR,SPRITE_SIZE_CURSOR,SPRITE_SIZE_CURSOR,0,1);
end;

//------------------------------------------------------------------------------


{ TIAmTreeStatePersistentData }

constructor TIAmTreeStatePersistentData.create;
begin
  inherited;

  fTime:=0;
  fStateTime:=0;
  fScore:=0;
end;

procedure TIAmTreeStatePersistentData.reset;
begin
  fScore:=0;
  stateChanged;
end;

procedure TIAmTreeStatePersistentData.stateChanged;
begin
  fStateTime:=0;
end;

procedure TIAmTreeStatePersistentData.timer;
begin
  inc(fTime);
  inc(fStateTime);
end;



end.
