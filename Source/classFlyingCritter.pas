unit classFlyingCritter;

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
  zgl_sound,
  unitConstants;

type
  TFlyingCritter = class(zglCSprite2D)
  protected
    fSpeed : zglTPoint2D;
    fTex : zglPTexture;
    fWaveTime : double;
    fWaveStep : double;
    fStartFrame : integer;
    fEndFrame : integer;
    fStartingPoint : zglTPoint2D;
    fBaseY : integer;
    fSound : zglPSound;
    fSoundVolume : single;
    fSoundID : integer;
    fOnDeath : TNotifyEvent;

    function wave:double;
  public
    constructor createWithStartingPosition(tex:zglPTexture;sound:zglPSound;engine:zglCSEngine2d;spriteId:integer;startingX:integer;startingY:integer;onDeath:TNotifyEvent);
    procedure OnInit(texture:zglPTexture;layer:integer); override;
    procedure OnDraw; override;
    procedure OnProc; override;
    procedure OnFree; override;
  end;

implementation

uses
  unitUtils;

{ TFlyingCritter_FlyingRightToLeft }

constructor TFlyingCritter.createWithStartingPosition(tex:zglPTexture;sound:zglPSound;engine:zglCSEngine2d;spriteId:integer;startingX,startingY:integer;onDeath:TNotifyEvent);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.createWithStartingPosition (%.8x) - tex=%.8x,sound=%.8x,engine=%.x8,spriteid=%d,startingX=%d,startingY=%d',
    [self.className,integer(self),integer(tex),integer(sound),integer(engine),spriteId,startingX,startingY])));
  {$ENDIF}

  fTex:=tex;
  fOnDeath:=onDeath;

  fStartingPoint.x:=startingX;
  fStartingPoint.y:=startingY-HALF_SPRITE_SIZE;

  fWaveTime:=random*TWOPI;
  fWaveStep:=WASP_WAVETIME_STEP;

  // fSound:=sound;

  inherited create(engine,spriteId);
end;

procedure TFlyingCritter.onDraw;
begin
  inherited;
end;

procedure TFlyingCritter.onFree;
begin
  // snd_Stop(fSound,fSoundId);
  if (assigned(fOnDeath)) then
  begin
    fOnDeath(self);
  end;

  inherited;
end;

procedure TFlyingCritter.onInit(texture:zglPTexture;layer:integer);
begin
  {$IFDEF DEBUG}
  log_add(UTF8String(format('%s.init (%.8x) - fTex=%.8x,fSound=%.8x,fStartFrame=%d,startingX=%.2f,startingY=%.2f',
    [self.className,integer(self),integer(fTex),integer(fSound),fStartFrame,fStartingPoint.x,fStartingPoint.y])));
  {$ENDIF}

  inherited onInit(fTex,LAYER_FLYINGCRITTERS);

  frame:=fStartFrame;
  x:=fStartingPoint.x;
  Y:=fStartingPoint.y+wave;

  //fSoundVolume:=0;
  //fSoundId:=snd_play(fSound,true,CalcX2D(x),CalcY2D(y),0,fSoundVolume);
end;

procedure TFlyingCritter.onProc;
begin
  inherited;

  x:=x+fSpeed.x;
  y:=fStartingPoint.y+wave;

  frame:=frame+WASP_FRAMERATE+(random*WASP_FRAMERATE_VARIANCE);
  if (frame>=fEndFrame) then
  begin
    frame:=fStartFrame;
  end;

  (*
  if (sign(fSpeed.x)>0) then
  begin
    if (x<0) then
    begin
      fSoundVolume:=fSOundVolume-sign(fSpeed.x)*FLYING_CRITTER_VOLUME_STEP;
    end;
    if (x>SCREEN_WIDTH) then
    begin
      fSoundVolume:=fSOundVolume+sign(fSpeed.x)*FLYING_CRITTER_VOLUME_STEP;
    end;
  end
  else
  begin
    if (x<0) then
    begin
      fSoundVolume:=fSOundVolume+sign(fSpeed.x)*FLYING_CRITTER_VOLUME_STEP;
    end;
    if (x>SCREEN_WIDTH) then
    begin
      fSoundVolume:=fSOundVolume-sign(fSpeed.x)*FLYING_CRITTER_VOLUME_STEP;
    end;
  end;

  {$IFDEF DEBUG}
  log_add(UTF8STRING(format('TFlyingCritter - SOUND VOLUME = %.4f',[fSoundVolume])));
  {$ENDIF}

  snd_setVolume(fSound,fSOundID,fSoundVolume);
  snd_setPos(fSound,fSoundId,CalcX2D(x),CalcY2D(y),0);
  *)

  if (x<RANGE_FLYINGCRITTER_MINIMUM) or (x>RANGE_FLYINGCRITTER_MAXIMUM) then
  begin
    manager.delSprite(id);
  end;
end;

function TFlyingCritter.wave: double;
begin
  result:=sin(fWaveTime)*WASP_WAVESIZE;

  fWaveTime:=fWaveTime+fWaveStep+(random*WASP_WAVETIME_STEPVARIANCE);
  if (fWaveTime>TWOPI) then
  begin
    fWaveTime:=fWaveTime-TWOPI;
  end;
end;


end.
