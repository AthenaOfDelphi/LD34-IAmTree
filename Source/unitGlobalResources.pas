unit unitGlobalResources;

(*

This really goes against the grain... globals, but time being what it is... bad stuff happens :)
*)

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
  zgl_particles_2d,
  zgl_font,
  zgl_text,
  zgl_math_2d,
  zgl_utils,
  zgl_log,
  zgl_sound,
  zgl_sound_wav;

var
  //------------------------------------------------------------------------------
  // Fonts

  fntDebug : zglPFont;
  fntGameLarge : zglPFont;
  fntGameSmall : zglPFont;
  fntScore : zglPFont;

  //------------------------------------------------------------------------------
  // Textures

  texTree : zglPTexture;
  texCritters : zglPTexture;
  texBack_Spring : zglPTexture;
  texBack_Summer : zglPTexture;
  texBack_Autumn : zglPTexture;
  texTreeParts : zglPTexture;
  texRootCritters : zglPTexture;
  texCursor : zglPTExture;

  //------------------------------------------------------------------------------
  // Sounds

  sndWasp : zglPSound;
  sndBee : zglPSound;

  //------------------------------------------------------------------------------
  // Particle emitters

  emitRain : zglPEmitter2d;
  emitHeartFlower : zglPEmitter2d;
  emitHeartBee : zglPEmitter2d;
  emitAppleEaten : zglPEmitter2d;
  emitAppleScored : zglPEmitter2d;
  emitFoodCritterDead : zglPEmitter2d;
  emitWaterCritterDead : zglPEmitter2d;

implementation

end.
