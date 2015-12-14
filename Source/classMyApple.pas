unit classMyApple;

interface

uses
  System.SysUtils,
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
  unitGlobalResources,
  unitConstants,
  classMe;

type
  TMyApple = class(TMyItem)
  protected
    procedure setState(newState:integer); override;
    procedure stateTimeExpired; override;
    function getIdle:boolean; override;
    function getActioned:boolean; override;
  public
    constructor create(theTree:TMe;x,y:integer;s,w:integer);

    procedure action; override;
    procedure nerf; override;
    procedure success; override;

    function canBeNerfed:boolean; override;

    procedure draw; override;
  end;


implementation

{ TMyApple }


constructor TMyApple.create(theTree:TMe;x,y:integer;s,w:integer);
begin
  inherited;

  fState:=APPLE_STATE_NONE;
  setState(APPLE_STATE_GROWING);
end;

function TMyApple.getActioned: boolean;
begin
  result:=(fState in [APPLE_STATE_HIDDEN]);
end;

function TMyApple.getIdle:boolean;
begin
  result:=(fState in [APPLE_STATE_NONE,APPLE_STATE_NORMAL,APPLE_STATE_GONE]);
end;

procedure TMyApple.draw;
begin
  if (fState=APPLE_STATE_NONE) or (fState=APPLE_STATE_EATEN) or (fState=APPLE_STATE_SCORED) then
  begin
    // Do nothing - It's not there or there is a particle in it's place
  end
  else
  begin
    asprite2d_Draw(texTreeParts,fX,fY,fSize,fSize,0,TREEPART_FRAME_APPLE,255);
  end;
end;

function TMyApple.canBeNerfed:boolean;
begin
  result:=(fState in [APPLE_STATE_NONE,APPLE_STATE_GROWING,APPLE_STATE_NORMAL,APPLE_STATE_HIDING,APPLE_STATE_UNHIDING]);
end;

procedure TMyApple.nerf;
begin
  inherited;

  setState(APPLE_STATE_EATEN);
end;

procedure TMyApple.action;
begin
  setState(APPLE_STATE_HIDING);
end;

procedure TMyApple.success;
begin
  inherited;

  setState(APPLE_STATE_SCORED);
end;

procedure TMyApple.setState(newState: integer);
begin
  if (newState<>fState) then
  begin
    fState:=newState;

    case fState of
      APPLE_STATE_GROWING : begin
        fNerfed:=false;
        fStateTime:=APPLE_FRAMES_GROWING;
        fSizeChange:=APPLE_SIZECHANGE_GROWING;
        fSize:=APPLE_SIZE_SHRUNK;
      end;
      APPLE_STATE_NORMAL : begin
        fStateTime:=0;
        fSizeChange:=0;
        fSize:=APPLE_SIZE_NORMAL;
        clearEmitter;
      end;
      APPLE_STATE_HIDING : begin
        fStateTime:=APPLE_FRAMES_HIDING;
        fSizeChange:=APPLE_SIZECHANGE_HIDING;

        // Todo : play hiding sound here
      end;
      APPLE_STATE_HIDDEN : begin
        fStateTime:=APPLE_FRAMES_HIDDEN;
        fSizeChange:=0;
        fSize:=APPLE_SIZE_SHRUNK;
      end;
      APPLE_STATE_UNHIDING : begin
        fStateTime:=APPLE_FRAMES_UNHIDING;
        fSizeChange:=APPLE_SIZECHANGE_UNHIDING;

        // Todo : play pop sound here
      end;
      APPLE_STATE_EATEN : begin
        fNerfed:=true;
        fStateTime:=APPLE_FRAMES_EATEN;
        fSizeCHange:=APPLE_SIZE_SHRUNK;
        emit(emitAppleEaten,SPRITE_SIZE_TREEPARTS);
      end;
      APPLE_STATE_GONE : begin
        fStateTime:=0;
        fSizeChange:=0;
        clearEmitter;
        fTheTree.itemRemoved(self);
      end;
      APPLE_STATE_SCORED : begin
        fStateTime:=APPLE_FRAMES_SCORED;
        emit(emitAppleScored,SPRITE_SIZE_TREEPARTS);

        // Todo : play score sound here
      end;
    end;
  end;
end;

procedure TMyApple.stateTimeExpired;
begin
  case fState of
    APPLE_STATE_GROWING : setState(APPLE_STATE_NORMAL);
    APPLE_STATE_HIDING : setState(APPLE_STATE_HIDDEN);
    APPLE_STATE_HIDDEN : setState(APPLE_STATE_UNHIDING);
    APPLE_STATE_UNHIDING : begin
      fTheTree.actionEnded;
      setState(APPLE_STATE_NORMAL);
    end;
    APPLE_STATE_EATEN : setState(APPLE_STATE_GONE);
    APPLE_STATE_SCORED : setState(APPLE_STATE_NORMAL);
    else
    begin
      raise exception.create('Unhandled transient apple state ('+intTOStr(fSTate)+')');
    end;
  end;
end;

end.
