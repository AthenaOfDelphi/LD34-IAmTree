unit unitUtils;

interface

function CalcX2D( const X : Single ) : Single;
function CalcY2D( const Y : Single ) : Single;
function sign(src:double):integer;

implementation

uses
  unitConstants;

function CalcX2D( const X : Single ) : Single;
begin
  Result := ( X - SCREEN_WIDTH / 2 ) * ( 1 / SCREEN_WIDTH / 2 );
end;

function CalcY2D( const Y : Single ) : Single;
begin
  Result := ( Y - SCREEN_HEIGHT / 2 ) * ( 1 / SCREEN_HEIGHT / 2 );
end;

function sign(src:double):integer;
begin
  if (src>0) then
  begin
    result:=+1;
  end
  else
  begin
    result:=-1;
  end;
end;


end.
