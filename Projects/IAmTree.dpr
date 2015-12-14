program IAmTree;

{$I zglCustomConfig.cfg}

{$R *.res}

uses
  {$IFDEF DEBUG}
  System.SysUtils,
  {$ENDIF }
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
  unitConstants in '..\Source\unitConstants.pas',
  classIAmTreeController in '..\Source\classIAmTreeController.pas',
  classIAmTreeIntroController in '..\Source\classIAmTreeIntroController.pas',
  unitBees in '..\Source\unitBees.pas',
  classFlyingCritter in '..\Source\classFlyingCritter.pas',
  unitGlobalResources in '..\Source\unitGlobalResources.pas',
  unitUtils in '..\Source\unitUtils.pas',
  classMe in '..\Source\classMe.pas',
  classMyApple in '..\Source\classMyApple.pas',
  classIAmTreeGameController in '..\Source\classIAmTreeGameController.pas',
  classIAmTreeMenuController in '..\Source\classIAmTreeMenuController.pas',
  classIAmTreeGameOverController in '..\Source\classIAmTreeGameOverController.pas',
  classRootCritter in '..\Source\classRootCritter.pas',
  classMyFlower in '..\Source\classMyFlower.pas',
  classResource in '..\Source\classResource.pas';

var
  appController : TIAmTreeController;

//------------------------------------------------------------------------------
// Todo list

// todo : Implement apples
// DONE : Implement flowers
// todo : Hook apples into tree
// DONE : Hook flowes into tree
// todo : Implement basic intro controller
// todo : Implement basic menu controller
// todo : Implement basic game over controller

//------------------------------------------------------------------------------

procedure Draw;
begin
  appController.draw;
end;

procedure Timer;
begin
  appController.timer;
end;

procedure Init;
begin
  appController.init;
end;

procedure Update(dt:double);
begin
  appController.update(dt);
end;

//------------------------------------------------------------------------------

procedure hookupZenGL;
begin
  timer_Add( @Timer, 16 ); // This is approx. 62.5 frames per second
  zgl_Reg( SYS_LOAD, @Init );
  zgl_Reg( SYS_DRAW, @Draw );
  zgl_Reg( SYS_UPDATE, @Update );
end;

//------------------------------------------------------------------------------

begin
  appController:=TIAmTreeCOntroller.create;
  hookupZenGL;
  appController.run;
  appController.free;
end.
