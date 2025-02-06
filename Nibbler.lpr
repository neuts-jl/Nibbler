{
  *****************************************************************************
   Program     : Nibbler
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : Created in 1990 resurrected the 01/02/2025

   This program is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along with
   this program. If not, see <https://www.gnu.org/licenses/>.
  *****************************************************************************
}

program Nibbler;

uses
  crt, Classes, Windows,Sysutils, IniFiles;

const

  cMaxTime = 20;
  MaxGameTime = 2500;
  WidthPlayground=40;
  HeightPlayground=21;
  BodyLen=1000;

  cBodyCar=#4;
  cHeadCar=#1;

  vkEscape=#27;
  vkExtend=#0;
  vkUp=#72;
  vkDown=#80;
  vkRight=#77;
  vkLeft=#75;

  Widthboard=58;
  HeightBoard=21;
  xBoard=41;
  xStatus=13;
  yTitle=1;
  yScore=11;
  yTime=13;
  yHelp=21;
  yCopyRight=15;

type
  TCarterpillar=record
    Len:integer;
    Color:integer;
    x:integer;
    y:integer;
    Body:array[0..BodyLen] of TPoint;
    Time:integer;
  end;

const
  ColorMap: array[0..15] of record
    Name: string;
    Value: Byte;
  end = (
    (Name: 'Black';        Value: Black),
    (Name: 'Blue';         Value: Blue),
    (Name: 'Green';        Value: Green),
    (Name: 'Cyan';         Value: Cyan),
    (Name: 'Red';          Value: Red),
    (Name: 'Magenta';      Value: Magenta),
    (Name: 'Brown';        Value: Brown),
    (Name: 'LightGray';    Value: LightGray),
    (Name: 'DarkGray';     Value: DarkGray),
    (Name: 'LightBlue';    Value: LightBlue),
    (Name: 'LightGreen';   Value: LightGreen),
    (Name: 'LightCyan';    Value: LightCyan),
    (Name: 'LightRed';     Value: LightRed),
    (Name: 'LightMagenta'; Value: LightMagenta),
    (Name: 'Yellow';       Value: Yellow),
    (Name: 'White';        Value: White)
  );

var
  Stop, Escape, Miam: boolean;
  Score, MaxScore: word;
  Level: word;
  Carterpillar: TCarterpillar;
  BackgroundColor, WallColor, TrackColor: Integer;
  EggColor: Integer;
  GameTime: word;
  Playground:Array[1..HeightPlayground+1,1..WidthPlayground+1] of Char;

function sndPlaySound32bit(lpSoundName: PChar; uFlags: LongInt): LongInt; stdcall; external 'winmm.dll' name 'sndPlaySoundA';

procedure PlaySound(FileName:string;Const Wait:boolean=True);
const
  SND_SYNC = $0000;
  SND_ASYNC = $0001;
  SND_FILENAME = $20000;

var
  Options:Longint;
begin
  if ExtractFileExt(FileName)='' then
    FileName:=FileName+'.wav';
  FileName:=ExtractFilePath(ParamStr(0))+'sounds/'+FileName;
  if Wait then
    Options:=SND_FILENAME or SND_SYNC
  else
    Options:=SND_FILENAME or SND_ASYNC;
  sndPlaySound32bit(PChar(FileName),Options);
end;

function IsMatch(Car: char; x, y: Integer): boolean;
begin
  Result:=PlayGround[y,x]=Car;
end;

procedure ShowPlayground;
var
  x, y: word;
begin
  TextBackground(BackgroundColor);
  for y:=1 to HeightBoard do
  begin
    GotoXY(1,y);
    Write(StringOfChar(' ',WidthBoard));
  end;
  MaxScore:=0;
  for y := 1 to HeightPlayground do
  begin
    for x := 1 to WidthPlayground do
    begin
      gotoXY(x,y);
      Case PlayGround[y,x] of
        '#':
        begin
          TextBackground(WallColor);
          TextColor(WallColor);
          write(' ');
        end;
        ' ':
        begin
          TextBackground(BackgroundColor);
          TextColor(TrackColor);
          write('.');
        end;
        'o':
        begin
          TextBackground(BackgroundColor);
          TextColor(EggColor);
          write('o');
          Inc(MaxScore,10);
        end;
      end;
    end;
  end;
end;

function ColorNameToInt(ColorName: string): Integer;
var
  i: Integer;
begin
  Result := Black;
  ColorName := LowerCase(ColorName);

  for i := 0 to High(ColorMap) do
  begin
    if LowerCase(ColorMap[i].Name) = ColorName then
    begin
      Result := ColorMap[i].Value;
      Exit;
    end;
  end;
end;

function LevelFileName(Level:integer):string;
begin
  Result:=ExtractFilePath(ParamStr(0))+'levels/Level'+IntToStr(Level)+'.ini';
end;

procedure LoadLevel(Level:integer);
var
  FIni: TIniFile;
  FBoardData: TStringList;
  i: Integer;
begin
  FIni := TIniFile.Create(LevelFileName(Level));

  BackgroundColor := ColorNameToInt(FIni.ReadString('Parameters', 'BackgroundColor', 'Black'));
  WallColor := ColorNameToInt(FIni.ReadString('Parameters', 'WallColor', 'White'));
  TrackColor := ColorNameToInt(FIni.ReadString('Parameters', 'TrackColor', 'Gray'));
  Carterpillar.Color := ColorNameToInt(FIni.ReadString('Parameters', 'Carterpillar.Color', 'Red'));
  EggColor := ColorNameToInt(FIni.ReadString('Parameters', 'EggColor', 'White'));

  FBoardData := TStringList.Create;
  try
    FIni.ReadSectionRaw('Board', FBoardData);
    for i := 1 to Min(FBoardData.Count,HeightPlayground) do
      Playground[i] := Copy(FBoardData[i - 1],1,WidthPlayground);
  finally
    FBoardData.Free;
    FIni.Free;
  end;
  ShowPlayground;
end;

procedure ShowLevel4;
begin
  BackgroundColor := red;
  WallColor := Yellow;
  TrackColor := Black;
  Carterpillar.Color := Lightcyan;
  EggColor := White;
  Playground[ 1]:='###################';
  Playground[ 2]:='#o       o       o#';
  Playground[ 3]:='# ####### ####### #';
  Playground[ 4]:='# #o    o o    o# #';
  Playground[ 5]:='# # #####o##### # #';
  Playground[ 6]:='# # #o       o# # #';
  Playground[ 7]:='#o# # ####### # #o#';
  Playground[ 8]:='#      o   o      #';
  Playground[ 9]:='# ############### #';
  Playground[10]:='#   o   o o  o    #';
  Playground[11]:='## ###### ###### ##';
  Playground[12]:='#   o   o o  o    #';
  Playground[13]:='# ############### #';
  Playground[14]:='#      o   o      #';
  Playground[15]:='#o# # ####### # #o#';
  Playground[16]:='# # #o       o# # #';
  Playground[17]:='# # #####o##### # #';
  Playground[18]:='# #o    o o    o# #';
  Playground[19]:='# ####### ####### #';
  Playground[20]:='#o       o       o#';
  Playground[21]:='###################';
  ShowPlayground;
end;

procedure ShowLevel5;
begin
  BackgroundColor := Black;
  WallColor := Lightred;
  TrackColor := Blue;
  Carterpillar.Color := Yellow;
  EggColor := White;
  Playground[ 1]:='###################';
  Playground[ 2]:='#o   o   o   o   o#';
  Playground[ 3]:='# #### # # # #### #';
  Playground[ 4]:='# #o   # o #   o# #';
  Playground[ 5]:='#o# ## # # # ## #o#';
  Playground[ 7]:='#  o o   o   o o  #';
  Playground[ 8]:='#o# ## ##### ## #o#';
  Playground[ 9]:='# #o   # o #   o# #';
  Playground[10]:='# ### ##o#o## ### #';
  Playground[11]:='#        o        #';
  Playground[12]:='#o###o#######o###o#';
  Playground[13]:='#        o        #';
  Playground[14]:='# ### ##o#o## ### #';
  Playground[15]:='# #o   # o #   o# #';
  Playground[16]:='#o# ## ##### ## #o#';
  Playground[17]:='#  o o   o   o o  #';
  Playground[18]:='#o# ## # # # ## #o#';
  Playground[19]:='# #o   # o #   o# #';
  Playground[20]:='# #### # # # #### #';
  Playground[21]:='#o   o   o   o   o#';
  Playground[22]:='###################';
  ShowPlayground;
end;

procedure ShowLevel6;
begin
  BackgroundColor := Black;
  WallColor := LightGreen;
  TrackColor := White;
  Carterpillar.Color := Blue;
  EggColor := Yellow;
  Playground[ 1]:='###################';
  Playground[ 2]:='#o   o   o   o   o#';
  Playground[ 3]:='# ####### ####### #';
  Playground[ 4]:='#o#o  o  o  o  o#o#';
  Playground[ 5]:='# # ### ### ### # #';
  Playground[ 6]:='# # # o  o  o # # #';
  Playground[ 7]:='# #o# ####### #o# #';
  Playground[ 8]:='# o #o   o   o# o #';
  Playground[ 9]:='#o# # # ### # # #o#';
  Playground[10]:='# # # #o o o# # # #';
  Playground[11]:='#o#o#o# ### #o#o#o#';
  Playground[12]:='# # # #o o o# # # #';
  Playground[13]:='#o# # # ### # # #o#';
  Playground[14]:='# o #o   o   o# o #';
  Playground[15]:='# #o# ####### #o# #';
  Playground[16]:='# # # o  o  o # # #';
  Playground[17]:='# # ### ### ### # #';
  Playground[18]:='#o#o  o  o  o  o#o#';
  Playground[19]:='# ####### ####### #';
  Playground[20]:='#o   o   o   o   o#';
  Playground[21]:='###################';
  ShowPlayground;
end;

procedure ShowTitle;
begin
  TextColor(Yellow);
  TextBackground(Brown);
  GotoXY(xBoard, yTitle);
  Write('               ');
  GotoXY(xBoard, yTitle+1);
  Write('    NIBBLER    ');
  GotoXY(xBoard, yTitle+2);
  Write('               ');
  TextBackground(Blue);
  GotoXY(xBoard, yTitle+6);
  Write(' >> LEVEL ', Level, ' << ');
end;

procedure ShowScore;
begin
  TextColor(Yellow);
  TextBackground(Blue);
  GotoXY(xBoard, yScore);
  Write(' Score :',Score: 5, '  ');
end;

procedure ShowGameTime;
begin
  TextColor(Yellow);
  TextBackground(Blue);
  GotoXY(xBoard,yTime);
  Write('  Time :',GameTime: 5, '  ');
end;

procedure ShowCopyright;
begin
  TextColor(Yellow);
  TextBackground(Brown);
  GotoXY(xBoard, yCopyright);
  Write('    Written    ');
  GotoXY(xBoard, yCopyright+1);
  Write('      by       ');
  GotoXY(xBoard, yCopyright+2);
  Write('   Neuts JL    ');
  GotoXY(xBoard, yCopyright+3);
  Write('   @   1990    ');
end;

procedure ShowHelp;
begin
  TextColor(White);
  TextBackground(Brown);
  GotoXY(xBoard-2, yHelp);
  Write(' Escape  for break ');
end;

procedure ClearTitle;
begin
  TextBackground(BackgroundColor);
  GotoXY(xBoard, yTitle);
  Write('               ');
  GotoXY(xBoard, yTitle+1);
  Write('               ');
  GotoXY(xBoard, yTitle+2);
  Write('               ');
  GotoXY(xBoard, yTitle+6);
  Write('               ');
end;

procedure ClearScore;
begin
  TextBackground(BackgroundColor);
  GotoXY(xBoard, yScore);
  Write('               ');
end;

procedure ClearGameTime;
begin
  TextBackground(BackgroundColor);
  GotoXY(xBoard, yTime);
  Write('               ');
end;

procedure ShowCarterpillar;
var
  BodyPart: char;
  i: integer;
  Eaten: boolean;
begin
  Eaten := False;
  if IsMatch('o', Carterpillar.x, Carterpillar.y) then
  begin
    Inc(Carterpillar.Len);
    Eaten := True;
    Score := Score + 10;
    ShowScore;
  end;
  if (Carterpillar.x <> Carterpillar.Body[0].x)
  or (Carterpillar.y <> Carterpillar.Body[0].y) then
  begin
    for i := Carterpillar.Len downto 1 do
    begin
      Carterpillar.Body[i].x := Carterpillar.Body[i - 1].x;
      Carterpillar.Body[i].y := Carterpillar.Body[i - 1].y;
    end;
    Carterpillar.Body[0].x := Carterpillar.x;
    Carterpillar.Body[0].y := Carterpillar.y;
  end;
  if Miam then
    Carterpillar.Color := Carterpillar.Color + blink;
  for i := 0 to Carterpillar.Len do
  begin
    if i = 0 then
      BodyPart := cHeadCar
    else if i = Carterpillar.Len then
      BodyPart := ' '
    else
      BodyPart := cBodyCar;
    GotoXY(Carterpillar.Body[i].x, Carterpillar.Body[i].y);
    TextBackground(BackgroundColor);
    TextColor(Carterpillar.Color);
    Write(BodyPart);
    PlayGround[Carterpillar.Body[i].y, Carterpillar.Body[i].x]:=BodyPart;
  end;
  if Eaten then
    PlaySound('eat',False);
end;

procedure SelectDirection;
type
  TDirection = (dirNone, dirUp, dirDown, dirLeft, dirRight);
var
  Key: char;
  Test: word;
  Direction, NewDirection: TDirection;
  ax, ay: Integer;
begin
  Carterpillar.Time := cMaxTime;
  Test := 5 + Carterpillar.Time;
  Direction := dirNone;
  NewDirection := TDirection(Random(4) + 1);
  ax := Carterpillar.x;
  ay := Carterpillar.y;

  repeat
    Dec(Test);
    if Carterpillar.Time = 0 then
    begin
      case NewDirection of
        dirUp:    NewDirection := dirDown;
        dirDown:  NewDirection := dirLeft;
        dirLeft:  NewDirection := dirRight;
        dirRight: NewDirection := dirUp;
      else
        NewDirection := dirUp;
      end;
      Direction := NewDirection;
    end
    else
    begin
      Dec(Carterpillar.Time);
      Dec(GameTime);
      if GameTime = 0 then Stop := True;
      ShowGameTime;
      Delay(30);

      if KeyPressed then
      begin
        Key := ReadKey;
        if Key = vkEscape then Escape := True;
        if Key = vkExtend then
        begin
          Key := ReadKey;
          case Key of
            vkUp:    Direction := dirUp;
            vkDown:  Direction := dirDown;
            vkRight: Direction := dirRight;
            vkLeft:  Direction := dirLeft;
          end;
        end;
      end;
    end;

    case Direction of
      dirUp:
        if not IsMatch(cBodyCar, Carterpillar.x, Carterpillar.y - 1)
        and not IsMatch('#', Carterpillar.x, Carterpillar.y - 1) then
          Dec(Carterpillar.y);
      dirDown:
        if not IsMatch(cBodyCar, Carterpillar.x, Carterpillar.y + 1)
        and not IsMatch('#', Carterpillar.x, Carterpillar.y + 1) then
          Inc(Carterpillar.y);
      dirLeft:
        if not IsMatch(cBodyCar, Carterpillar.x - 1, Carterpillar.y)
        and not IsMatch('#', Carterpillar.x - 1, Carterpillar.y) then
          Dec(Carterpillar.x);
      dirRight:
        if not IsMatch(cBodyCar, Carterpillar.x + 1, Carterpillar.y)
        and not IsMatch('#', Carterpillar.x + 1, Carterpillar.y) then
          Inc(Carterpillar.x);
    end;

    if (ax <> Carterpillar.x) or (ay <> Carterpillar.y) then
      PlaySound('swipe', False)
    else
      Direction := dirNone;

  until (Direction <> dirNone) or Stop or Escape or (Test = 0);
  Miam := (Test = 0);
end;

procedure GameInit;
var
  i: integer;
begin
  Carterpillar.Len := 4;
  for i := 0 to Carterpillar.Len + 1 do
  begin
    Carterpillar.Body[i].x := i + 4;
    Carterpillar.Body[i].y := 4;
  end;
  Carterpillar.x := Carterpillar.Body[0].x;
  Carterpillar.y := Carterpillar.Body[0].y;
  Stop := False;
  Escape := False;
  Miam := False;
  GameTime := MaxGameTime;
  Score := 0;
  ShowCarterpillar;
  ShowCopyright;
  PlaySound('intro',false);
  for i := 1 to 10 do
  begin
    ClearTitle;
    delay(100);
    ShowTitle;
    ClearScore;
    delay(100);
    ShowScore;
    ClearGameTime;
    delay(100);
    ShowGameTime;
  end;
  Delay(500);
  ShowCopyright;
  ShowHelp;
end;

procedure RunGame;
begin
  CursorOff;
  Level := 1;
  repeat
    LoadLevel(Level);
    GameInit;
    repeat
      SelectDirection;
      ShowCarterpillar;
    until Stop or Escape or (Score >= MaxScore) or Miam;
    if Miam then
    begin
      TextColor(Yellow); // + blink
      TextBackground(red);
      GotoXY(xStatus, 13);
      write(' hae hae...');
      PlaySound('miam');
    end
    else if Stop then
    begin
      TextColor(Yellow); // + blink
      TextBackground(red);
      GotoXY(xStatus, 13);
      Write(' OUT OF TIME ')
    end
    else
    begin
      TextColor(Yellow); // + blink
      TextBackground(red);
      GotoXY(xStatus, 13);
      Write('  GAME OVER  ');
    end;
    if Score < MaxScore then
    begin
      PlaySound('Lost');
      if Level > 1 then
        Dec(Level);
    end
    else
    begin
      PlaySound('winner');
      if FileExists(LevelFileName(Level+1)) then
        Inc(Level);
    end;
    Delay(1000);
  until Escape;
  TextBackground(Black);
  Textcolor(LightGray);
  clrscr;
  CursorOn;
end;

begin
  TextBackground(Black);
  Clrscr;
  CheckBreak := True;
  RunGame;
end.
