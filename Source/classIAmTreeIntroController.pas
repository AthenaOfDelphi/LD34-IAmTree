unit classIAmTreeIntroController;

interface

uses
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
  classIAmTreeController;

type
  TIAmTreeIntroController = class(TIAmTreeStateController)
  public
    procedure drawBeforeSprites; override;
    procedure drawBeforeParticles; override;
    procedure drawFinal; override;

    procedure timer; override;
    procedure init; override;
  end;

implementation

uses
  unitConstants, unitGlobalResources;

{ TIAmTreeIntroController }

procedure TIAmTreeIntroController.drawBeforeParticles;
var
  x : integer;
begin
  inherited;

  x:=SCREEN_WIDTH div 2;

  text_Draw(fntGameLarge,x,100,'I Am Tree',TEXT_HALIGN_CENTER);

  text_draw(fntGameSmall,x,150,'Copyright © 2015 Christina Louise Warne (aka AthenaOfDelphi)',TEXT_HALIGN_CENTER);
  text_draw(fntGameSmall,x,180,'(An LD #34 Entry)',TEXT_HALIGN_CENTER);

  text_draw(fntGameSmall,x,230,'The aim of the game is to grow apples, protecting them from wasps',TEXT_HALIGN_CENTER);
  text_draw(fntGameSmall,x,260,'Feed your tree with water and food using the beetle army',TEXT_HALIGN_CENTER);
  text_draw(fntGameSmall,x,290,'If it''s got food and water during spring, flowers will grow',TEXT_HALIGN_CENTER);

  text_draw(fntGameSmall,x,350,'Prese <ENTER> to play or <ESC> at any time to exit',TEXT_HALIGN_CENTER);

  text_draw(fntGameSmall,x,430,'Built with Delphi XE7 using the ZenGL Library (http://www.zengl.org)',TEXT_HALIGN_CENTER);
  text_draw(fntGameSmall,x,460,'Follow me on twitter - @AthenaOfDelphi',TEXT_HALIGN_CENTER);
  text_draw(fntGameSmall,x,490,'or visit my blog - http://athena.outer-reaches.com',TEXT_HALIGN_CENTER);

  text_draw(fntGameSmall,x,SCREEN_HEIGHT-40,'(p.s. there may be one or two ''small'' glitches... sorry)',TEXT_HALIGN_CENTER);
end;

procedure TIAmTreeIntroController.drawBeforeSprites;
begin
  inherited;

end;

procedure TIAmTreeIntroController.drawFinal;
begin
  inherited;

end;

procedure TIAmTreeIntroController.init;
begin
  inherited;

end;

procedure TIAmTreeIntroController.timer;
begin
  inherited;

  if (key_press(K_ENTER)) then
  begin
    changeState(GAME_STATE_INGAME);
  end;
end;

end.
