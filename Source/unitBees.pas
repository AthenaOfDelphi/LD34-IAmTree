unit unitBees;

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
  zgl_particles_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log,
  zgl_sound,
  unitConstants,
  classFlyingCritter;

type
  TCritterBee = class(TFlyingCritter)
  protected
    fInLove : boolean;
    fInLoveEmitter : zglPPEmitter2D;
  public
    constructor createWithStartingPosition(tex:zglPTexture;sound:zglPSound;engine:zglCSEngine2d;spriteId:integer;startingX:integer;startingY:integer;onDeath:TNotifyEvent);
    destructor Destroy; override;

    procedure OnProc; override;

    property inLove:boolean read fInLove write fInLove;
  end;

  TCritterBee_FlyingRightToLeft = class(TCritterBee)
  protected
  public
    constructor createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
  end;

  TCritterBee_FlyingLeftToRight = class(TCritterBee)
  protected
  public
    constructor createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
  end;


implementation

uses
  unitGlobalResources, unitUtils;


//------------------------------------------------------------------------------

{ TCritterBee_FlyingRightToLeft }

constructor TCritterBee_FlyingRightToLeft.createWithStartingY(engine:zglCSEngine2d;spriteId,startingY:integer;onDeath:TNotifyEvent);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.createWithStartingY (%.8x) - tex=%.8x,engine=%.x8,spriteid=%d,startingY=%d',
    [self.className,integer(self),integer(texCritters),integer(engine),spriteId,startingY])));
  {$ENDIF}

  fSpeed.X:=-(1+random*BEE_SPEED_VARIANCE);
  fSpeed.Y:=0;

  fStartFrame:=BEE_FIRSTFRAME_RIGHTTOLEFT;
  fEndFrame:=BEE_LASTFRAME_RIGHTTOLEFT;

  inherited createWithStartingPosition(texCritters,sndBee,engine,spriteId,RANGE_FLYINGCRITTER_MAXIMUM,startingY,onDeath);
end;

{ TCritterBee_FlyingLeftToRight }

constructor TCritterBee_FlyingLeftToRight.createWithStartingY(engine:zglCSEngine2d;spriteId:integer;startingY:integer;onDeath:TNotifyEvent);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.createWithStartingY (%.8x) - tex=%.8x,engine=%.x8,spriteid=%d,startingY=%d',
    [self.className,integer(self),integer(texCritters),integer(engine),spriteId,startingY])));
  {$ENDIF}

  fSpeed.X:=1+random*BEE_SPEED_VARIANCE;;
  fSpeed.Y:=0;

  fStartFrame:=BEE_FIRSTFRAME_LEFTTORIGHT;
  fEndFrame:=BEE_LASTFRAME_LEFTTORIGHT;

  inherited createWithStartingPosition(texCritters,sndBee,engine,spriteId,RANGE_FLYINGCRITTER_MINIMUM,startingY,onDeath);
end;

{ TCritterBee }

constructor TCritterBee.createWithStartingPosition(tex: zglPTexture;
  sound: zglPSound; engine: zglCSEngine2d; spriteId, startingX,
  startingY: integer;onDeath:TNotifyEvent);
begin
  fInLove:=false;
  new(fInLoveEmitter);

  fInLoveEmitter^:=nil;

  inherited;
end;

destructor TCritterBee.destroy;
begin
  if (fInLoveEmitter^<>nil) then
  begin
    pengine2d_DelEmitter(fInLoveEmitter^.id);
  end;

  dispose(fInLoveEmitter);

  inherited;
end;

procedure TCritterBee.OnProc;
begin
  inherited;

  if (fInLove) then
  begin
    if (fInLoveEmitter^=nil) then
    begin
      pengine2d_AddEmitter(emitHeartBee,fInLoveEmitter);
    end;

    if (sign(fSpeed.x)>0) then
    begin
      fInLoveEmitter^.Params.Position.X:=x+BEE_EMITTER_OFFSETX_LEFTTORIGHT;
    end
    else
    begin
      fInLoveEmitter^.Params.Position.X:=x+BEE_EMITTER_OFFSETX_RIGHTTOLEFT;
    end;
    fInLoveEmitter^.Params.Position.y:=y+BEE_EMITTER_OFFSETY;
  end
  else
  begin
    if (fInLoveEmitter^<>nil) then
    begin
      pengine2d_DelEmitter(fInLoveEmitter^.ID);
      fInLoveEmitter^:=nil;
    end;
  end;

end;

end.
