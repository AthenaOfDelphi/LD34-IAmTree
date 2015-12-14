unit unitWasps;

interface

uses
  {$IFDEF DEBUG}
  System.SysUtils,
  {$ENDIF}
  classes,
  zglSpriteEngine,
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  zgl_keyboard,
  zgl_render_2d,
  zgl_fx,
  zgl_textures,
  zgl_textures_png,
  zgl_textures_jpg,
  zgl_sprite_2d,
  zgl_primitives_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log,
  unitConstants,
  classFlyingCritter;

type
  TCritterWasp = class(TFlyingCritter)
  protected
    fWaspState : integer;
  public
    constructor createWithStartingPosition(engine:zglCSEngine2d;spriteId:integer;startingX:integer;startingY:integer;onDeath:TNotifyEvent);

    procedure OnProc; override;

    property waspState:integer read fWaspState write fWaspState;
  end;

  TCritterWasp_FlyingRightToLeft = class(TCritterWasp)
  protected
  public
    constructor createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
  end;

  TCritterWasp_FlyingLeftToRight = class(TCritterWasp)
  protected
  public
    constructor createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
  end;


implementation

uses
  unitGlobalResources;


//------------------------------------------------------------------------------

{ TCritterWasp_FlyingRightToLeft }

constructor TCritterWasp.createWithStartingPosition(engine:zglCSEngine2d;spriteId:integer;startingX,startingY:integer;onDeath:TNotifyEvent);
begin
  fWaspState:=WASP_STATE_FLYING;

  inherited createWithStartingPosition(texCritters,sndWasp,engine,spriteId,startingX,startingY,onDeath);
end;

procedure TCritterWasp.onProc;
begin
  // Todo : Deal with wasp success state here

  inherited;
end;

//------------------------------------------------------------------------------

{ TCritterWasp_FlyingRightToLeft }

constructor TCritterWasp_FlyingRightToLeft.createWithStartingY(engine: zglCSEngine2d; spriteId, startingY: integer;onDeath:TNotifyEvent);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.createWithStartingY (%.8x) - tex=%.8x,engine=%.x8,spriteid=%d,startingY=%d',
    [self.className,integer(self),integer(texCritters),integer(engine),spriteId,startingY])));
  {$ENDIF}

  fSpeed.X:=-(1+random*WASP_SPEED_VARIANCE);
  fSpeed.Y:=0;

  fStartFrame:=WASP_FIRSTFRAME_RIGHTTOLEFT;
  fEndFrame:=WASP_LASTFRAME_RIGHTTOLEFT;

  inherited createWithStartingPosition(engine,spriteId,RANGE_FLYINGCRITTER_MAXIMUM,startingY,onDeath);
end;

{ TCritterWasp_FlyingLeftToRight }

constructor TCritterWasp_FlyingLeftToRight.createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.createWithStartingY (%.8x) - tex=%.8x,engine=%.x8,spriteid=%d,startingY=%d',
    [self.className,integer(self),integer(texCritters),integer(engine),spriteId,startingY])));
  {$ENDIF}

  fSpeed.X:=1+random*WASP_SPEED_VARIANCE;;
  fSpeed.Y:=0;

  fStartFrame:=WASP_FIRSTFRAME_LEFTTORIGHT;
  fEndFrame:=WASP_LASTFRAME_LEFTTORIGHT;

  inherited createWithStartingPosition(engine,spriteId,RANGE_FLYINGCRITTER_MINIMUM,startingY,onDeath);
end;


end.
