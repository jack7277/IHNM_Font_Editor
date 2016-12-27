unit Unit1;
{$OPTIMIZATION off}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Spin, Math;

type
  TForm1 = class(TForm)
    img1: TImage;
    _FontNum: TScrollBar;
    TMemoLOG: TMemo;
    imgFontImage: TImage;
    btn_SaveBTN: TButton;
    FontZoom1: TScrollBar;
    ScrollBar2: TScrollBar;
    _FontWidth: TSpinEdit;
    _FontFlag: TSpinEdit;
    _FontTracking: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    _ImportBMP: TButton;
    _C_height: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    _FontIndex: TSpinEdit;
    _row_length: TSpinEdit;
    _ClrSym: TButton;
    Button1: TButton;
    _FontChoose: TScrollBar;
    procedure FormActivate(Sender: TObject);
    procedure _FontNumChange(Sender: TObject);
    procedure scrlbr1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btn_SaveBTNClick(Sender: TObject);
    procedure FontZoom1Change(Sender: TObject);
    procedure ScrollBar2Change(Sender: TObject);
    procedure img1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure _ImportBMPClick(Sender: TObject);
    procedure _ClrSymClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure _FontChooseChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  // терминология взята из http://wiki.scummvm.org/index.php/SAGA/Datafiles/Bitmap_Font
  c_height: Integer; // Maximum character height
  c_width: Integer; // Maximum character width
  row_length: Integer; // Font data row length (in bytes)
  FontIndex: array[0..255] of Integer; // Byte index into character data
  FontWidth: array[0..255] of Integer; // Character width
  FontFlag: array[0..255] of Integer; // Unknown character flag (either 0 or 1)
  FontTracking: array[0..255] of Integer; // Character tracking value

  buf: PByteArray;

  SymbolArray: array[0..100, 0..10000] of byte;

  FontStart: LongInt; // смещение начало структуры шрифта

  OverHead: Integer; // перерасход байт

  GlobalFontBitmap: array[0..100, 0..10000] of integer; // прямоугольник всех шрифтов

  BufFileSize: LongInt; // размер scream.res

  // таблицы смещений блоков и их размеры из scream.res
  GlobalOffset: array[0..1272] of LongWord;
  GlobalSizes: array[0..1272] of LongWord;
  //bufRus : PByteArray;
  {
Followed by a block of (row_length * c_height) bytes of font data.
If char *font_data points to the beginning of the font data block, then the following formula will
     access the data for a particular character:
font_data + (row_length * y)
where y is the row value; each character has c_height rows.
 Each character is ((width - 1) / 8) + 1 bytes wide. A set bit corresponds to a set pixel.
}

//  const FONT_START=$6082;//24706; { было 24572}
//  const FONT_HEIGHT=17;
//  const WIDTH_START=$5D1D;//23837;

const R1Start = $5AF6; // Начало структуры шрифта диалогов
  //const R3Start=$4106; // начала структуры маленького шрифта
const R3Start = $DE6;
const FontHeaderSize = 1286; // размер заголовка всех шрифтов

implementation

function getDWORD(offset: LongWord; buf: PByteArray): LongInt;
begin
  Result := buf[offset + 0] + 256 * buf[offset + 1] + 256 * 256 * buf[offset + 2] + 256 * 256 * 256 * buf[offset + 3];
end;

// пишем 4 байта, DWORD в байт-буфер, формат памяти LE
// offset - куда пишем, отсчет от нуля
// number - число, которое пишем
// buf - байт буфер

procedure WriteDWORD(offset: LongWord; number: LongWord; var buf: PByteArray);
var
  byte0, byte1, byte2, byte3: Byte;
begin
 //Пишем смещение блока
  BYTE3 := Trunc(number / (256 * 256 * 256));
  BYTE2 := Trunc((number - BYTE3 * 256 * 256 * 256) / (256 * 256));
  BYTE1 := Trunc((number - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256) / (256));
  BYTE0 := number - BYTE1 * 256 - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256;

  buf[offset + 0] := byte0;
  buf[offset + 1] := byte1;
  buf[offset + 2] := byte2;
  buf[offset + 3] := byte3;
end;

procedure ShowABC;
var
  k, i, j, col, cbyte, DataStart: longint;
begin
  DataStart := FontStart + FontHeaderSize;
   // Текущий байт раскладываем в биты, где каждый бит - это пиксель квадрата всего шрифта
  for i := 0 to (c_height - 1) do
    for j := 0 to (row_length - 1) do
    begin
      cbyte := buf[DataStart + i * row_length + j];

      for k := 7 downto 0 do
      begin
        // 48 = 30h = 0
        // 49 = 31h = 1
        if char($30 + (cbyte and 1)) = '1' then
          GlobalFontBitmap[i, j * 8 + k] := 255 * 255
        else
          GlobalFontBitmap[i, j * 8 + k] := 0;

        cbyte := cbyte shr 1;
      end;
    end;

  k := 0;
  col := 255;
  for i := 0 to (c_height - 1) do
    for j := 0 to (row_length * 8 - 1) do
    begin
      form1.imgFontImage.Canvas.Pixels[j, i] := GlobalFontBitmap[i, j];
      form1.imgFontImage.Canvas.Pixels[j, c_height] := col;
      if (k < 8) then
      begin
        form1.imgFontImage.Canvas.Pixels[j, c_height] := col;
        inc(k);

        if (k >= 8) then
        begin
          if (col = 200 * 200) then
          begin
            col := 255;
            k := 0;
            Continue;
          end;

          if (col = 255) then
          begin
            col := 200 * 200;
            k := 0;
            Continue;
          end;
        end;
      end;
    end;
end;

procedure ShowSymbol(symnum: Integer); // рисует символ
var
  i, j, d, fontnum: Integer;
begin
  fontnum := Form1._fontnum.position;
  Form1.img1.Picture := nil;

  d := 24;
  if FontWidth[fontnum] <= 8 then d := 8;
  if ((FontWidth[fontnum] <= 16) and (FontWidth[fontnum] > 8)) then d := 16;

  Form1.img1.Width := d;
  Form1.img1.Height := c_height;

  for i := 0 to (c_height - 1) do
    for j := 0 to (FontWidth[symnum] - 1) do
      Form1.img1.Canvas.Pixels[j, i] := GlobalFontBitmap[i, FontIndex[symnum] * 8 + j];

  Form1.img1.Canvas.Refresh;
end;


// Глава 1, заполняем данные
procedure InitFont(fontnum: Integer);
var
  f: file of Byte;
  i, j, k, k2, off1: LongInt;
  cbyte: integer; // текущий байт в масиве данных шрифта
  DataStart: LongInt; // FontStart + длина заголовка 1286 байт = DataStart
  col: LongInt;
begin
  FileMode := fmShareDenyNone; // права доступа отключить ругань
  AssignFile(f, 'scream.res');
  Reset(f);

  BufFileSize := FileSize(f);
  GetMem(Buf, BufFileSize); // выделяем память буфферу
  Blockread(f, Buf[0], BufFileSize); // читаем весь файл туда

 // заполняем таблицу смещений и размеров блоков
 //GlobalOffset : array [0..1272] of LongWord;
 //GlobalSizes  : array [0..1272] of LongWord;
 // берем указатель на таблицу
  off1 := buf[BufFileSize - 8] + 256 * buf[BufFileSize - 7] + 256 * 256 * buf[BufFileSize - 6] + 256 * 256 * 256 * buf[BufFileSize - 5];
  for i := 0 to 1272 do
  begin
    GlobalOffset[i] := getdword(off1 + i*8, Buf);
    GlobalSizes[i] := getdword(off1 + i*8 + 4, buf);
//    inc(off1, 8);
  end;

  if fontnum = 1 then FontStart := R3Start;
  if fontnum = 2 then FontStart := R1Start;

 // читаем высоту шрифта
  c_height := buf[FontStart + 0] + 256 * buf[FontStart + 1];
 // Выводим тут же
  Form1._c_height.Value := c_height;

 // читаем ширину шрифта
  c_width := buf[FontStart + 2] + 256 * buf[FontStart + 3];

 // читаем длину ряда
  row_length := buf[FontStart + 4] + 256 * buf[FontStart + 5];
  form1._row_length.Value := row_length;

 // читаем FontIndex
  for i := 0 to 255 do
  begin
    FontIndex[i] := buf[FontStart + 6 + i * 2] + 256 * buf[FontStart + 6 + i * 2 + 1];
    FontWidth[i] := buf[FontStart + 6 + 512 + i];
    FontFlag[i] := buf[FontStart + 6 + 512 + 256 + i];
    FontTracking[i] := buf[FontStart + 6 + 512 + 256 + 256 + i];
  end;

  // Создаем GlobalFontMap
  // чистим
  for i := 0 to 99 do
    for j := 0 to 9999 do
      GlobalFontBitmap[i, j] := 0;
  //

  // Создаем картинку текущего шрифта
  // Читаем (row_length * c_height) байт данных с адреса 45FCh в scream.res
  // Длина заголовка шрифта 1286 байт, поэтому 1286+FontStart = DataStart
 // for i:=0 to (row_length * c_height) do
   //begin
  DataStart := FontStart + FontHeaderSize;

   //j:=0;

  ShowABC;

 // прорисовка полоски с трекингом
  for k := 0 to 255 do
    for j := 0 to (FontTracking[k] - 1) do
      form1.imgFontImage.Canvas.Pixels[FontIndex[k] * 8 + j, c_height + 1] := 55 * 155 * 155;

  CloseFile(f);
end;

{$R *.dfm}

// Глава0, инициализируем массив из описания SAGA fonts на scummvm

procedure TForm1.FormActivate(Sender: TObject);
begin
  OverHead := 0; // пока что перерасхода нет
  _FontChooseChange(Sender);
end;

procedure TForm1._FontNumChange(Sender: TObject);
var
  i, j, fontnum: Integer;
begin
  //ScrollBar1.Position от 0 до 255, код символа
  fontnum := Form1._FontNum.Position;

  ShowSymbol(fontnum);

  ScrollBar2Change(Sender);
//ReadSYMBOL(form1.ScrollBar1.Position);

  Form1.TMemoLOG.Lines.Clear;
  Form1.TMemoLOG.Lines.Add('Код символа = ' + inttostr(fontnum));
  Form1.TMemoLOG.Lines.Add('c_height = ' + inttostr(c_height));
  Form1.TMemoLOG.Lines.Add('c_width = ' + inttostr(c_width));
  Form1.TMemoLOG.Lines.Add('row_length = ' + inttostr(row_length));

  Form1.TMemoLOG.Lines.Add('FontIndex[' + inttostr(fontnum) + '] = ' + inttostr(FontIndex[fontnum]));
  Form1.TMemoLOG.Lines.Add('FontWidth[' + inttostr(fontnum) + '] = ' + inttostr(FontWidth[fontnum]));
  Form1.TMemoLOG.Lines.Add('FontFlag[' + inttostr(fontnum) + '] = ' + inttostr(FontFlag[fontnum]));
  Form1.TMemoLOG.Lines.Add('FontTracking[' + inttostr(fontnum) + '] = ' + inttostr(FontTracking[fontnum]));

  Form1.TMemoLOG.Lines.Add('Символ = ' + chr(fontnum));


  _FontWidth.Value := FontWidth[fontnum];
  _FontFlag.Value := FontFlag[fontnum];
  _FontTracking.Value := FontTracking[fontnum];
  _FontIndex.Value := FontIndex[fontnum];
end;

procedure TForm1.scrlbr1Change(Sender: TObject);
begin
  Form1.img1.Picture := nil;
  Form1.img1.Canvas.Refresh;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeMem(buf);
end;

procedure TForm1.btn_SaveBTNClick(Sender: TObject);
var
  f: file of Byte;
  datastart, i, j, d, dH, off1, size1, off2, DW1: LongInt;
  ByteWide, fontnum, LOBYTE, HIBYTE: integer;
  fsize: LongWord;
  BYTE0, BYTE1, BYTE2, BYTE3: Byte;
begin
  datastart := FontStart + FontHeaderSize;

  for i := 0 to 99 do
    for j := 0 to 999 do
      SymbolArray[i, j] := 0;

  for i := 0 to (c_height - 1) do
    for j := 0 to (row_length - 1) do
    begin
      SymbolArray[i, j] := buf[datastart + i * row_length + j];
      buf[datastart + i * row_length + j] := 0; //
    end;

  fontnum := _fontnum.Position; // текущий код символа

 // записуем
  AssignFile(f, '.\fontout\scream.res');
  Rewrite(f);

  // Сохраняем параметры
  FontWidth[fontnum] := _FontWidth.Value;
  FontFlag[fontnum] := _FontFlag.Value;
  FontTracking[fontnum] := _FontTracking.Value;
  FontIndex[fontnum] := _FontIndex.Value;

  // Записываем назад row_length
  d := _row_length.Value - row_length; // дельта сдвига
  row_length := _row_length.Value;
  HIBYTE := trunc(row_length / 256); // Старший байт из WORD
  LOBYTE := row_length - 256 * HIBYTE; // Младший байт WORD, row_length уже с новой длиной
  buf[FontStart + 4] := LOBYTE; // младщий байт
  buf[FontStart + 5] := HIBYTE; // старший байт

  // Записываем назад c_heigth
  c_height := Form1._c_height.Value;
  HIBYTE := trunc(c_height / 256); // Старший байт из WORD
  LOBYTE := c_height - 256 * HIBYTE; // Младший байт WORD, c_height уже с новой длиной
  buf[FontStart + 0] := LOBYTE;
  buf[FontStart + 1] := HIBYTE;

 // Сбрасываем массивы в буфер перед отправкой в файл
  for i := 32 to 255 do
  begin
    HIBYTE := trunc(FontIndex[i] / 256);
    LOBYTE := FontIndex[i] - 256 * HIBYTE;
    // Записываем назад индексы
    buf[FontStart + 6 + i * 2 + 1] := HIBYTE; // старший байт
    buf[FontStart + 6 + i * 2] := LOBYTE;

    buf[FontStart + 6 + 512 + i] := FontWidth[i];
    buf[FontStart + 6 + 512 + 256 + i] := FontFlag[i];
    buf[FontStart + 6 + 512 + 256 + 256 + i] := FontTracking[i];
  end;

  for i := 0 to (c_height - 1) do
    for j := 0 to (row_length - 1) do
      buf[datastart + i * (row_length) + j] := SymbolArray[i, j];

// патчим перед записью шрифт
// вместо смещения шрифта №5 пишем указатель на шрифт №2, там находится шрифт
// в блок записать смещение  0de6 и размер 7526 байт
// смещение на таблицу смещений и размеров
  off1 := buf[BufFileSize - 8] + 256 * buf[BufFileSize - 7] + 256 * 256 * buf[BufFileSize - 6] + 256 * 256 * 256 * buf[BufFileSize - 5];

  DW1 := $0DE6;
 //Пишем смещение блока

  BYTE3 := Trunc(DW1 / (256 * 256 * 256));
  BYTE2 := Trunc((DW1 - BYTE3 * 256 * 256 * 256) / (256 * 256));
  BYTE1 := Trunc((DW1 - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256) / (256));
  BYTE0 := DW1 - BYTE1 * 256 - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256;
 // 6*8 - это 6 блок, состоящий из 2х DWORD, смещение и размер
  buf[off1 + 6 * 8 + 0] := byte0;
  buf[off1 + 6 * 8 + 1] := byte1;
  buf[off1 + 6 * 8 + 2] := byte2;
  buf[off1 + 6 * 8 + 3] := byte3;

  DW1 := $1D66; // размер 7526
 // Пишем размер блока
  BYTE3 := Trunc(DW1 / (256 * 256 * 256));
  BYTE2 := Trunc((DW1 - BYTE3 * 256 * 256 * 256) / (256 * 256));
  BYTE1 := Trunc((DW1 - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256) / (256));
  BYTE0 := DW1 - BYTE1 * 256 - BYTE2 * 256 * 256 - BYTE3 * 256 * 256 * 256;
 // 6*8 - это 6 блок, состоящий из 2х DWORD, смещение и размер
  buf[off1 + 6 * 8 + 4] := byte0;
  buf[off1 + 6 * 8 + 5] := byte1;
  buf[off1 + 6 * 8 + 6] := byte2;
  buf[off1 + 6 * 8 + 7] := byte3;

  BlockWrite(f, buf[0], BufFileSize);
  CloseFile(f);

  ShowSymbol(fontnum);
  ShowABC;
  FontZoom1Change(sender);
  ScrollBar2Change(sender);

  TMemoLOG.Lines.Add('saved');
end;

procedure TForm1.FontZoom1Change(Sender: TObject);
begin
  Form1.imgFontImage.Height := form1.FontZoom1.Position * c_height;
  form1.imgFontImage.Width := form1.FontZoom1.Position * row_length;
end;

procedure TForm1.ScrollBar2Change(Sender: TObject);
begin
  Form1.img1.Height := form1.ScrollBar2.Position * c_height;
  form1.img1.Width := form1.ScrollBar2.Position * c_width; //FontWidth[ScrollBar1.Position];
end;

//set a particular bit as 1
function Set_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
  Result := aValue or (1 shl Bit);
end;

//Enable o disable a bit
function xor_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
  Result := (aValue xor (1 shl Bit));
end;

procedure TForm1.img1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  kx, ky, d, xpos, ypos, color, fontnum, datastart, Byte1: Integer;
  f: file of Byte;
  Fsize: LongWord;
begin
  fontnum := _fontnum.Position;
  datastart := FontStart + FontHeaderSize;

  d := 24;
  if FontWidth[fontnum] <= 8 then d := 8;
  if ((FontWidth[fontnum] <= 16) and (FontWidth[fontnum] > 8)) then d := 16;

  kx := trunc(form1.img1.Width / d);
  ky := trunc(Form1.img1.Height / c_height);

  xpos := Trunc(X / kx);
  ypos := Trunc(Y / ky);

  if (Button = mbLeft) then
  begin
    color := 255 * 255; // карандаш
  end;

  if (Button = mbRight) then
  begin
    color := 0; // ластик
  end;

// рисуем точку
  form1.img1.Canvas.Pixels[xpos, ypos] := color;

// Пишем точку прямо в байт ряда
// Если символ = 1 байт шириной
  if (d = 8) then
  begin
    byte1 := buf[datastart + ypos * row_length + FontIndex[fontnum]];

    if color = 255 * 255 then byte1 := Set_a_Bit(byte1, 7 - xpos);
    if color = 0 then Byte1 := xor_a_Bit(byte1, 7 - xpos);

    buf[datastart + ypos * row_length + FontIndex[fontnum]] := byte1;
  end;

// если символ 2х байтный
  if (d = 16) then
  begin
    if (xpos <= 7) then byte1 := buf[datastart + ypos * row_length + FontIndex[fontnum]]
    else byte1 := buf[datastart + ypos * row_length + FontIndex[fontnum] + 1];

    if ((color = 255 * 255) and (xpos <= 7)) then byte1 := Set_a_Bit(byte1, 7 - xpos);
    if ((color = 255 * 255) and (xpos >= 8)) then byte1 := Set_a_Bit(byte1, 15 - xpos);

    if ((color = 0) and (xpos <= 7)) then Byte1 := xor_a_Bit(byte1, 7 - xpos);
    if ((color = 0) and (xpos >= 8)) then Byte1 := xor_a_Bit(byte1, 15 - xpos);

    if (xpos <= 7) then buf[datastart + ypos * row_length + FontIndex[fontnum]] := byte1
    else buf[datastart + ypos * row_length + FontIndex[fontnum] + 1] := byte1;
  end;

 // если символ 3х байтный
{
if (d=24) then
 begin
   if ( xpos <= 7 ) then byte1 := buf[datastart + ypos * row_length + FontIndex[fontnum]]
                     else byte1 := buf[datastart + ypos * row_length + FontIndex[fontnum] + 1];

   if ( (color=255*255) and (xpos <= 7) ) then byte1 := Set_a_Bit(byte1, 7 - xpos);
   if ( (color=255*255) and (xpos >= 8) and (xpos<=15) ) then byte1 := Set_a_Bit(byte1, 15 - xpos);
   if ( (color=255*255) and (xpos >= 16) ) then byte1 := Set_a_Bit(byte1, 23 - xpos);

   if ( (color=0) and (xpos<=7)) then Byte1 := xor_a_Bit(byte1, 7 - xpos);
   if ( (color=0) and (xpos>=8) and (xpos<=15)) then Byte1 := xor_a_Bit(byte1, 15 - xpos);
   if ( (color=0) and (xpos>=16)) then Byte1 := xor_a_Bit(byte1, 23 - xpos);

   if (xpos <= 7) then buf[datastart + ypos * row_length + FontIndex[fontnum]] := byte1
                    else buf[datastart + ypos * row_length + FontIndex[fontnum] + 1] := byte1;
 end;
}

  ShowABC;
  ShowSymbol(fontnum);
  ScrollBar2Change(sender);
end;

procedure TForm1._ImportBMPClick(Sender: TObject);
var
  bmpFont: PByteArray;
  GlobalFileSize, i, j, symIndx, k: longint;
  fin: file of Byte;
  bmpH, bmpW, bmpData, col1, col2, colCMP1, colCMP2, PixCol, lastPos, symoffsetinbmp, sym, cp1251pos: Integer;
  // массив ширин шрифта из bmp
  bmpFont_width: array[0..65] of Integer;
  fname: string;

  byte1, ind1, delta, h: integer;

  Button: TMouseButton;
  Shift: TShiftState;

const
  bmpHoffset = $16; // смещение в BMP от нуля, высота BMP
  bmpWoffset = $12; // смещение в BMP от нуля, ширина BMP
  bmpDataOffset = $0A; // указатель начала raw данных в bmp
begin
  if FontStart = R1Start then
  begin
    colCMP1 := 1;
    colCMP2 := 2;
    h := 2; // ряд для сканирования
    fname := '.\finalfonts\R1-final18.bmp';
  end;

  if FontStart = R3Start then
  begin
    colCMP1 := $FF;
    colCMP2 := 8;
    PixCol := 0;
    h := 8;
    fname := '.\finalfonts\R3-final8.bmp';
  end;

  FileMode := fmShareDenyNone; // права доступа отключить ругань
  AssignFile(fin, fname);
  Reset(fin);
  GlobalFileSize := FileSize(fin);
  GetMem(bmpFont, GlobalFileSize); // выделяем память буфферу
  Blockread(fin, bmpFont[0], GlobalFileSize); // читаем весь файл туда

  bmpH := getDWORD(bmpHoffset, bmpFont);
  bmpW := getDWORD(bmpWoffset, bmpFont);
  bmpData := getDWORD(bmpDataOffset, bmpFont); // =0436h = 1078 начало raw даных

  if (bmpH > c_height) then
  begin
    Form1.TMemoLOG.Lines.Add('Несовпадение высот');
   //Exit;
  end;
 // заполняем массив ширин из BMP файла
  symIndx := 0; // индекс символа, в BMP идет А-Яа-я
  lastPos := 0;

 // ищем границы букв и заполняю таблицу ширин символов из BMP
  for j := 0 to (bmpW - 2) do
  begin
    col1 := bmpFont[bmpData + h * bmpW + j]; // первого ряда мне оказалось достаточно
    col2 := bmpFont[bmpData + h * bmpW + j + 1];
    // белый фон = 255 , $FF
    // зеленый фон = 250 , $FA
    if (((col1 = colCMP1) and (col2 = colCMP2))
      or
      ((col1 = colCMP2) and (col2 = colCMP1))) then
    begin
      bmpFont_width[symIndx] := j - lastPos + 1; // записываем ширину
      lastPos := j + 1; // смещаем последний указатель
      inc(symIndx);
    end;
  end;
 // заполняю ширину последней буквы я маленькой
  bmpFont_width[65] := bmpW - lastPos;

 // сравниваем ширины текущего символа и из BMP
 // затем высчитываем смещение в raw bmp тек символа и заполняем массив новой буквой
 // диапазоны font_width[form1.fontnum.Position] 32-255 и bmpFont_width[65] 0-65
 //Form1.Memo1.Lines.Add(IntToStr(font_width[form1.fontnum.Position]));  // ширина, 7 для Ё
 //Form1.Memo1.Lines.Add(IntToStr(form1.fontnum.Position+1));            // позиция в вин, 167+1
 //Form1.Memo1.Lines.Add(IntToStr(bmpFont_width[7-1]));
 // form1.fontnum.Position + 1 = 168 - это Ё, 7 буква в алфавите BMP
 // form1.fontnum.Position+1 = 184 - это ё, 33+7 в алфавите BMP
 // 192 - А (1 буква)
 // 223 - Я (33 буква)
 // 224 - а (33 + 1 буква)
 // 255 - я (33 + 33 буква)
  sym := 0;
  cp1251pos := form1._fontnum.Position;

  if (cp1251pos = 168) then sym := 7; // 7 буква Ё
  if (cp1251pos = 184) then sym := 33 + 7; // 33 + 7 буква ё
  if ((cp1251pos >= 192) and (cp1251pos <= 197)) then sym := cp1251pos - 191;
  if ((cp1251pos >= 198) and (cp1251pos <= 223)) then sym := cp1251pos + 1 - 191;

  if ((cp1251pos >= 224) and (cp1251pos <= 229)) then sym := cp1251pos - 190;
  if ((cp1251pos >= 230) and (cp1251pos <= 255)) then sym := cp1251pos + 1 - 190;

  if sym = 0 then Exit; // не выбрана русская буква

// проверка ширин и корректировка
  while ((FontWidth[form1._fontnum.Position] <> bmpFont_width[sym - 1])) do
  begin
    Form1._FontWidth.Value := bmpFont_width[sym - 1];
    btn_SaveBTNClick(Sender);
  end;

  if ((FontWidth[form1._fontnum.Position] = bmpFont_width[sym - 1])) then
  begin
    Form1.TMemoLOG.Lines.Add('Ширина из CFT и BMP файла совпадают.');

    symoffsetinbmp := 0; // ищем смещение начала изображения
    for i := 0 to (sym - 2) do // -1 потому что с нуля, еще -1 потому что ДО буквы, а не после
      inc(symoffsetinbmp, bmpfont_width[i]); // нашли смещение-начало буквы, сумма ширин букв идущих до
  end;

  // заполняем букву из бмп в font_array
  for i := 0 to (c_height - 1) do // координата Y ноль сверху слева
  begin
    byte1 := 0;
    ind1 := 128;
    delta := 0;

    for j := 0 to (bmpFont_width[sym - 1] - 1) do // координата X
    begin //начало изображения + смещение до буквы + ряд Y + текущий X
      col1 := bmpFont[bmpData + symoffsetinbmp + i * bmpW + j];
       // $66 - коричневый
      if (col1 = 0) then byte1 := byte1 + ind1;

      ind1 := ind1 shr 1; // ind1=0 значит байт отсчитали
      if (ind1 = 0) then
      begin
        buf[FontStart + FontHeaderSize + i * (row_length) + FontIndex[_FontNum.Position] + delta] := byte1;
        ind1 := 128;
        byte1 := 0;
        inc(delta);
      end;
    end;

    if ind1 <> 128 then
      buf[FontStart + FontHeaderSize + i * row_length + FontIndex[_FontNum.Position] + delta] := byte1;
  end;
   // сохраняем
  btn_SaveBTNClick(sender);
   // обновляем картинку
  ShowSymbol(_FontNum.Position);
  ScrollBar2Change(sender);

  CloseFile(fin);
  FreeMem(bmpFont); // освободить, закрыть и уйти.
end;

procedure TForm1._ClrSymClick(Sender: TObject);
var
  i, j: Integer;
begin
  for i := 0 to (c_height - 1) do
    for j := 0 to (FontWidth[Form1._FontNum.Position] - 1) do
      buf[FontStart + FontHeaderSize + i * row_length + FontIndex[Form1._FontNum.Position]] := 0;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i, j, num, k, i2: LongInt;
  BlockStart1, BlockSize1, ResBlockStart, ResBlockSize, off1: LongInt;
  ANSIstr1: AnsiString;
  UTF8str1: UTF8String;
  fout: TextFile;
  tmpStr1: string;

  byte0, byte1, byte2, byte3: Byte;
// Нужно построить массив слов и таблицу смещений
  namesENG: array[0..522] of string;
  namesRUS: array[0..522] of string;
// таблица смещений блока с текстом, нумерация ноль начало блока
  offsetTable: array of Word; // таблица смещений
  translationTable: array of string; // таблица перевода, оба массива - это один из маленьких блоков
  fin: TextFile;
// походу нужны еще 2 таблицы, смещение больших блоков и размер

// байтовый блок с переводом и его новый размер
  TextByteBlock: array of Byte;
  TextBlockSize, NewSize: LongInt;
  LOBYTE, HIBYTE: Byte; // старший и младший байты в WORD
  f2: file of Byte;
// номера блоков где я нашел текст, возможно потом дополню
  bufRus: PByteArray;
  DW1: LongWord;
  index: LongWord;
T1, T2 : TTime;
MegaStringENG : string;

const TextBlocksNUM: array[0..91] of Integer = (
    22, 41, 45, 120, 129, 137, 148, 161, 173, 183,
    191, 205, 217, 231, 249, 259, 274, 284, 292, 302, 312,
    321, 328, 332, 392, 401, 412, 421, 430, 439, 449,
    468, 488, 503, 512, 519, 523, 577, 586, 596, 604,
    612, 620, 628, 638, 646, 653, 663, 672, 679, 683,
    719, 728, 737, 746, 755, 764, 773, 789, 800, 807,
    811, 848, 858, 873, 882, 891, 901, 910, 920, 936,
    945, 954, 963, 970, 974, 1036, 1051, 1063, 1075, 1090,
    1100, 1112, 1130, 1142, 1151, 1160, 1167, 1171, 1235, 1258,
    1266);
begin
 MegaStringENG := '';
 // заполняем таблицу английских имен
  k := 0;
  AssignFile(fin, '.\files\ItemNames.txt');
  Reset(fin);
  while (not (Eof(fin))) do
  begin
    Readln(fin, ansistr1);
    if (ANSIstr1 <> '') then
    begin
      namesENG[k] := ANSIstr1;
      MegaStringENG := MegaStringENG + ANSIstr1 + #0;
      Inc(k);
    end;
  end;
  CloseFile(fin);

 // заполняем таблицу русских названий предметов
  k := 0;
  AssignFile(fin, '.\files\Названия_предметов,_имена.txt');
  Reset(fin);
  while (not (Eof(fin))) do
  begin
    Readln(fin, utf8str1);
    while (UTF8str1 = '') do
      Readln(fin, UTF8str1);

    Ansistr1 := Trim(Utf8ToAnsi(UTF8str1));
    if Ansistr1[1] = '?' then Delete(Ansistr1, 1, 1);
    if ANSIstr1 <> '' then namesRUS[k] := ANSIstr1;
    Inc(k);
    if k > 522 then Break;
  end;
  CloseFile(fin);

 // смещение по номеру (блока-1) где хранится адрес начала данных
 //ResBlockStart := getDWORD(BlockStart1 + 21*8, buf);
 // размер блока
 //ResBlockSize := getDWORD(BlockStart1 + 21*8 + 4, buf);

 // начинаем обход текста по номерам блоков
 // в каждом блоке идет сперва таблица смещений,
 // потом текст.
 // сейчас i = 0.. 91
 //AssignFile (fout, '.\temp\ItemNames.txt');
 //Rewrite (fout);
  for i := 0 to (Length(TextBlocksNUM) - 1) do
  begin
   T1 := Now;  // время до начала цикла
   // смещение начала таблицы смещений
    BlockStart1 := getDWORD(BufFileSize - 8, buf);
   // количество блоков
    BlockSize1 := getDWORD(BufFileSize - 4, buf);

   // смещение по номеру (блока-1) где хранится адрес начала данных
    ResBlockStart := getDWORD(BlockStart1 + (TextBlocksNUM[i] - 1) * 8, buf);
   // размер блока
    ResBlockSize := getDWORD(BlockStart1 + (TextBlocksNUM[i] - 1) * 8 + 4, buf);

   // количество слов в блоке
    num := Trunc((Buf[ResBlockStart + 0] + 256 * Buf[ResBlockStart + 1]) / 2);
   // таблица смещений в блоке
    SetLength(offsetTable, (num - 1));
    SetLength(translationTable, (num - 1));
   // последнее смещение равно длине всего блока, поэтому -1, так как с нуля, и -1 минус последний блок - это размер
    for j := 0 to (num - 2) do
    begin
      ANSIstr1 := '';
      k := 0;
      off1 := buf[ResBlockStart + j * 2] + 256 * buf[ResBlockStart + j * 2 + 1];
      offsetTable[j] := off1; // записали смещение оригинального блока

      while (buf[ResBlockStart + off1 + k] <> 0) do
      begin
        ANSIstr1 := ANSIstr1 + chr(Buf[ResBlockStart + off1 + k]);
        inc(k);
      end;
      translationTable[j] := ANSIstr1; // пусть будет англ, если есть перевод, подставляем его
     // вынули из блока слово
     // слово может быть пустым, состоит из 2х байт, ноль слово и ноль на конце, 00 00
      if ANSIstr1 = '' then
      begin
        translationTable[j] := ''; //#0 + #0; записали пустоту
        Continue;
      end;

     // пишем слово в лог
     // ищем это слово в таблице и берем его перевод, составляем блок слов с переводом
      for i2 := 0 to (Length(namesENG) - 1) do
      begin
        tmpStr1 := namesEng[i2];
        if (ANSIstr1 = tmpStr1) then
        begin
          k := Pos(ANSIstr1, MegaStringENG);

          tmpStr1 := namesRUS[i2];
          translationTable[j] := tmpStr1;
          Break;
        end;
      end;

     //writeln (fout, ansistr1);
    end;

   // здесь имеем translationTable[] и offsetTable[]
   // в translationTable[] могут быть пустые строки - это два байта нуля, 00 00
   // в offsetTable[] если это пустая строка, то +2, последнего элемента нет в таблице
   // это длина блока (мини), тип WORD 2 байта.
   // заголовок смещений, вся длина блока, блока текста с нулем в конце строки.

   // собираем новый миниблок байт TextByteBlock[] с русским переводом, потом его интегрируем в общий buf файл
   // в котором еще таблицу смещений править
   // считаем размер нового TextByteBlock[]
    TextBlockSize := 0;
   // +1 байт ноль в конец
    for j := 0 to (Length(translationTable) - 1) do
      TextBlockSize := TextBlockSize + Length(translationTable[j]) + 1;

   // сосчитали длины строк, учли пустые строки и нули у всех на конце
   // теперь добавляем размер заголовка + 2 байта размер в конце таблицы смещений
    TextBlockSize := TextBlockSize + num * 2 + 2;
   // новый размер блока мини содержится в TextBlockSize, устанавливаем размер
    SetLength(TextByteBlock, TextBlockSize);
   // на всякий случай чистим, хотя он инициализируется нулями
    for j := 0 to (TextBlockSize - 1) do
      TextByteBlock[j] := 0;
   // всё готово для сборки блока.
   // собираем вольтрона, руки и ноги
    i2 := 0;
    for j := 1 to (num - 2) do
    begin
      i2 := Length(translationTable[j - 1]) + 1; // плюс ноль на конце
      if translationTable[j - 1] = '' then i2 := 2; // для пустых строк длина 2, 0 + 0 на конце
     // текущее смещение = предыдущее + длина предыдущего слова с учетом пустых строк
      offsetTable[j] := offsetTable[j - 1] + i2;
    end;
   // запишем таблицу смещений в байтовый массив textBlock
    for j := 0 to (num - 2) do
    begin
      HIBYTE := Trunc(offsetTable[j] / 256);
      LOBYTE := offsetTable[j] - HIBYTE * 256;

      TextByteBlock[j * 2] := LOBYTE;
      TextByteBlock[j * 2 + 1] := HIBYTE;
    end;
   // записываем 2 байта длина блока
    HIBYTE := Trunc(TextBlockSize / 256);
    LOBYTE := TextBlockSize - 256 * HIBYTE;
    TextByteBlock[num * 2 - 2] := LOBYTE;
    TextByteBlock[num * 2 - 1] := HIBYTE;
   // записываем русский перевод
    for j := 0 to (num - 2) do
      for i2 := 1 to (Length(translationTable[j])) do
      begin
        tmpStr1 := translationTable[j];
        TextByteBlock[offsetTable[j] + i2 - 1] := ord(tmpStr1[i2]);
      end;

  // имеем переведенный и собранный байтовый блок TextByteBlock[]
  // размером TextBlockSize
  // начало и размер оригинального блока
  // ResBlockStart, ResBlockSize
  //
  // оригинальный блок buf[] размерм BufFileSize

  // Разница размеров нового и старого блоков
    NewSize := BufFileSize + (TextBlockSize - ResBlockSize);
    GetMem(bufRus, NewSize); // выделяем память буфферу
   // копируем начало
   move (buf[0], bufRus[0], ResBlockStart);
   // for j := 0 to (ResBlockStart - 1) do
   //   bufRus[j] := Buf[j];

  // копируем новый переведенный блок
  Move(textbyteblock[0], bufRus[ResBlockStart], TextBlockSize);
  //  for j := 0 to (TextBlockSize - 1) do
  //    bufRus[ResBlockStart + j] := TextByteBlock[j];

  // копируем конец
  i2 := ResBlockStart + TextBlockSize;
  Move(buf[ResBlockStart + ResBlockSize], bufRus[ResBlockStart + TextBlockSize], BufFileSize - (ResBlockStart + ResBlockSize) );
{    for j := (ResBlockStart + ResBlockSize) to (BufFileSize - 1) do
    begin
      bufRus[i2] := buf[j];
      inc(i2);
    end;
}
  // надо подготовить таблицу смещений и размеров scream.res
  //GlobalOffset : array [0..1272] of LongWord;
  //GlobalSizes  : array [0..1272] of LongWord;
  // смещение по номеру (блока-1) где хранится адрес начала данных
  //ResBlockStart := getDWORD(BlockStart1 + (TextBlocksNUM[i] - 1)*8, buf);
  // размер блока
  //ResBlockSize := getDWORD(BlockStart1 + (TextBlocksNUM[i] - 1)*8 + 4, buf);
    GlobalSizes[TextBlocksNUM[i] - 1] := TextBlockSize;

  // поправить смещения в таблице со следующего блока
    for j := TextBlocksNUM[i] to 1272 do
      GlobalOffset[j] := GlobalOffset[j - 1] + GlobalSizes[j - 1];

  // сбрасываем таблицу в буфер
  // смещение пишем
    off1 := NewSize - 1273 * 4 * 2 - 4 * 2;
    for j := 0 to 1272 do
    begin
      DW1 := GlobalOffset[j];
      WriteDWORD((off1 + j * 8), DW1, bufRus);

      DW1 := GlobalSizes[j];
      WriteDWORD((off1 + j * 8 + 4), DW1, bufRus);
    end;

   // еще правим указатель на таблицу
    DW1 := off1;
    WriteDWORD((NewSize - 8), DW1, bufRus);

   // патчим мелкий шрифт
   //Пишем смещение блока
    DW1 := $0DE6;
    WriteDWORD((off1 + 6 * 8), DW1, bufRus);

   // Пишем размер блока
    DW1 := $1D66; // размер 7526
    WriteDWORD((off1 + 6 * 8 + 4), DW1, bufRus);

   // переписать bufRus в buf;
    FreeMem(buf);
   // переносим новый буфер в старый с учетом новой длины
    GetMem(Buf, NewSize); // выделяем память буферу
    //buf := bufRus; // переносим
    Move(bufRus[0], buf[0], NewSize);
//    for j := 0 to (NewSize - 1) do
//      buf[j] := bufRus[j];

    // правим размер
    BufFileSize := NewSize;
    FreeMem(bufRus);

    T2 := Now;
    TMemoLOG.Lines.Add(IntToStr(i+1) + '/' + IntToStr(Length(TextBlocksNUM)) + ' - ' + FloatToStr(t2-t1));
//    Exit;
  end;

  TMemoLOG.Lines.add('done');

  AssignFile(f2, '.\temp\scream.res');
  Rewrite(f2);
  BlockWrite(f2, buf[0], BufFileSize);
  closefile(f2);

 //CloseFile (fout);
end;

procedure TForm1._FontChooseChange(Sender: TObject);
begin
  if _FontChoose.Position = 0 then
  begin
    FontStart := R3Start;
    InitFont(1);
  end;

  if _FontChoose.Position = 1 then
  begin
    FontStart := R1Start;
    InitFont(2);
  end;

  _FontNumChange(Sender);
  FontZoom1Change(sender);
  ScrollBar2Change(sender);
end;

end.

