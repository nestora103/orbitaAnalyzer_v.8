unit OrbitaAll;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, StdCtrls, Series, TeEngine, TeeProcs, Chart, ExtCtrls,
  Lusbapi, {Visa_h,} Math, Buttons, ComCtrls, xpman, DateUtils,
  MPlayer,iniFiles,StrUtils,syncobjs,ExitForm, Gauges;
//Lusbapi-���������� ��� ������ � ��� �20-10
//Visa_h-���������� ��� ������ � ����������� � �����������

const
  //���
  // ������� ����� ������
  ADCRATE: double = 10000.0; //3145.728
  // ���-�� �������� �������
  CHANNELSQUANTITY: WORD = $01;
  //������ ���������� ������(������ ���������� ����)
  FIFOSIZE = 2500000;
  //������ ������� ������. � ������ ������ �������� �������� ����� � 10-�� �������
  SIZEMASGROUP=2048;
  //���������� ������(������ ������ �������������� �� ���� ������)
  NUMBLOCK = 4;
  SIZEBLOCKPREF = 32;
  MAXHEADSIZE = 256;

  //M08,04,02,01
  // ������� ������� 1/2 ������� ����
  MARKMINSIZE = 3;
  MARKMAXSIZE = 4;
  //��� ����� ����� ����� ���������
  MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR = 1220;
  //���������� ����� ��������� �� 1 ��� �� ������
  NUMPOINTINTCOUT = 10;

  //�����. �������� � ������� ���
  NUM_BUS_ELEM=96;
  //����. ������� ���.
  BUS_MARKER_VAL=65535;
type
  TForm1 = class(TForm)
    GroupBox2: TGroupBox;
    GroupBox4: TGroupBox;
    OrbitaAddresMemo: TMemo;
    TimerOutToDia: TTimer;
    Memo1: TMemo;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    diaSlowAnl: TChart;
    Series1: TBarSeries;
    diaSlowCont: TChart;
    Series3: TBarSeries;
    gistSlowAnl: TChart;
    upGistSlowSize: TButton;
    downGistSlowSize: TButton;
    Series2: TLineSeries;
    fastDia: TChart;
    Series4: TBarSeries;
    fastGist: TChart;
    Series11: TFastLineSeries;
    upGistFastSize: TButton;
    downGistFastSize: TButton;
    tlmWriteB: TButton;
    Label2: TLabel;
    Panel2: TPanel;
    TrackBar1: TTrackBar;
    LabelHeadF: TLabel;
    fileNameLabel: TLabel;
    OpenDialog1: TOpenDialog;
    PanelPlayer: TPanel;
    play: TSpeedButton;
    pause: TSpeedButton;
    stop: TSpeedButton;
    TimerPlayTlm: TTimer;
    startReadACP: TButton;
    startReadTlmB: TButton;
    tlmPSpeed: TTrackBar;
    Label2x: TLabel;
    Labelx: TLabel;
    Labelx2: TLabel;
    timeHeadLabel: TLabel;
    orbTimeLabel: TLabel;
    OpenDialog2: TOpenDialog;
    propB: TButton;
    saveAdrB: TButton;
    TabSheet3: TTabSheet;
    busDia: TChart;
    busGist: TChart;
    Series5: TBarSeries;
    Series6: TLineSeries;
    TimerOutToDiaBus: TTimer;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Timer1: TTimer;
    tmrForTestOrbSignal: TTimer;
    gProgress1: TGauge;
    gProgress2: TGauge;
    procentFalseMF1: TLabel;
    procentFalseMG: TLabel;
    ts3: TTabSheet;
    tempDia: TChart;
    Series7: TBarSeries;
    tempGist: TChart;
    lnsrsSeries8: TLineSeries;
    upGistTempSize: TButton;
    downGistTempSize: TButton;
    procedure startReadACPClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure upGistSlowSizeClick(Sender: TObject);
    procedure downGistSlowSizeClick(Sender: TObject);
    procedure Series1Click(Sender: TChartSeries; ValueIndex: Integer;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TimerOutToDiaTimer(Sender: TObject);
    procedure upGistFastSizeClick(Sender: TObject);
    procedure downGistFastSizeClick(Sender: TObject);
    procedure tlmWriteBClick(Sender: TObject);
    procedure startReadTlmBClick(Sender: TObject);
    procedure Series4Click(Sender: TChartSeries; ValueIndex: Integer;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TimerPlayTlmTimer(Sender: TObject);
    procedure playClick(Sender: TObject);
    procedure pauseClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure stopClick(Sender: TObject);
    procedure tlmPSpeedChange(Sender: TObject);
    procedure propBClick(Sender: TObject);
    procedure saveAdrBClick(Sender: TObject);
    procedure Series5Click(Sender: TChartSeries; ValueIndex: Integer;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TimerOutToDiaBusTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure tmrForTestOrbSignalTimer(Sender: TObject);
    procedure Series7Click(Sender: TChartSeries; ValueIndex: Integer;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure upGistTempSizeClick(Sender: TObject);
    procedure downGistTempSizeClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  //����� ���. ���������� ��� ����������� �������� ������.
  TShortrArray = array[0..1] of array of SHORT;

  //��� �������� ������ (��� ������ �����)
  TDBufCircleArray = array[0..1] of array[1..SIZEMASGROUP*32] of word;

  Ttlm = class(TObject)
    //���� ���
    //PtlmFile:file of byte;
    //���������� ��� ������ � ������ ���
    PtlmFile: file;
    //��� ��������� ����� ��� �����
    fileName: string;
    //����� �������� ����� tlm � ������� unixtime
    msTime: cardinal;
    //����� ������������� �����
    blockNumInfile: Cardinal;
    //�����. ���� � �����
    wordNumInBlock: Cardinal;
    //����� � ������� ������� ������
    timeBlock: cardinal;
    //������1
    rez: cardinal;
    //������� �����
    prKPSEV: cardinal;
    //�������� ������� ����
    nowTime: TDateTime;
    //�
    hour: byte;
    //�
    minute: byte;
    //���
    sec: byte;
    //mc
    mSec: word;
    //mcs
    mcSec: byte;
    //������2
    rez1M08_04_02_01:word;
    rez1M16: byte;
    //���� ��������
    prSEV: byte;
    error: byte;
    //������3
    rez2: cardinal;
    //��� ������� � ��������� ������ � ���
    flagWriteTLM: boolean;

    //�������� ������ ��������� � ������� ������ � ���
    tlmHeadByteArray: array of byte;
    iTlmHeadByteArray: integer;

    //�������� ������ ��������� � ������� ������ � ���
    tlmBlockByteArray: array of byte;
    iTlmBlockByteArray: integer;

    //���� ������ ������� �����
    flagFirstWrite: boolean;
    //���� ��� �������� �����
    flagEndWrite: boolean;
    //������� ��� ��������� ���� � 1 ��
    iOneGC: integer;
    //���������� ��������� ���� � ���� ���
    countWriteByteInFile: int64;
    //���. �������� ������ �����. ����.
    precision: integer;
    stream: TFileStream;
    //���������� ������ ���. �� 1 ������
    tlmPlaySpeed: integer;
    //���� ������������� ��� ����������� ���������� �������
    fFlag: boolean;
    //���� ��� ����������� ����� ������ � ��� ��� ������������� ��
    tlmBFlag: boolean;
    //���������� ���� � ����� ���  � ����������� �� ���������������
    sizeBlock: integer;
    //�������� ������ �����
    //blockOrbArr: array  of byte;
    //�������� ������� ����� � ����������� �� ���������������
    arr1: array[0..131103] of byte;
    arr2: array[0..65567] of byte;
    arr3: array[0..32799] of byte;
    arr4: array[0..16415] of byte;
    arr5: array[0..8223] of byte;

    //������ �������� ��������� �����. ������. ������
    procedure WriteToFile(str: string); overload;
    //������ ������� �������� � ��������� ����� ���
    procedure WriteToFile(nullVal: byte); overload;
    //������ �������� ��������� � ������. ����. ������
    procedure WriteByteToByte(multiByteValue: cardinal); overload;
    procedure WriteByteToByte(multiByteValue: word); overload;
    procedure WriteByteToByte(multiByteValue: byte); overload;
    //����� �� ����� ���������� ��������� � ���� �����
    procedure OutTLMfileSize(numWriteByteInFile: int64; var numValBefore: integer);
    //������ ���������
    procedure WriteTLMhead;
    //������ ����� M16
    procedure WriteTLMBlockM16(msStartFile: cardinal);
    //������ ����� M08_04_02_01
    procedure WriteTLMBlockM08_04_02_01(msStartFile: cardinal);
    //������ ����� ������ � ������� ���. M16
    procedure WriteCircleM16;
    //������ ����� ������ � ������� ���. M08_04_02_01
    procedure WriteCircleM08_04_02_01;
    //���. ���� �������
    constructor CreateTLM;
    //������ ������ � ���
    procedure StartWriteTLM;
    //����� �������� �����
    procedure OutFileName;
    //���������� � ������ � ��� ������
    procedure BeginWork;
    //������ ����������� ���������� ������ ���. �����
    procedure ParseBlock(countBlock: word);
    //���� ������� ������
    procedure CollectOrbGroup;
    //���� ������� �����
    procedure CollectBlockTime;
    function ConvTimeToStr(t: cardinal): string;
  end;

  //��� �������� ������� ��� ������ �� ������
type
  channelOutParam = record
    //����� ������ ����� � ������� ������
    numOutElemG: integer;
    //��� �� ����. ������ ����� � ������� ������
    stepOutG: integer;
    //0-���������� �����. 1-���������� �����. 2-������� ���������
    adressType: short;
    //����� ���� � ��������, ��� �����. �������� ����������� ������.
    //0-���������� �����. 1-8 ������ �����.
    bitNumber: short;
    //����� ������ ��� ���.
    numBusThread: short;
    //����� ���.
    adrBus: short;
    //����� ������ � ������� ��� ���
    numAdrInTable: short;
    //����� 1 ������ � ������ ���
    numAdrInBusPocket: short;
    //����� 2 ������ � ������ ���
    numAdrInBusPocket2: short;
    //!!! ����� ������� ����� ��� ������ �� �����������
    numOutPoint: short;
  end;

  Tdata = class(TObject)
    //���� ��� ���������� ������ 1 ���
    modC: boolean;
    //���������� ����������� ������ ������ � ���.
    buffDivide: integer;
    //����� ��������� ����� �� �����������
    numP: integer;
    numPfast: integer;
    // �����(������� �������� ������� ������� ����� ����������� ������� �������)
    porog: integer;
    //��� �������� �������� ����������� ������
    contVal: integer;
    //������� ���������� ������������� ����� ���� ������
    numRetimePointUp: integer;
    //������� ���������� ������������� ����� ���� ������
    numRetimePointDown: integer;
    //���������� ����� ������� � ����
    outStep: integer;

    //������� ������ ��� ������� �������
    fifoBufCount: integer;
    //������� ��� ������ � ������ fifo
    fifoLevelWrite: integer;
    //������� ������ �� fifo
    fifoLevelRead: integer;

    //������ ��� �������� ����� ������
    fifoMas: array[1..FIFOSIZE] of integer;
    //������� ��� ���������� ���������� ���������� ���
    masAnlBusChCount: integer;
    //���� ������������ ��� ������ ����� �������
    firstFraseFl: boolean;
    //������� �������� ��������� �� ���������� ������
    current: integer;

    //���������� ����� ����� ������� ������ �������� ����. ������
    pointCount: integer;
    //������� ��� ����� 12 ����. ����� ������
    iBit: integer;
    //���������� ����������� ����. ���������� ����� � �����.
    bitSizeWord: integer;

    //�����. 12 ����. ����� ������
    codStr: word;
    //������� ������ ����� ������
    wordNum: integer;
    //������� �����
    groupWordCount: integer;
    //������� ����
    fraseNum: integer;

    //���������� ��� ���� ���������� ��������� �����
    myFraseNum: integer;
    //�����������. 8 �����.
    markerNumGroup: byte;
    //��� ��������� ������� ������� �������� ����� � ����
    nMarkerNumGroup: integer;
    //��������. 8 �����
    markerGroup: byte;
    //��� ����� ���� ������
    flagL: boolean;

    //���� ������ ����, ��� �� ����� ���� ������� 128 �����
    flagOutFraseNum: boolean;

    //�����. 11 ����. ����� ������. �� �������
    wordInfo: integer;
    //����. ������ � ������ ������
    startWriteMasGroup: boolean;
    //������ ��� �������� �������� ���� ������.11 ������� �����
    {masGroup:array[1..SIZEMASGROUP] of word;}

    //������ ��� �������� �������� ���� ������.12 �����
    {masGroupAll:array[1..SIZEMASGROUP] of word;}

    //��� ������� �����������
    reqArrayOfCircle: short;
    //��� ����������  masCircle
    imasCircle: integer;
    //��� ���������� ������� ����� � ������ 1 ����� ������ ����� ������ ������
    flSinxC: boolean;
    // �������. ���������� ��� flSinxC
    flBeg: boolean;

    //�����.���������� � ���������� ������
    graphFlagSlowP: boolean;
    //�����.������������� ���������
    graphFlagTempP: boolean;
    //�����. ������� ������
    graphFlagFastP: boolean;
    //�����. ��� ������
    graphFlagBusP: boolean;

    //������� ��� ������ �� ������ ������� ����������
    countPastOut: integer;
    //������ �� �������� ������� ������� ��������
    masFastVal: array{[1..100000]} of double;
    //����� ������ �� ����������� ��������
    //�������� ����� ��������� �� ������ ����.
    chanelIndexSlow: integer;
    //����� ������ �� ����������� ��������
    //�������� ����� ��������� �� ������ ����.
    chanelIndexTemp: integer;
    //����� ������ �� ����������� �������� ��������
    //����� ��������� �� ������ ����.
    chanelIndexFast: integer;
    //����� ������ �� ����������� �������� ��������
    //����� ��������� �� ������ ���
    chanelIndexBus:integer;
    //�������� ��� �������� ������� ���������� � ���������� �������
    analogAdrCount: integer;
    contactAdrCount: integer;
    tempAdrCount:Integer;
    //bool:boolean;

    //----------------------------------- M08,04,02,01
    fraseMarkFl: boolean;
    countPointMrFrToMrFr: integer;
    //���� ��� ����. �������� ������ ������� �����
    qSearchFl: boolean;
    iMasGroup: integer;
    //���� ��� ������ ����� ����
    flagCountFrase: boolean;
    //������� ����
    fraseCount: integer;
    //������� �����
    groupCount: integer;
    //����� ��� ����� ������� ������
    bufMarkGroup: int64;
    //7 ��������� �������� � 0 �� 127 ������ ������
    bufNumGroup:byte;
    flfl: boolean;
    //���� ��� ������ �������� �����
    flagCountGroup: boolean;
    //����� ��� ����� ������� �����
    bufMarkCircle: int64;
    //������ �������� ���� ���.
    busArray:array of word;
    //������� ����������� ���� ���
    iBusArray:integer;
    //���� ��� ������ ������� ��� ���. ������� ���
    flagWtoBusArray:boolean;
    //����. ��� ������ ������� ����� ��� �08,04,02,01 ������� �� ���������������
    markKoef:Double;
    //������ � ������ �������� ������� ����� � ����� �� ���������������.
    //3=111000,6=1111110000000
    widthPartOfMF:integer;
    //���������� ����� ����� ��������� ���� � �����. �� ���������������
    minSizeBetweenMrFrToMrFr:Integer;
    //������� ��� �������� �������� ���� �� 1 �� 100
    countForMF:Integer;
    //������� ������ ������ ������� ����� �� 100 ���
    countErrorMF:Integer;

    //������� ������ ���� �� ������� ������ �� ������� ������
    countEvenFraseMGToMG:integer;
    //������� ��� �������� �������� ����� �� 1 �� 100
    countForMG:Integer;
    //������� ������ ������ ������� ������ �� 100 ���
    countErrorMG:Integer;

    procedure OutMF(errMF:Integer);
    procedure OutMG(errMG:Integer);
    //�������� ������� ������� ����� ������ ������� �����
    function TestMFOnes(curNumPoint:Integer;numOnes:integer):Boolean;
    //�������� ������� ������� ����� ����� ������� �����
    function TestMFNull(curNumPoint:Integer;numNulls:integer):Boolean;
    //��������������� ��������� ��� ������ ������ �������� �����
    procedure TestSMFOutDate(numPointDown:Integer;numCurPoint:integer;numPointUp:integer);
    //������� ������ �������� �� 0 � 1
    function SearchP0To1(curPoint:Integer;nextPoint:integer):Boolean;
    //������� ������ �������� �� 1 � 0
    function SearchP1To0(curPoint:Integer;nextPoint:integer):Boolean;
    //����� ������ �� �������
    procedure OutDate;
    //������ ���� ������ � �����
    procedure FillBitInWord;
    //������ �����
    procedure AnalyseFrase;
    //���� �������� ��������� T22
    function BuildFastValueT22(value: integer; fastWordNum: integer): integer;
    //���� �������� ��������� T24
    function BuildFastValueT24(value: integer; fastWordNum: integer): integer;
    //���� ����������� ���������
    function OutputValueForBit(value: integer; bitNum: integer): short;
    //����� ������� �����
    procedure SearchFirstFraseMarker;
    //����� ���������� ������ �� �����������
    procedure OutToGistGeneral;
    //���������� ������� ������
    procedure FillArrayGroup;
    //���������� ������� �����
    procedure FillArrayCircle;
    //���� ������� ������ ������
    procedure CollectMarkNumGroup;
    //���� ������� ������
    procedure CollectMarkGroup;
    //procedure AddValueInMasDiaValue(numFOut:integer;step:integer;
      //masGSize:integer;var numP:integer);
    //����� �� �����������
    procedure OutToDia(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numChanel: integer; typeOfAddres: short;
      numBitOfValue: short; busTh: short; busAdr: short; var numOutPoint: short);
    //����� �� ����������� ����������
    procedure OutToGistSlowAnl(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numP: integer);
    //����� �� ����������� �������������
    procedure OutToGistTemp(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numP: integer);
    //����� �� ����������� �������
    procedure OutToGistFastParam(firstPointValue: integer; outStep: integer;
      masOutSize: integer; adrtype: short;
      var numPfast: integer; numBitOfValue: integer);
    //����� �� ����������� ���
    procedure OutToGistBusParam(firstPointValue: integer; outStep: integer;
      masOutSize: integer; adrtype: short;
      var numPfast: integer; numBitOfValue: integer);
    
    //��������� ��� ������������� ������� ������ ������
      // � ���������� ������� ������� ����� ��� ����. ������ �� ������
    procedure AdressAnalyser(adressString: string; var imasElemParam: integer);
    procedure FillAdressParam;
    //������� ������� ����� ������� � ������� ���� ��������
    procedure CountAddres;
    function SignalPorogCalk(bufMasSize: integer; acpBuf: TShortrArray;
      reqNumb: word): integer;
    procedure Add(signalElemValue: integer);
    //��������� ������� ��� M16
    procedure TreatmentM16;
    ////��������� ������� ��� M08,04,02,01
    procedure TreatmentM8_4_2_1;
    function Read(): integer; overload;
    function Read(offset: integer): integer; overload;
    //���������� ��������� � ������ ��� ������ ������
    procedure ReInitialisation;
    //�������� ������������ ������� ������
    function GenTestAdrCorrect:boolean;
    //�������� �����. ���. ������. �������
    function AditTestAdrCorrect: boolean;
    //���������� ������
    //procedure SaveReport;
    //��� ������ � ��������� ������(������� �������� ���� �����(system))
    procedure WriteSystemInfo(value: string);
    //������� �������� �������� � ������� ������
    function AvrValue(firstOutPoint: integer; nextPointStep: integer;
      masGroupS: integer): integer;
    constructor CreateData;

    //m08,04,02,01
    //
    procedure WriteToFIFObuf(valueACP: integer);
    //����� ������� �������
    function FindFraseMark(var fifoLevelRead: integer): integer;
    //������� �� ������ ���������� ����� ������
    procedure FifoNextPoint(countPoint: integer);
    //������� ����� ������� �����
    function QfindFraseMark: boolean;
    //�������� ������ ����������� ������� (����� �����),
    //������ �������� �������, ��������������� ������
    procedure FillMasGroup(countPointToPrevM: integer;
      currentMarkFrBeg: integer; orbInf: string; var iMasGroup: integer);
    //������� �� ������ ���������� ����� �����
    procedure FifoBackPoint(countPoint: integer);
    //������ 1 �������� � �����.���
    function ReadFromFIFObuf: integer;
    function TestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
    function QtestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
    function ReadFromFIFObufB(offset: integer): integer;
    function ReadFromFIFObufN(prevMarkFrBeg: integer; offset: integer): integer;
    function BuildBusValue(highVal:word;lowerVal:word):word;
    function CollectBusArray(var iBusArray:integer):boolean;
  end;

  Tacp = class(TObject)

    //������� ��� ������ � ��� � ���������� ������
    function ReadThread: DWORD;
    //����� ��������� �� ������
    procedure AbortProgram(ErrorString: string; AbortionFlag: bool = true);
    function WaitingForRequestCompleted(var ReadOv: OVERLAPPED): boolean;
    procedure ShowThreadErrorMessage;
    //����.
    constructor InitApc;
    procedure CreateApc;

  end;

  //��� ������ �������������
type
  adrElement = record
    litera: char;
    n: short;
    k: short;
  end;

var
  Form1: TForm1;

  //===================================
  //���������� ��� ������ � ���
  //===================================

  //=============================
  //��������� ��������.
  //=============================
  //RS485
  //���������� ��� �������� ip-������ �������� RS485 (ini-����)
  HostAdapterRS485: string;
  //���������� ��� �������� ������ ����� ��� ��������
  PortAdapterRS485: integer;
  //���1
  //���������� ��� �������� ip-������ ������� ��� (ini-����)
  HostISD1: string;
  //���2
  //���������� ��� �������� ip-������ ������� ��� (ini-����)
  HostISD2: string;
  //���������
  //���������� ��� �������� �������������� ����������
  RigolDg1022: string;
  //���������
  m_defaultRM_usbtmc, m_instr_usbtmc: array[0..3] of LongWord;
  viAttr: Longword = $3FFF001A;
  Timeout: integer = 1000; //7000
  //==============================

  //==============================
  //������ � �������
  //==============================
  //�������� ���������� ��� ������ � ��������� ������
  systemFile: Text;
  //�������� ���������� ��� ������������ ������ �������� � ����
  reportFile: Text;
  //���� ������ � ���
  LogFile: text;
  //==============================

  //����� ��� ������ � �������� ������
  data: Tdata;
  //����� ��� ������ � TLM
  tlm: Ttlm;
  //����� ��� ������ � ���
  acp: Tacp;

  //����. ������ ��� ���������� �������
  masElemParam: array of channelOutParam;

  arrAddrOk:array of string;

  //������� ������ ������. ����� ������� ������
  iCountMax: integer;
  //���. ���������� �������
  acumAnalog: integer;
  //�����. ������������� �������
  acumTemp:Integer;
  //���. ����������
  acumContact: integer;
  //���. �������
  acumFast: integer;
  //���. ��� �������
  acumBus:integer;
  //���������� ����������� ���� � ������� ������ �� ���������������
  masGroupSize: integer;
  //���������� ����������� ���� � ������� ����� �� ���������������
  masCircleSize:cardinal;
  masGroup: array[1..SIZEMASGROUP] of word;
  masGroupAll: array[1..SIZEMASGROUP] of word;
  //������ ��������� ����
  masCircle: TDBufCircleArray;
  //����� ��������������� ������
  infNum: integer;
  //������ � ���������������� ������
  infStr: string;

  // ������������� ������ �����
  hReadThread: THANDLE;
  ReadTid: DWORD;
  // ������ ���������� ������� ����� ������
  IsReadThreadComplete: boolean;
  // �������� �������-���������
  Counter, OldCounter: WORD;
  // ������ ���������� Rtusbapi.dll
  DllVersion: DWORD;
  // ������������� ����������
  ModuleHandle: THandle;
  // �������� ������ ���� USB
  UsbSpeed: BYTE;
  // ��������� � ������ ����������� � ������
  ModuleDescription: MODULE_DESCRIPTION_E2010;
  // ��������� �������� ����� ������
  DataState: DATA_STATE_E2010;
  // ����� ����������������� ����
  UserFlash: USER_FLASH_E2010;
  // ��������� ���������� ������ ���
  ap: ADC_PARS_E2010;
  // ���-�� �������� � ������� ReadData
  DataStep: DWORD;
  // ��������� ������ E20-10
  pModule: ILE2010;
  // �������� ������
  ModuleName: string;
  // ��������� �� ����� ��� ������
  Buffer: TShortrArray;
  //����� �������
  RequestNumber: WORD;
  // ��������������� ���.
  Str: string;
  // ������� ������ �� DataStep �������� ����� ������� � ����
  NBlockToRead: WORD; // = 4*20;
  //������ OVERLAPPED �������� �� ���� ���������
  ReadOv: array[0..1] of OVERLAPPED;
  // ������ �������� � ����������� ������� �� ����/����� ������
  IoReq: array[0..1] of IO_REQUEST_LUSBAPI;
  // ����� ������ ��� ���������� ������ ����� ������
  ReadThreadErrorNumber: WORD;

  //������� ��� �������� ������ ������
  countC: integer;

  //���������� ��� ini ����� ��� ����������� ���� ���������� ����� ��������
  propIniFile:TiniFile;
  propStrPath:string;


  flagEnd:boolean;

  //���� ��� 32-����. ����
  //swtFile:text;

  cOut:integer;
  csk:TCriticalSection;

  boolFlg:boolean;

  testOutFalg:boolean;

  //textTestFile:Text;
  //���� ��� ������ ������ �����
  orbOk:Boolean;
  orbOkCounter:integer;
implementation

//uses Unit1;

{$R *.dfm}

//==============================================================================
//��������� ���������� �� ����� � ����
//==============================================================================
//������������ ����� �����

{procedure SaveBitToLog(str: string);
begin
  Writeln(LogFile,str);
  exit
end;}
//==============================================================================

//==============================================================================
//������� ��������
//==============================================================================

procedure Wait(value: integer);
var
  i: integer;
begin
  for i := 1 to value do
  begin
    sleep(3);
    application.ProcessMessages;
  end;
end;
//==============================================================================


//==============================================================================
//
//==============================================================================
procedure GetAddrList;
var
  maxAdrNum:Integer;
  iAdr:integer;
  adrCount:integer;
begin
  arrAddrOk:=nil;
  iAdr := 0;
  maxAdrNum:=form1.OrbitaAddresMemo.Lines.Count - 1;
  for adrCount := 0 to maxAdrNum  do
  begin
    if form1.OrbitaAddresMemo.Lines.Strings[adrCount]<>'' then
    begin
      //��������� ������ ������
      //������� ������ �� ������� ������� ����������
      setlength(arrAddrOk, iAdr  + 1);
      arrAddrOk[iAdr]:=form1.OrbitaAddresMemo.Lines.Strings[adrCount];
      inc(iAdr);
    end;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure SetOrbAddr;
var
  iAdr:Integer;
  maxAdrNum:integer;
begin
  //������� ������ �������
  form1.OrbitaAddresMemo.Clear;
  maxAdrNum:=Length(arrAddrOk)-1;
  for iAdr:=0 to maxAdrNum do
  begin
    form1.OrbitaAddresMemo.Lines.Add(arrAddrOk[iAdr]);
  end;
end;
//==============================================================================

//==============================================================================
//������� �� ������ � ���
//==============================================================================

// ����������� ������ ��������� �� ����� ������ ������ ����� ������
//==============================================================================

procedure Tacp.ShowThreadErrorMessage;
begin
  case ReadThreadErrorNumber of
    $0: ;
    $1: showMessage(' ADC Thread: STOP_ADC() --> Bad! :(((');
    $2: showMessage(' ADC Thread: ReadData() --> Bad :(((');
    $3: showMessage(' ADC Thread: Waiting data Error! :(((');
    // ���� ��������� ���� ������ ��������, ��������� ���� ��������
    $4: showMessage(' ADC Thread: The program was terminated! :(((');
    $5: showMessage(' ADC Thread: Writing data file error! :(((');
    $6: showMessage(' ADC Thread: START_ADC() --> Bad :(((');
    $7: showMessage(' ADC Thread: GET_DATA_STATE() --> Bad :(((');
    $8: showMessage(' ADC Thread: BUFFER OVERRUN --> Bad :(((');
    $9: showMessage(' ADC Thread: Can''t cancel' +
         ' pending input and output (I/O) operations! :(((');
    $10: showMessage('������! ����� �� ���������!');

    else
      showMessage(' ADC Thread: Unknown error! :(((');
  end;
end;
//==============================================================================

//==============================================================================
// ��������� ���������� ���������. ��������������� ������������ ��� ��������
//==============================================================================

procedure Tacp.AbortProgram(ErrorString: string; AbortionFlag: bool = true);
var
  i: WORD;
begin
  // ��������� ��������� ������
  if pModule <> nil then
  begin
    // ��������� ��������� ������
    if not pModule.ReleaseLInstance() then
    begin
      //form1.Memo1.Lines.Add('ReleaseLInstance() --> Bad')
      showMessage('ReleaseLInstance() --> Bad')
    end
    else
    begin
      //showMessage('ReleaseLInstance() --> OK');
      //form1.Memo1.Lines.Add('ReleaseLInstance() --> OK');
      //������� ��������� �� ��������� ������
      pModule := nil;
    end;
    // ��������� ������ ��-��� ������� ������
    for i := 0 to 1 do
    begin
      Buffer[i] := nil;
    end;
    // ���� ����� - ������� ��������� � �������
    if ErrorString <> ' ' then
    begin
      MessageBox(HWND(nil),pCHAR(ErrorString),'������!!!', MB_OK + MB_ICONINFORMATION);
    end;
    // ���� ����� - �������� ��������� ���������
    if AbortionFlag = true then
    begin
      halt;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//      ������� ����������� � �������� ���������� ������
//             ��� ����� ������ c ������ E20-10
//==============================================================================
function Tacp.ReadThread: DWORD;
var
  indJ: integer;
  iReadThread: WORD;
  m:integer;
begin
  // ��������� ������ ��� � ������������ ������� USB-����� ������ ������
  if not pModule.STOP_ADC() then
  begin
    ReadThreadErrorNumber := 1;
    IsReadThreadComplete := true;
    result := 1;
    exit;
  end;

  // ��������� ����������� ��� ����� ������ ���������
  for iReadThread := 0 to 1 do
  begin
    // ������������� ��������� ���� OVERLAPPED
    ZeroMemory(@ReadOv[iReadThread], sizeof(OVERLAPPED));
    // ������ ������� ��� ������������ �������
    ReadOv[iReadThread].hEvent := CreateEvent(nil, FALSE, FALSE, nil);
    // ��������� ��������� IoReq
    IoReq[iReadThread].Buffer := Pointer(Buffer[iReadThread]);
    IoReq[iReadThread].NumberOfWordsToPass := DataStep;
    IoReq[iReadThread].NumberOfWordsPassed := 0;
    IoReq[iReadThread].Overlapped := @ReadOv[iReadThread];
    IoReq[iReadThread].TimeOut := Round(Int(DataStep / ap.KadrRate)) + 1000;
  end;

  // ������� ������� ������ ����������� ���� ������ � Buffer
  RequestNumber := 0;
  if not pModule.ReadData(@IoReq[RequestNumber]) then
  begin
    CloseHandle(IoReq[0].Overlapped.hEvent);
    CloseHandle(IoReq[1].Overlapped.hEvent);
    ReadThreadErrorNumber := 2;
    IsReadThreadComplete := true;
    result := 1;
    exit;
  end;

  //���� ������
  if pModule.START_ADC() then
  begin
    while hReadThread <> THANDLE(nil) do
    begin
      RequestNumber := RequestNumber xor $1;
      // ������� ������ �� ��������� ������ �������� ������
      if not pModule.ReadData(@IoReq[RequestNumber]) then
      begin
        ReadThreadErrorNumber := 2;
        break;
      end;
      if not WaitForSingleObject(IoReq[RequestNumber xor $1].Overlapped.hEvent,
          IoReq[RequestNumber xor $1].TimeOut) = WAIT_TIMEOUT then
      begin
        ReadThreadErrorNumber := 3;
        break;
      end;
      // ��������� �������� ������� ��������� �������� ����� ������
      if not pModule.GET_DATA_STATE(@DataState) then
      begin
        ReadThreadErrorNumber := 7;
        break;
      end;
      // ������ ����� ��������� ���� ������� ������������
      // ����������� ������ ������
      if (DataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
      begin
        ReadThreadErrorNumber := 8;
        break;
      end;
      //��� ������ ������� ������� ��������� ��������
      if (not data.modC) then
      begin
        data.buffDivide := length(buffer[RequestNumber xor $1]);
        //����������� �������� ������ ��� ����������� ������� �������.
        data.porog := data.SignalPorogCalk(Round(data.buffDivide/10), buffer,RequestNumber); //!!! Round(data.buffDivide/10)
        //data.modC := true;
      end;

     { for m:=1 to 3000 do
      begin
      form1.Memo1.Lines.Add(inttostr(m)+'  '+intTostr(buffer[RequestNumber xor $1][m]));
      end;



      while (true) do application.processmessages; }



      //���������, ��� ������ ������ �����.
      if data.porog>200 then
      begin
        //��������� ��������� ���������������
        indJ := 0;
        form2.Hide;
        //M16
        if infNum = 0 then
        begin
          //���� �� ��������� ������ � ���
          if not flagEnd then
          begin
            //������������ ������ � ����� �����.
            while indJ < data.buffDivide do
            begin
              data.Add(Buffer[RequestNumber xor $1][indJ]);
              inc(indJ);
            end;
            //��������� �16
            data.TreatmentM16;
          end;
        end
        //M8,4,2,1
        else
        begin
          if not flagEnd then
          begin
            while indJ < data.buffDivide do
            begin
              data.WriteToFIFObuf(Buffer[RequestNumber xor $1][indJ]);
              inc(indJ);
            end;
            //��������� �8_4_2_1
            data.TreatmentM8_4_2_1;
          end;
        end;
      end
      else
      begin
        //CloseFile(textTestFile);
        {data.graphFlagFastP := false;

        //Application.ProcessMessages;
        sleep(50);
        //Application.ProcessMessages;

        if ((form1.tlmWriteB.Enabled)and
            (not form1.startReadTlmB.Enabled)and
            (not form1.propB.Enabled))  then
        begin
          //��������� ������ � ���
          pModule.STOP_ADC();
        end;
        //�������� ��� ���������� �����
        flagEnd:=true;
        wait(100); }

        data.modC := false;
        form2.show;

      end;

      // ���� �� ������ ��� ������������ ������� ���� ������?
      if ReadThreadErrorNumber <> 0 then
      begin
        break;
      end
      else
      begin
        //Sleep(20);
      end;

      // ����������� ������� ���������� ������ ������(��������)
      inc(countC);
      {if countC = 12 then
      begin
        form1.Label2.Caption:=IntToStr(countC);
      end;}

      //����� �������� ������ ������. ��� ������ �����=).
      if (countC = 32767) then
      begin
        countC := 0;
      end;
      //form1.Label2.Caption := IntToStr(countC);
    end;
  //��������� ����������.��������� ����������� ������.
  end
  else
  begin
    ReadThreadErrorNumber := 6;
  end;
  // ��������� ���� ������ c ���
  // !!!�����!!! ���� ���������� ����������� ���������� � �����������
  // ���� �������� ������, �� ������� STOP_ADC() ������� ��������� �� �������,
  // ��� ����� 800 �� ����� ��������� ����� ��������� ������ ������.
  // ��� �������� ������� ����� ������ � 5 ��� ��� �������� ���������� �����
  // ������������ ������������� FIFO ������ ������, ������� ����� ������ 8 ��.
  if not pModule.STOP_ADC() then
  begin
    ReadThreadErrorNumber := 1;
  end;
  acp.ShowThreadErrorMessage();
  // ���� ����� - ����������� ������������� �������
  //������������ ����������� ������ ������
  if (DataState.BufferOverrun <> (1 shl BUFFER_OVERRUN_E2010)) then
  begin
    // ��������� �������� ������������� ��������� �������� ����� ������
    if not pModule.GET_DATA_STATE(@DataState) then
    begin
      ReadThreadErrorNumber := 7
    end
    // ������ ����� ��������� ���� �������
    //������������ ����������� ������ ������
    else
    begin
      if (DataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
      begin
        ReadThreadErrorNumber := 8;
      end;
    end
  end;
  // ���� ����, �� ������ ��� ������������� ����������� �������
  if not CancelIo(ModuleHandle) then
  begin
    ReadThreadErrorNumber := 9;
  end;
  // ��������� �������������� �������
  CloseHandle(IoReq[0].Overlapped.hEvent);
  CloseHandle(IoReq[1].Overlapped.hEvent);
  // ����������
  //Sleep(100);
  //����� ������ ������� ��� �������
  form1.diaSlowAnl.Series[0].Clear;
  form1.gistSlowAnl.Series[0].Clear;
  form1.diaSlowCont.Series[0].Clear;
  form1.fastDia.Series[0].Clear;
  form1.fastGist.Series[0].Clear;
  Form1.tempDia.Series[0].Clear;
  Form1.tempGist.Series[0].Clear;
  //����� �������������� ������ ������ ��������� ����� � ������.
  form1.startReadACP.Enabled:=true;
  form1.startReadTlmB.Enabled:=true;
  result := 0;
end;
//=============================================================================

//==============================================================================
// �������� ���������� ���������� ���������� ������� �� ���� ������
//==============================================================================

function Tacp.WaitingForRequestCompleted(var ReadOv: OVERLAPPED): boolean;
var
  BytesTransferred: DWORD;
begin
  Result := true;
  while true do
  begin
    if GetOverlappedResult(ModuleHandle, ReadOv,BytesTransferred, FALSE) then
    begin
      break
    end
    else
    begin
      if (GetLastError() <> ERROR_IO_INCOMPLETE) then
      begin
        // ������ �������� ����� ��������� ������ ������
        ReadThreadErrorNumber := 3;
        Result := false;
        break;
      end
      else
      begin
        //Sleep(20);
      end;
    end;
  end
end;
//==============================================================================


//==============================================================================
//
//==============================================================================
constructor Tacp.InitApc;
begin
  //����. ��� ���
  DataStep := 1024 * 1024;
  //������� �������� ���
  countC := 0;
  // ������������� ����� ������. ������ ��� 0. ������� ����� ������ ������ �����
  ReadThreadErrorNumber := 0;
end;

//==============================================================================

//=============================================================================
//
//=============================================================================
procedure Tacp.CreateApc;
var
  iGeneralTh, jGeneralTh: integer;
begin
  iGeneralTh := 0;
  //�������� ���������� ���.
  //============================================================================
  //�������� ������ ������������ DLL ����������
  //��������� ��������� Dll ������ ���������� ��� ������ � ���
  DllVersion := GetDllVersion;

  //������ DLL �� �������������.
  if DllVersion <> CURRENT_VERSION_LUSBAPI then
  begin
    Str := '�������� ������ DLL ���������� Lusbapi.dll! ' + #10#13 +
    '           �������: ' + IntToStr(DllVersion shr 16) +
    '.' + IntToStr(DllVersion and $FFFF) + '.' +
    ' ���������: ' + IntToStr(CURRENT_VERSION_LUSBAPI shr 16) +
    '.' + IntToStr(CURRENT_VERSION_LUSBAPI and $FFFF) + '.';
    //���� �������� ������ ������� ������, ������ � �
    //��������� ���������� � ��������� ���������� �����.
    AbortProgram(Str);
  end;

  //��������� �������� ��������� �� ��������� ��� ������ E20-10
  //�������� ����� ��� � �������
  pModule := CreateLInstance(pCHAR('e2010'));

  //���������� �� ����������, ��������� nil
  if pModule = nil then
  begin
    AbortProgram('�� ���� ����� ��������� ������ E20-10!');
  end;

  // ��������� ���������� ������ E20-10 �
  //������ MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI ����������� ������
  {for iGeneralTh := 0 to (MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI - 1) do
    begin
      if pModule.OpenLDevice(iGeneralTh) then
        begin
          AbortProgram('�� ���� ����� ��������� ������ E20-10!');
        end;
    end;}

  //�������� ����� e20-10 � ������� ����������� �����
  iGeneralTh := 0;
  if not pModule.OpenLDevice(iGeneralTh) then
  begin
    AbortProgram('�� ���� ����� ��������� ������ E20-10!');
  end;

  //���������� ������� ������ USB
  if not pModule.GetUsbSpeed(@UsbSpeed) then
  begin
    AbortProgram(' �� ���� ���������� �������� ������ ���� USB')
  end;

  {// ������ ��������� �������� ������ ���� USB}
  if UsbSpeed = USB11_LUSBAPI then
  begin
    Str := 'Full-Speed Mode (12 Mbit/s)';
  end
  else
  begin
    //480 ����/c   . ��� 1
    Str := 'High-Speed Mode (480 Mbit/s)';
  end;



  //iGeneralTh:=0;
  // ���-������ ����������?
  //���������� ������������ �� ����������. ���� ���, �� ������� ������.
  {if iGeneralTh = MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI then
  begin
    AbortProgram('�� ������� ���������� ������ E20-10' +
      '� ������ 127 ����������� ������!');
  end
  else
  begin
    //�� ����� ������
    //����� ������ ����������
    //form1.Memo1.Lines.Add(Format('OpenLDevice(%u) --> OK', [iGeneralTh]));
  end; }

  // ������� ������������� ����������
  //ModuleHandle := pModule.GetModuleHandle();

  //��������� �������� ������ � ������� ����������� �����
  //���������� ������ ��� ������������ ��������
  ModuleName := '0123456';
  //ModuleName := 'E20-10';


  //�������� ���������� � ������� ���������� ���?
  if not pModule.GetModuleName(pCHAR(ModuleName)) then
  begin
    AbortProgram('�� ���� ��������� �������� ������!')
  end;


  {// ��������, ��� ��� ������ E20-10}
  if Boolean(AnsiCompareStr(ModuleName, 'E20-10')) then
  begin
    AbortProgram('������������ ������ �� �������� E20-10!');
  end;

  // ����� ��� ���� ������ �� ���������������� ������� DLL ���������� Lusbapi.dll
  if not pModule.LOAD_MODULE(nil) then
  begin
    AbortProgram('�� ���� ��������� ������ E20-10!');
  end;

  if not pModule.TEST_MODULE() then
  begin
    AbortProgram('������ � �������� ������ E20-10!');
  end;

  if not pModule.GET_MODULE_DESCRIPTION(@ModuleDescription) then
  begin
    AbortProgram('�� ���� �������� ���������� � ������!');
  end;

  if not pModule.READ_FLASH_ARRAY(@UserFlash) then
  begin
    AbortProgram('�� ���� ��������� ���������������� ����!');
  end;

  if not pModule.GET_ADC_PARS(@ap) then
  begin
    AbortProgram('�� ���� �������� ������� ��������� ����� ������!');
  end;


  if ModuleDescription.Module.Revision = BYTE(REVISIONS_E2010[REVISION_A_E2010]) then
  begin
    // �������� �������������� ������������� ������ �� ������ ������ (��� Rev.A)
    ap.IsAdcCorrectionEnabled := FALSE
  end
  else
  begin
    //�������� �������������� �������������
    //������ �� ������ ������ (��� Rev.B � ����)
    ap.IsAdcCorrectionEnabled := TRUE;
    ap.SynchroPars.StartDelay := 0;
    ap.SynchroPars.StopAfterNKadrs := 0;
    ap.SynchroPars.SynchroAdMode := NO_ANALOG_SYNCHRO_E2010;
    //ap.SynchroPars.SynchroAdMode:=ANALOG_SYNCHRO_ON_HIGH_LEVEL_E2010;
    ap.SynchroPars.SynchroAdChannel := $0;
    ap.SynchroPars.SynchroAdPorog := 0;
    ap.SynchroPars.IsBlockDataMarkerEnabled := $0;
  end;

  // ���������� ����� ����� � ���
  ap.SynchroPars.StartSource := INT_ADC_START_E2010;

  // ������� ����� ����� � ���
  // ap.SynchroPars.StartSource := EXT_ADC_START_ON_RISING_EDGE_E2010;

  // ���������� �������� �������� ���
  ap.SynchroPars.SynhroSource := INT_ADC_CLOCK_E2010;

  // �������� ����� ���������� ������� ������� ��� ������
  //�������� � ������� ��� (������ ��� Rev.A)
  // ap.OverloadMode := MARKER_OVERLOAD_E2010;

  // ������� �������� ����� ���������� ������� �������
  //���� ����������� ������� ��� (������ ��� Rev.A)
  ap.OverloadMode := CLIPPING_OVERLOAD_E2010;

  // ���-�� �������� �������
  ap.ChannelsQuantity := CHANNELSQUANTITY;

  //-
  // ���� �������� ������� ������ 1.
  {for iGeneralTh := 0 to (ap.ChannelsQuantity - 1) do
    begin
      ap.ControlTable[iGeneralTh] := iGeneralTh;
    end;}

  //����c����� ����� ������ � ������� ������� ������������ ������
  {if (strtoint(form1.ComboBox1.Text)<>0) then }
    //ap.ControlTable[0]:=1;  //����������� ����� ������(1)

  //+
  // ������� ����� ����� ������������� � ����������� �� �������� USB
  // ������� ��� ������ � ���
  // ������������� ���������
  ap.AdcRate := AdcRate;
  // � ����������� �� �������� USB ����������
  //����������� �������� � ������ �������.
  if UsbSpeed = USB11_LUSBAPI then
  begin
    // ����������� �������� � ��.
    //����� ����� ����� ����� ����� ��������� ����� � ���.
    // 12 Mbit/s
    ap.InterKadrDelay := 0.01;
    DataStep := 256 * 1024; // ������ �������
  end
  else
  begin
    // ����������� �������� � ��  . 1/131072= 0.00007. 7 ����� ������.
    // 480 Mbit/s
    ap.InterKadrDelay := 0.0;
    DataStep := 1024 * 1024; // ������ �������
  end;

  // ���������� ������� ������ . ��������� 4-� ���������� �������.
  {for iGeneralTh := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
    begin
      // ������� �������� 3�
      ap.InputRange[iGeneralTh] := ADC_INPUT_RANGE_3000mV_E2010;
      // �������� ����� - ������
      ap.InputSwitch[iGeneralTh] := ADC_INPUT_SIGNAL_E2010;
    end;}

  iGeneralTh := 0;
  // ������� �������� 3�
  ap.InputRange[iGeneralTh] := ADC_INPUT_RANGE_3000mV_E2010;
  // �������� ����� - ������
  ap.InputSwitch[iGeneralTh] := ADC_INPUT_SIGNAL_E2010;

  // ������� � ��������� ���������� ������ ��� ���������������� ������������ ���
  //������ ����������� � ��������� ��������� ��� ���������� ��������
  {for iGeneralTh := 0 to (ADC_INPUT_RANGES_QUANTITY_E2010 - 1) do
    begin
      for jGeneralTh := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
        begin
          // ������������� ��������
          ap.AdcOffsetCoefs[iGeneralTh][jGeneralTh] :=
            ModuleDescription.Adc.OffsetCalibration[jGeneralTh +
              iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
          // ������������� ��������
          ap.AdcScaleCoefs[iGeneralTh][jGeneralTh] :=
            ModuleDescription.Adc.ScaleCalibration[jGeneralTh +
              iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
        end;
    end;}

  iGeneralTh:=0;
  jGeneralTh:=0;
  // ������������� ��������
  ap.AdcOffsetCoefs[iGeneralTh][jGeneralTh] :=
    ModuleDescription.Adc.OffsetCalibration[jGeneralTh +
      iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
  // ������������� ��������
  ap.AdcScaleCoefs[iGeneralTh][jGeneralTh] :=
    ModuleDescription.Adc.ScaleCalibration[jGeneralTh +
      iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];

  // ��������� � ������ ��������� ��������� �� ����� ������
  // ���������� ��������� ����� � ���
  // �� ������� ��������
  if not pModule.SET_ADC_PARS(@ap) then
  begin
    AbortProgram('�� ���� ���������� ��������� ����� ������!');
  end;


  // ��������� �������� ������ ���-�� ������ ��� ������ ������
  for iGeneralTh := 0 to 1 do
  begin
    SetLength(Buffer[iGeneralTh], DataStep);
    ZeroMemory(Buffer[iGeneralTh], DataStep * SizeOf(SHORT));
  end;

  // �������� ����� ����� ������
  hReadThread := BeginThread(nil, 0, @Tacp.ReadThread, nil, 0, ReadTid);
  if hReadThread = THANDLE(nil) then
  begin
    AbortProgram('�� ���� ��������� ����� ����� ������!');
  end;
end;
//==============================================================================

//==============================================================================
//������� �� ������ � ������ ���
//==============================================================================

//=============================================================================
//
//=============================================================================

constructor Ttlm.CreateTLM;
begin
  //��������� ����������� ����� � ����� ��� � ���������� �� ���������������
  case infNum of
    //M16
    0:
    begin
      sizeBlock := 131104;
    end;
    //M08
    1:
    begin
      sizeBlock := 65568;
    end;
    //M04
    2:
    begin
      sizeBlock := 32800;
    end;
    //M02
    3:
    begin
      sizeBlock := 16416;
    end;
    //M01
    4:
    begin
      sizeBlock := 8224;
    end;
  end;

  //�� ��������� ����� � ���
  tlmBFlag := true;
  //���������� ������ �� ������
  tlmPlaySpeed := 4;
  //��� ����. ������ � ���� ��� ���
  flagWriteTLM := false;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.StartWriteTLM;
var
  j: integer;
  strLen:integer;
begin
  //get time in ms
  msTime := DateTimeToUnix(Time) * 1000;
  //create file name
  case infNum of
    //M16
    0:
      begin
        fileName := 'M16_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.tlm';
      end;
    //M08
    1:
      begin
        fileName := 'M08_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.tlm';
      end;
    //M04
    2:
      begin
        fileName := 'M04_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.tlm';
      end;
    //M02
    3:
      begin
        fileName := 'M02_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.tlm';
      end;
    //M01
    4:
      begin
        fileName := 'M01_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.tlm';
      end;
  end;
  strLen:=length(fileName);
  for j := 1 to strLen do
  begin
    if (fileName[j] = ':') then
    begin
      fileName[j] := '.';
    end;
  end;

  //set begin value of count write byte
  countWriteByteInFile := 0;
  //set begin out precision
  precision := 0;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteToFile(str: string);
var
  i: integer;
  simbInByte: byte;
  strLen:Integer;
begin
  strLen:=length(str);
  for i := 1 to strLen do
  begin
    simbInByte := ord(str[i]);
    SetLength(tlmHeadByteArray, iTlmHeadByteArray + 1);
    tlmHeadByteArray[iTlmHeadByteArray] := simbInByte and 255;
    inc(iTlmHeadByteArray);
    //write(PtlmFile,simbInByte);
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteToFile(nullVal: byte);
var
  j: integer;
begin
  //������� �� ���. ���� ���������� ����������
  for j := 1 to SizeOf(nullVal) do
  begin
    SetLength(tlmHeadByteArray, iTlmHeadByteArray + 1);
    tlmHeadByteArray[iTlmHeadByteArray] := nullVal and 255;
    inc(iTlmHeadByteArray);
    //���������� �� ����� �������� ����� �������
    nullVal := nullVal shr 8 {(j*8)};
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
//for cardinal value

procedure Ttlm.WriteByteToByte(multiByteValue: cardinal);
var
  j: integer;
begin
  //������� �� ���. ���� ���������� ����������
  for j := 1 to SizeOf(multiByteValue) do
  begin
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //���������� �� ����� �������� ����� �������
    multiByteValue := multiByteValue shr 8 {(j*8)};
  end;
end;

//for word value

procedure Ttlm.WriteByteToByte(multiByteValue: word);
var
  j: integer;
begin
  //������� �� ���. ���� ���������� ����������
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //write(PtlmFile,multiByteValue);
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //���������� �� ����� �������� ����� �������
    multiByteValue := multiByteValue shr 8 {(j*8)};
  end;
end;

//for byte value

procedure Ttlm.WriteByteToByte(multiByteValue: byte);
var
  j: integer;
begin
  //������� �� ���. ���� ���������� ����������
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //write(PtlmFile,multiByteValue);
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //���������� �� ����� �������� ����� �������
    multiByteValue := multiByteValue shr 8 {(j*8)};
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteCircleM16;
var
  i: integer;
begin
  for i := 1 to {length(masCircle[data.reqArrayOfCircle])}masCircleSize{ - 1} do
  begin
    //12 ��������� ����� ������ + ��� 1��+�� �����+����� ����������+
    //+��. ������ ����� . M8 65535 ���� 32768 ���� ������
    if i = 1{0} then
    begin
      //��������� ��� ��� ������ ����� � ������������� ��� ������ �����
      //� 1 �����
     //16 ��� � 1. ������ �����
    { data.masCircle[data.reqArrayOfCircle][i]:=
       data.masCircle[data.reqArrayOfCircle][i] or 32768;}
    end;
    if iOneGC = 4 then
    begin
      //13 ��� � 1. ����� 1 ��
      masCircle[data.reqArrayOfCircle][i] :=masCircle[data.reqArrayOfCircle][i] or 4096;
      iOneGC := 1;
    end;

    //������ 16 ������� �������� �������� � ��������
    WriteByteToByte(masCircle[data.reqArrayOfCircle][i]);
  end;
  inc(iOneGC);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteCircleM08_04_02_01;
var
  i: integer;
begin
  for i := 1 to {length(masCircle[data.reqArrayOfCircle])}masCircleSize {- 1} do
  begin
    //12 ��������� ����� ������ + ��� 1��+�� �����+����� ����������+
    //+��. ������ ����� . M8 65535 ���� 32768 ���� ������
    if i = 1{0} then
    begin
      //��������� ��� ��� ������ ����� � ������������� ��� ������ �����
      //� 1 �����
     //16 ��� � 1. ������ �����
      {masCircle[data.reqArrayOfCircle][i] :=     ///!!!!! �������� �������
        masCircle[data.reqArrayOfCircle][i] or 32768;}
    end;
    if iOneGC = 4 then
    begin
      //12 ��� � 1. ����� 1 ��
      masCircle[data.reqArrayOfCircle][i] :=
        masCircle[data.reqArrayOfCircle][i] or 4096;
      iOneGC := 1;
    end;

    //������ 16 ������� �������� �������� � ��������
    WriteByteToByte(masCircle[data.reqArrayOfCircle][i]);
  end;
  inc(iOneGC);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteTLMhead;
var
  str: string;
  //count write byte
  byteCount: integer;
  i: integer;
begin
  //������� ���������� ���� ���������
  iTlmHeadByteArray := 0;
  //Head//
  //dev name
  WriteToFile('Complex=');
  WriteToFile('MERATMS-M.SYSTEM=ORBITAIV.');
  //data
  WriteToFile('DATA=');
  DateTimeToString(str, 'yyyy:mm:dd.', Date);
  WriteToFile(str);
  //time
  WriteToFile('TIME=');
  DateTimeToString(str, 'hh:mm:sszzz.', Time);
  WriteToFile(str);
  //
  WriteToFile('OBJ=');
  WriteToFile('TMS-M.');
  //
  WriteToFile('SEANS=');
  WriteToFile('.');
  //
  WriteToFile('RC=');
  WriteToFile('LOC.');
  //
  WriteToFile('MODE=');
  WriteToFile('WORK.');
  //
  WriteToFile('T_INP=');
  WriteToFile('INT.');
  //
  WriteToFile('INF=');
  case infNum of
    //M16
    0:
      begin
        WriteToFile('16' + '.');
      end;
    //M08
    1:
      begin
        WriteToFile('8' + '.');
      end;
    //M04
    2:
      begin
        WriteToFile('4' + '.');
      end;
    //M02
    3:
      begin
        WriteToFile('2' + '.');
      end;
    //M01
    4:
      begin
        WriteToFile('1' + '.');
      end;
  end;

  //
  WriteToFile('INP=');
  WriteToFile('RADIO.');
  //
  WriteToFile('FREQ=');
  WriteToFile('2299400.');
  //
  WriteToFile('PPU=');
  WriteToFile('AUTO.');
  //
  WriteToFile('REF=');
  WriteToFile('.');
  //
  WriteToFile('TO=');
  WriteToFile('0.0S');
  //max head size 256 byte
  byteCount := length(tlmHeadByteArray);
  //write 0 value to end
  for i := byteCount + 1 to MAXHEADSIZE do
  begin
    WriteToFile(0);
  end;

  //��������� ���� �� ������ ����� ����
  AssignFile(PtlmFile, ExtractFileDir(ParamStr(0)) + '/Report/' + fileName);
  //��� ������ 1 �����, ���� ����� ������ ��������� ������
  ReWrite(PtlmFile, 1);
  //������� � ���� ���������� ���. ������ ��������*������ ������ �������� � ������
  BlockWrite(PtlmFile, tlmHeadByteArray[0], length(tlmHeadByteArray) * sizeOf(byte)); //!!!
  //���������� ���������� ���������� � ���� �a��
  countWriteByteInFile := length(tlmHeadByteArray);
  closeFile(PtlmFile);

  //���. ����. ������ �����. ����� . � ������
  blockNumInfile := 1;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.OutFileName;
var
  i: integer;
  str: string;
  bool: boolean;
  strLen:Integer;
begin
  str := '';
  bool := false;
  if form1.OpenDialog1.Execute then
  begin
    strLen:=length(form1.OpenDialog1.FileName);
    for i := 1 to strLen  do
    begin
      if (((form1.OpenDialog1.FileName[i] = 'M') and
        (form1.OpenDialog1.FileName[i + 1] = '1') and
        (form1.OpenDialog1.FileName[i + 2] = '6') and
        (form1.OpenDialog1.FileName[i + 3] = '_')) or
        ((form1.OpenDialog1.FileName[i] = 'M') and
        (form1.OpenDialog1.FileName[i + 1] = '0') and
        (form1.OpenDialog1.FileName[i + 2] = '8') and
        (form1.OpenDialog1.FileName[i + 3] = '_')) or
        ((form1.OpenDialog1.FileName[i] = 'M') and
        (form1.OpenDialog1.FileName[i + 1] = '0') and
        (form1.OpenDialog1.FileName[i + 2] = '4') and
        (form1.OpenDialog1.FileName[i + 3] = '_')) or
        ((form1.OpenDialog1.FileName[i] = 'M') and
        (form1.OpenDialog1.FileName[i + 1] = '0') and
        (form1.OpenDialog1.FileName[i + 2] = '2') and
        (form1.OpenDialog1.FileName[i + 3] = '_')) or
        ((form1.OpenDialog1.FileName[i] = 'M') and
        (form1.OpenDialog1.FileName[i + 1] = '0') and
        (form1.OpenDialog1.FileName[i + 2] = '1') and
        (form1.OpenDialog1.FileName[i + 3] = '_'))) then
      begin
        bool := true;
      end;

      if (bool) then
      begin
        str := str + form1.OpenDialog1.FileName[i];
      end;
    end;
    form1.fileNameLabel.Caption := str;
    //� ������ ���� ���� ������� �������
    //������������ ���� ���
    tlm.BeginWork;
    //��� ���������� ������������ �����  ����� ������
    tlm.fFlag := true;
    //1 �������
    form1.startReadTlmB.Enabled := not form1.startReadTlmB.Enabled;
    form1.propB.Enabled := false;
    form1.TrackBar1.Enabled := true;
    //������ ��������� �������������
    form1.PanelPlayer.Enabled := true;
  end
  else
  begin
    showMessage('�� ������� ������� ����!');
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.OutTLMfileSize(numWriteByteInFile: int64; var numValBefore: integer);
var
  valInMB: double;
begin
  valInMB := numWriteByteInFile / 1024 / 1024;
  if (trunc(valInMB) mod 10) = 0 then
  begin
    inc(numValBefore);
  end;
  //form1.tlmWriteB.Caption := '';
  //������� ������ ����� � MByte. 1 ���� �� ������� � 2 �����.
  if cOut=7 then
  begin
    form1.tlmWriteB.Caption := '';
  end;
  if cOut=10 then
  begin
    //csk.Enter;
    form1.tlmWriteB.Caption := floatToStrF(valInMB, ffFixed, numValBefore, 2) + ' Mb';
    cOut:=0;
    //csk.Leave;
  end;
  inc(cOut);

  //sleep(5);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteTLMBlockM16(msStartFile: cardinal);
begin
  //block
  wordNumInBlock := {length(masCircle[data.reqArrayOfCircle])}masCircleSize;
  rez := 0;
  mcSec := 0;
  prSEV := 0;
  error := 0;
  rez1M16 := 0;
  rez2 := 0;
  prKPSEV := high(prKPSEV);
  //������� ���������� ���� �����
  iTlmBlockByteArray := 0;
  //pref
  //block num (4b)
  WriteByteToByte(blockNumInfile);
  //word in block (4b)
  WriteByteToByte(wordNumInBlock);
  //time in mc (4b)
  timeBlock := (DateTimeToUnix(Time) * 1000) - msStartFile;
  WriteByteToByte(timeBlock);
  {2 ���� �� 4 �����(8b)}
  //4b
  //rez
  WriteByteToByte(rez);
  //rez
  //WriteByteToByte(rez);
  //kpSev  4b
  WriteByteToByte(prKPSEV);
  //calend
  nowTime := Now;
  //h  (1b)
  hour := HourOf(nowTime);
  WriteByteToByte(hour);
  //m  (1b)
  minute := MinuteOf(nowTime);
  WriteByteToByte(minute);
  //s  (1b)
  sec := SecondOf(nowTime);
  WriteByteToByte(sec);
  //ms (2b)
  mSec := MilliSecondOf(nowTime);
  WriteByteToByte(mSec);
  //mcs
  //mSec:=MilliSecondOf(nowTime);
  //WriteByteToByte(mcSec);
  {rez1 (2b)}
  //1b
  WriteByteToByte(rez1M16);
  //pr SEV. 1b
  WriteByteToByte(prSEV);
  //error (1b)
  WriteByteToByte(error);
  //rez2  (4b)
  WriteByteToByte(rez2);
  //write circle in tlm
  WriteCircleM16;

  //IntToStr(GetFileSizeInMByte(ExtractFileDir(ParamStr(0))+'/Report/'+fileName));

  if (flagFirstWrite) then
  begin
    AssignFile(PtlmFile, ExtractFileDir(ParamStr(0)) + '/Report/' + fileName);
    reset(PtlmFile, 1);
    seek(PtlmFile, length(tlmHeadByteArray));
    flagFirstWrite := false;
  end;
  //���� ���� ������ ������ ��������� ������, �� ���������� ���� �� �����
  if (flagEndWrite) then
  begin
    //wait(100);
    //flagEndWrite:=false;
  end
  else
  begin
    //form1.Memo1.Lines.Add(intToStr(length(tlmBlockByteArray)));
    BlockWrite(PtlmFile, tlmBlockByteArray[0],
      length(tlmBlockByteArray) * sizeof(byte)); //!!!
  end;
  //���������� ���������� �����. ����
  countWriteByteInFile := countWriteByteInFile + length(tlmBlockByteArray);
  //������� ������ ����������� ����� � ������
  OutTLMfileSize(countWriteByteInFile, precision);

  tlmBlockByteArray := nil;
  //form1.Memo1.Lines.Add(intToStr(iTlmBlockByteArray));
  iTlmBlockByteArray := 0;

  //��� ��������
  {if blockNumInfile=4 then
  begin
    closeFile(tlm.PtlmFile);
    inc(blockNumInfile);
  end; }

  inc(blockNumInfile);
  if blockNumInfile >= High(blockNumInfile) then
  begin
    blockNumInfile := 1;
  end;
  //form1.Memo1.Lines.Add(intToStr(blockNumInfile));

end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.WriteTLMBlockM08_04_02_01(msStartFile: cardinal);
begin
  //block
  wordNumInBlock := {length(masCircle[data.reqArrayOfCircle])}masCircleSize;
  rez := 0;
  mcSec := 0;
  prSEV := 0;
  error := 0;
  rez1M08_04_02_01 := 0;
  rez2 := 0;
  //������� ���������� ���� �����
  iTlmBlockByteArray := 0;
  //pref
  //block num (4b)
  WriteByteToByte(blockNumInfile);
  //word in block (4b)
  WriteByteToByte(wordNumInBlock);
  //time in mc (4b)
  timeBlock := (DateTimeToUnix(Time) * 1000) - msStartFile;
  WriteByteToByte(timeBlock);
  //2 ���� �� 4 �����(8b)
  //rez
  WriteByteToByte(rez);
  //rez
  WriteByteToByte(rez);
  //calend
  nowTime := Now;
  //h  (1b)
  hour := HourOf(nowTime);
  WriteByteToByte(hour);
  //m  (1b)
  minute := MinuteOf(nowTime);
  WriteByteToByte(minute);
  //s  (1b)
  sec := SecondOf(nowTime);
  WriteByteToByte(sec);
  //ms (2b)
  mSec := MilliSecondOf(nowTime);
  WriteByteToByte(mSec);
  //mcs
  //mSec:=MilliSecondOf(nowTime);
  //WriteByteToByte(mcSec);
  //rez1 (2b)
  WriteByteToByte(rez1M08_04_02_01);
  //pr SEV
  //WriteByteToByte(prSEV);
  //error (1b)
  WriteByteToByte(error);
  //rez2  (4b)
  WriteByteToByte(rez2);
  //write circle in tlm
  WriteCircleM08_04_02_01;

  if (flagFirstWrite) then
  begin
    AssignFile(PtlmFile, ExtractFileDir(ParamStr(0)) + '/Report/' + fileName);
    reset(PtlmFile, 1);
    seek(PtlmFile, length(tlmHeadByteArray));
    flagFirstWrite := false;
  end;
  //���� ���� ������ ������ ��������� ������, �� ���������� ���� �� �����
  if (flagEndWrite) then
  begin
    //wait(100);
    //flagEndWrite:=false;
  end
  else
  begin
    //form1.Memo1.Lines.Add(intToStr(length(tlmBlockByteArray)));
    BlockWrite(PtlmFile, tlmBlockByteArray[0],
      length(tlmBlockByteArray) * sizeof(byte)); //!!!
  end;

  //���������� ���������� �����. ����
  countWriteByteInFile := countWriteByteInFile + length(tlmBlockByteArray);
  //������� ������ ����������� ����� � ������
  OutTLMfileSize(countWriteByteInFile, precision);

  tlmBlockByteArray := nil;
  //form1.Memo1.Lines.Add(intToStr(iTlmBlockByteArray));
  iTlmBlockByteArray := 0;

  //��� ��������
  {if blockNumInfile=4 then
    begin
      closeFile(tlm.PtlmFile);
      inc(blockNumInfile);
    end; }

  inc(blockNumInfile);
  if blockNumInfile >= High(blockNumInfile) then
    blockNumInfile := 1;
  //form1.Memo1.Lines.Add(intToStr(blockNumInfile));

end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.BeginWork;
begin
  //�������� ����� �� ������
  stream := TFileStream.Create(form1.OpenDialog1.FileName, fmOpenRead);
  //1 ���� �16 131104 �����
  form1.TrackBar1.Max := round((stream.Size - MAXHEADSIZE) / SIZEBLOCK);
  //��������� � ����� �� ������ ���������
  stream.Seek(MAXHEADSIZE, soFromCurrent);
  //��������� �� ������ ����� �� ������ ��������
  //stream.Seek(SIZEBLOCKPREF,soFromCurrent);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.CollectOrbGroup;
begin
  //showMessage('!! '+intToStr(iMasGroup)+' '+intToStr(iBlock));
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure Ttlm.CollectBlockTime;
{var
  time: cardinal;
  iT: integer;
  str: string;}
begin
  {iT := 11;
  time := blockOrbArr[iT];
  dec(iT);
  while iT >= 8 do
  begin
    time := (time shl 8) + blockOrbArr[iT];
    dec(iT);
  end;
  DateTimeToString(str, 'hh:mm:ss', UnixToDateTime(time));
  form1.orbTimeLabel.Caption := str;}
end;
//==============================================================================

function Ttlm.ConvTimeToStr(t: cardinal): string;
var
  h: integer;
  m: integer;
  s: integer;
  str: string;
begin
  s := round(t / 1000);
  if s > 59 then
  begin
    if s > 3600 then
    begin
      //����
      h := trunc(s / 3600);
      m := trunc(s / 60);
      s := s mod 3600;
      if s > 9 then
      begin
        if m > 9 then
        begin
          if h > 9 then
          begin
            str := intToStr(h) + ':' + intToStr(m) + ':' + intToStr(s);
          end
          else
          begin
            str := '0' + intToStr(h) + ':' + intToStr(m) + ':' + intToStr(s);
          end;
        end
        else
        begin
          if h > 9 then
          begin
            str := intToStr(h) + ':' + '0' + intToStr(m) + ':' + intToStr(s);
          end
          else
          begin
            str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + intToStr(s);
          end;
        end;
      end
      else
      begin
        if m > 9 then
        begin
          if h > 9 then
          begin
            str := intToStr(h) + ':' + intToStr(m) + ':' + '0' + intToStr(s);
          end
          else
          begin
            str := '0' + intToStr(h) + ':' + intToStr(m) + ':' + '0' + intToStr(s);
          end;
        end
        else
        begin
          if h > 9 then
          begin
            str := intToStr(h) + ':' + '0' + intToStr(m) + ':' + '0' + intToStr(s);
          end
          else
          begin
            str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + '0' + intToStr(s);
          end;
        end;
      end;
    end
    else
    begin
      //���.
      h := 0;
      m := trunc(s / 60);
      s := s mod 60;
      if s > 9 then
      begin
        if m > 9 then
        begin
          str := '0' + intToStr(h) + ':' + intToStr(m) + ':' + intToStr(s);
        end
        else
        begin
          str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + intToStr(s);
        end;
      end
      else
      begin
        if m > 9 then
        begin
          str := '0' + intToStr(h) + ':' + intToStr(m) + ':' + '0' + intToStr(s);
        end
        else
        begin
          str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + '0' + intToStr(s);
        end;
      end;
    end;
  end
  else
  begin
    //���
    s := round(t / 1000);
    m := 0;
    h := 0;
    if s > 9 then
    begin
      str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + intToStr(s);
    end
    else
    begin
      str := '0' + intToStr(h) + ':' + '0' + intToStr(m) + ':' + '0' + intToStr(s);
    end;
  end;
  result := str;
end;

//==============================================================================
//
//==============================================================================

procedure Ttlm.ParseBlock(countBlock: word);
var
  //������� �������� ������(������)
  i, jG: integer;
  iMasGroupPars: integer;
  time: cardinal;
  iT: integer;
  str: string;
  arrLength:Integer;
begin
  //form1.Memo1.Lines.Add(intToStr(countBlock));
  i := 1;
  //��������� � ������� ���� �� ������. ��� ������ ��������������� ���� ����������� ������
  while i <= countBlock do
  begin
    try
      //������� ��� ����� �������
      iT := 11;
      case infNum of
        //M16
        0:
        begin
          //������ �� ����� ���� ��� ����� ��������
          stream.Read(arr1, sizeof(arr1));
          //CollectBlockTime;
          time := arr1[iT];
          dec(iT);
          while iT >= 8 do
          begin
            time := (time shl 8) + arr1[iT];
            dec(iT);
          end;
          //DateTimeToString(str,'hh:mm:ss',
            //StrToDateTime(intToStr(round(time/1000))));
          str := ConvTimeToStr(time);
          form1.orbTimeLabel.Caption := str; {intToStr(h)+':'+
            intToStr(m)+':'+intToStr(s)}
          //intToStr(round(time/1000));
          //���������� �� ������ ����� �� ������ ��������
          jG := SIZEBLOCKPREF; {+1} //!!!!!

          arrLength:=length(arr1);
          //��������� ���� �� ������ � ������� �������� �� ������
          while jG <=arrLength  - 1 do
          begin
            //�������� ������ ������
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //�������� 11 ��������� �������� ��� ������
              masGroup[iMasGroupPars] := ((arr1[jG + 1] shl 8) +
              arr1[jG]) and 2047;
              //�������� 12 ��������� �������� ��� ����� ������� �������
              masGroupAll[iMasGroupPars] := ((arr1[jG + 1] shl 8) +
              arr1[jG]) and 4095;
              jG := jG + 2;
            end;
            //������� ����������� ����� �� ���������
            form1.TimerOutToDia.Enabled := true;
            //����� �� �������. ����� ���������.
            data.OutToGistGeneral;
          end;
        end;
        //M08
        1:
        begin
          //������ �� ����� ���� ��� ����� ��������
          stream.Read(arr2, sizeof(arr2));
          //CollectBlockTime;
          time := arr2[iT];
          dec(iT);
          while iT >= 8 do
          begin
            time := (time shl 8) + arr2[iT];
            dec(iT);
          end;
          //DateTimeToString(str,'hh:mm:ss',
            //StrToDateTime(intToStr(round(time/1000))));
          str := ConvTimeToStr(time);
          form1.orbTimeLabel.Caption := str; {intToStr(h)+':'+
            intToStr(m)+':'+intToStr(s)}
          //intToStr(round(time/1000));
          //���������� �� ������ ����� �� ������ ��������
          jG := SIZEBLOCKPREF; {+1} //!!!!!

          arrLength:=length(arr2);
          //��������� ���� �� ������ � ������� �������� �� ������
          while jG <= arrLength - 1 do
          begin
            //�������� ������ ������
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //�������� 11 ��������� �������� ��� ������
              masGroup[iMasGroupPars] := ((arr2[jG + 1] shl 8) +
              arr2[jG]) and 2047;
              //�������� 12 ��������� �������� ��� ����� ������� �������
              masGroupAll[iMasGroupPars] := ((arr2[jG + 1] shl 8) +
              arr2[jG]) and 4095;
              jG := jG + 2;
            end;
            //������� ����������� ����� �� ���������
            form1.TimerOutToDia.Enabled := true;
            //����� �� �������. ����� ���������.
            data.OutToGistGeneral;
          end;
         end;
        //M04
        2:
        begin
          //������ �� ����� ���� ��� ����� ��������
          stream.Read(arr3, sizeof(arr3));
          //CollectBlockTime;
          time := arr3[iT];
          dec(iT);
          while iT >= 8 do
          begin
            time := (time shl 8) + arr3[iT];
            dec(iT);
          end;
          //DateTimeToString(str,'hh:mm:ss',
            //StrToDateTime(intToStr(round(time/1000))));
          str := ConvTimeToStr(time);
          form1.orbTimeLabel.Caption := str; {intToStr(h)+':'+
            intToStr(m)+':'+intToStr(s)}
          //intToStr(round(time/1000));
          //���������� �� ������ ����� �� ������ ��������
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr3);
          //��������� ���� �� ������ � ������� �������� �� ������
          while jG <= arrLength - 1 do
          begin
            //�������� ������ ������
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize  do
            begin
              //�������� 11 ��������� �������� ��� ������
              masGroup[iMasGroupPars] := ((arr3[jG + 1] shl 8) +
              arr3[jG]) and 2047;
              //�������� 12 ��������� �������� ��� ����� ������� �������
              masGroupAll[iMasGroupPars] := ((arr3[jG + 1] shl 8) +
              arr3[jG]) and 4095;
              jG := jG + 2;
            end;
            //������� ����������� ����� �� ���������
            form1.TimerOutToDia.Enabled := true;
            //����� �� �������. ����� ���������.
            data.OutToGistGeneral;
          end;
        end;
        //M02
        3:
        begin
          //������ �� ����� ���� ��� ����� ��������
          stream.Read(arr4, sizeof(arr4));
          //CollectBlockTime;
          time := arr4[iT];
          dec(iT);
          while iT >= 8 do
          begin
            time := (time shl 8) + arr4[iT];
            dec(iT);
          end;
          //DateTimeToString(str,'hh:mm:ss',
            //StrToDateTime(intToStr(round(time/1000))));
          str := ConvTimeToStr(time);
          form1.orbTimeLabel.Caption := str; {intToStr(h)+':'+
            intToStr(m)+':'+intToStr(s)}
          //intToStr(round(time/1000));
          //���������� �� ������ ����� �� ������ ��������
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr4);
          //��������� ���� �� ������ � ������� �������� �� ������
          while jG <=arrLength  - 1 do
          begin
            //�������� ������ ������
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //�������� 11 ��������� �������� ��� ������
              masGroup[iMasGroupPars] := ((arr4[jG + 1] shl 8) +
              arr4[jG]) and 2047;
              //�������� 12 ��������� �������� ��� ����� ������� �������
              masGroupAll[iMasGroupPars] := ((arr4[jG + 1] shl 8) +
              arr4[jG]) and 4095;
              jG := jG + 2;
            end;
            //������� ����������� ����� �� ���������
            form1.TimerOutToDia.Enabled := true;
            //����� �� �������. ����� ���������.
            data.OutToGistGeneral;
          end;
        end;
        //M01
        4:
        begin
          //������ �� ����� ���� ��� ����� ��������
          stream.Read(arr5, sizeof(arr5));
          //CollectBlockTime;
          time := arr5[iT];
          dec(iT);
          while iT >= 8 do
          begin
            time := (time shl 8) + arr5[iT];
            dec(iT);
          end;
          //DateTimeToString(str,'hh:mm:ss',
            //StrToDateTime(intToStr(round(time/1000))));
          str := ConvTimeToStr(time);
          form1.orbTimeLabel.Caption := str; {intToStr(h)+':'+
            intToStr(m)+':'+intToStr(s)}
          //intToStr(round(time/1000));
          //���������� �� ������ ����� �� ������ ��������
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr5);
          //��������� ���� �� ������ � ������� �������� �� ������
          while jG <=arrLength - 1 do
          begin
            //�������� ������ ������
            //CollectOrbGroup;
            for iMasGroupPars := 1{0} to masGroupSize do
            begin
              //�������� 11 ��������� �������� ��� ������
              masGroup[iMasGroupPars] := ((arr5[jG + 1] shl 8) +
              arr5[jG]) and 2047;
              //�������� 12 ��������� �������� ��� ����� ������� �������
              masGroupAll[iMasGroupPars] := ((arr5[jG + 1] shl 8) +
              arr5[jG]) and 4095;
              jG := jG + 2;
            end;
            //������� ����������� ����� �� ���������
            form1.TimerOutToDia.Enabled := true;
            //����� �� �������. ����� ���������.
            data.OutToGistGeneral;
          end;
        end;
      end;
      form1.TrackBar1.Position := form1.TrackBar1.Position +form1.TrackBar1.PageSize;
    finally
      //��������� ������ ��� ����� �� �� ����� �����.
      if stream.Position >= stream.Size then
      begin
        form1.TimerPlayTlm.Enabled := false;
        form1.TimerOutToDia.Enabled := false;
        i := countBlock + 1;
        form1.diaSlowAnl.Series[0].Clear;
        form1.diaSlowCont.Series[0].Clear;
        form1.fastDia.Series[0].Clear;
        form1.fastGist.Series[0].Clear;
        form1.gistSlowAnl.Series[0].Clear;
        //form1.fileNameLabel.Caption:='';
      end;
    end;
    inc(i);
    //!!
    {sleep(250);
    Application.ProcessMessages;}
  end;
end;
//==============================================================================

procedure TForm1.startReadACPClick(Sender: TObject);
var
  intPointNum:integer;
begin
  testOutFalg:=true;

  //setlength(data.masFastVal, trunc(form1.fastGist.BottomAxis.Maximum)-2);
  //data.masFastVal:=nil;
  //intPointNum:=trunc(form1.fastGist.BottomAxis.Maximum);
  setlength(data.masFastVal, intPointNum);
  //�������. �������� ��� �����. �����. ������� ���� �������
  //��
  acumAnalog := 0;
  //����
  acumTemp:=0;
  //��
  acumContact := 0;
  //�
  acumFast := 0;
  //���
  acumBus := 0;
  //������������ ���. ������.
  form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
  //��������� ����������� ������ �������
  GetAddrList;
  //��������� ������ ���������� �������
  SetOrbAddr; 
  //���������� ���������������
  form1.gistSlowAnl.AllowZoom:=false;
  form1.gistSlowAnl.AllowPanning:=pmNone;

  form1.fastGist.AllowZoom:=false;
  form1.fastGist.AllowPanning:=pmNone;

  form1.tempGist.AllowZoom:=False;
  form1.tempGist.AllowPanning:=pmNone;
  //�������� ������������ �������
  if (data.GenTestAdrCorrect) then
  begin
    //������ ��� ������ � ���
    tlm := Ttlm.CreateTLM;
    //��������� �������� ��������
    form1.tlmPSpeed.Position := 3;
    form1.tlmPSpeed.Enabled:=true;
    if form1.startReadACP.Caption = '�����' then
    //�����
    begin
      //AssignFile(textTestFile,'TextTestFile.txt');
      //Rewrite(textTestFile);
      //AssignFile(swtFile,ExtractFileDir(ParamStr(0)) + '/Report/' + '777.txt');
      //ReWrite(swtFile);
      //�������. ���� ������ �� ���� ������
      flagEnd:=false;
      //���������� ������� ����������
      data.FillAdressParam;
      form1.startReadACP.Caption := '����';
      //����� ������ ������
      form1.tlmWriteB.Enabled := true;
      form1.startReadTlmB.Enabled:=false;
      form1.propB.Enabled:=false;

      //���������� ��� � ������
      if  (not boolFlg) then
      begin
        acp := Tacp.InitApc;
        //������������ � ������ � ���
        acp.CreateApc;
        //�������� ���� ������ � ���
        pModule.START_ADC();
        //boolFlg:=true;
      end
      else
      begin
        //acp := Tacp.InitApc;
        //
        //pModule.START_ADC();
      end;
    end
    else
    //����
    begin

      //closeFile(swtFile);
      {form1.startReadACP.Caption := '�����';
      form1.startReadACP.Enabled:=false;
      form1.tlmWriteB.Enabled := false;
      form1.propB.Enabled:=true;
      //flagEnd:=true;
      // wait(50);
      //���������� � ������ � 0
      //data.Free;
      //data := Tdata.CreateData;
      pModule.STOP_ADC();
      //flagEnd:=true;
      //wait(50);
      WaitForSingleObject(hReadThread,1500);
      //���� ����� ������ , �� ���������� ������
      if hReadThread <> THANDLE(nil) then
      begin
        CloseHandle(hReadThread);
        hReadThread:=THANDLE(nil);
      end;
      flagEnd:=true;
      //acp.Free;
      //pModule.ReleaseLInstance();
      //pModule:=nil;
      wait(50);}

      //form1.Visible:=false;


      //CloseFile(textTestFile);
      data.graphFlagFastP := false;

      //Application.ProcessMessages;
      sleep(50);
      //Application.ProcessMessages;

      if ((form1.tlmWriteB.Enabled)and
          (not form1.startReadTlmB.Enabled)and
          (not form1.propB.Enabled))  then
      begin
        //��������� ������ � ���
        pModule.STOP_ADC();
      end;
      //�������� ��� ���������� �����
      flagEnd:=true;
      wait(20);
      //while (True) do Application.ProcessMessages; //!!!!
      WinExec(PChar('OrbitaMAll.exe'), SW_ShowNormal);
      wait(20);
      //�������� ���������� �� �����������.
      Application.Terminate;
    end;
  end
  else
  begin
    ShowMessage('��������� ������������ �������!');
  end;
end;

//�������� ��������� � ������������� ������ �����������
//��� �������� ������ ���� ��� � ������.

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //���� �������� ���������� ��� ������ �� ��������� ������ � ���. ����� ���������.
  if ((form1.tlmWriteB.Enabled)and(not form1.startReadTlmB.Enabled)and
      (not form1.propB.Enabled))  then
  begin
    //��������� ������ � ���
    pModule.STOP_ADC();
  end;

  //�������� ��� ���������� �����
  flagEnd:=true;
  wait(20);
  //�������� ���������� �� �����������.
  Application.Terminate;
  //halt
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  path:string;

begin
  orbOk:=False;
  orbOkCounter:=0;
  boolFlg:=false;
  csk:=TCriticalSection.Create;
  //������ ��� ������ � ��������
  data := tdata.CreateData;
  //��������� ��������
  form1.diaSlowAnl.LeftAxis.Maximum := 1025.0;
  form1.gistSlowAnl.BottomAxis.Maximum := 300;
  form1.gistSlowAnl.BottomAxis.Minimum := 0;
  form1.gistSlowAnl.LeftAxis.Maximum := 1025;
  form1.gistSlowAnl.LeftAxis.Minimum := 0;
  path:=ExtractFileDir(ParamStr(0))+'\ConfigDir\property.ini';
  propIniFile:=TIniFile.Create(path);
  //������ �� ����� ���������� ������ ��������� path.
  propStrPath:=propIniFile.ReadString('lastPropFile','path','');
  //��������� ���� �� ����� ���� �������� �� ��.
  if FileExists(propStrPath) then
  begin
    //����, �� ��� ������ ������ ��
    if propStrPath='' then
    begin
      //����������� ��������� ������������
      //���. ���.
      form1.propB.Enabled := true;
      //�����
      form1.startReadACP.Enabled := false;
      //������
      form1.startReadTlmB.Enabled := false;
      //������ � tlm
      form1.tlmWriteB.Enabled := false;
      //������ ������
      form1.PanelPlayer.Enabled := false;
      //�������� ��������� � �����
      form1.TrackBar1.Enabled := false;
      //�������� ��������
      form1.tlmPSpeed.Enabled:=false;
      //���������� � ���� �������
      form1.saveAdrB.Enabled:=false;
    end
    else
    //����.
    begin
      form1.propB.Enabled := true;
      form1.startReadACP.Enabled := true;
      form1.startReadTlmB.Enabled := true;
      form1.tlmWriteB.Enabled := false;
      form1.PanelPlayer.Enabled := false;
      form1.TrackBar1.Enabled := false;
      form1.tlmPSpeed.Enabled:=false;
      form1.saveAdrB.Enabled:=true;
      //�������� ����� ������� � ������� ������ �������
      form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
      //��������� ����������� ������ �������
      GetAddrList;
      //��������� ������ ���������� �������
      SetOrbAddr;
    end;
  end
  else
  //������ ����� ���. ����������� ���.
  begin
    form1.propB.Enabled := true;
    form1.startReadACP.Enabled := false;
    form1.startReadTlmB.Enabled := false;
    form1.tlmWriteB.Enabled := false;
    form1.PanelPlayer.Enabled := false;
    form1.TrackBar1.Enabled := false;
    form1.tlmPSpeed.Enabled:=false;
    form1.saveAdrB.Enabled:=false;
  end;
  //�������� ���� ��������
  propIniFile.Free;
end;

procedure TForm1.upGistSlowSizeClick(Sender: TObject);
begin
  form1.downGistSlowSize.Enabled := true;
  if form1.gistSlowAnl.BottomAxis.Maximum <=form1.gistSlowAnl.BottomAxis.Minimum + 20 then
  begin
    form1.upGistSlowSize.Enabled := false
  end
  else
  begin
    form1.gistSlowAnl.BottomAxis.Maximum := form1.gistSlowAnl.BottomAxis.Maximum - 10;
  end;
end;

procedure TForm1.downGistSlowSizeClick(Sender: TObject);
begin
  form1.upGistSlowSize.Enabled := true;
  form1.gistSlowAnl.BottomAxis.Maximum := form1.gistSlowAnl.BottomAxis.Maximum + 10;
  if form1.gistSlowAnl.BottomAxis.Maximum >= 700 then
  begin
    form1.downGistSlowSize.Enabled := false;
  end;
end;

procedure TForm1.Series1Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //�������� ������� � ����. � � ������ �����������
  //���� ������ ��� ����������� � ��������
  //form1.OrbitaAddresMemo.Enabled:= not form1.OrbitaAddresMemo.Enabled;
  //form1.Memo1.Enabled:= not form1.Memo1.Enabled;
  if (data.graphFlagSlowP) then
  begin
    form1.gistSlowAnl.Series[0].Clear;
    data.graphFlagSlowP := false;
  end
  else
  begin
    data.graphFlagSlowP := true;
    //form1.dia.Canvas.MoveTo(form1.dia.Width-1051,form1.dia.Height-33);
    data.chanelIndexSlow := ValueIndex;
  end;
end;

procedure TForm1.TimerOutToDiaTimer(Sender: TObject);
var
  orbAdrCount: integer;
begin
  //������������� ������� ��������� ������ ������.
  orbAdrCount := 0;
  //������� ��� �������� ���������� ���������� �������
  data.analogAdrCount := 0;
  //������� ��� �������� ���������� ���������� �������
  data.contactAdrCount := 0;
  //������� ��� �������� ���������� ���������� �������
  data.tempAdrCount := 0;
  //�������� ����� ��� ���������� ������
  form1.diaSlowAnl.Series[0].Clear;
  form1.diaSlowCont.Series[0].Clear;
  form1.fastDia.Series[0].Clear;
  form1.tempDia.Series[0].Clear;
  //sleep(3);
  //��������������� ��������� ������ �� ������� ������
  //������, �������� ������ �������� � ������� �� ������
  while orbAdrCount <= iCountMax - 1 do // iCountMax-1
  begin
    data.OutToDia(masElemParam[orbAdrCount].numOutElemG,
      masElemParam[orbAdrCount].stepOutG, {length(masGroup)}masGroupSize, //���������11
      orbAdrCount, masElemParam[orbAdrCount].adressType,
      masElemParam[orbAdrCount].bitNumber,
      masElemParam[orbAdrCount].numBusThread,
      masElemParam[orbAdrCount].adrBus,
      masElemParam[orbAdrCount].numOutPoint);
    inc(orbAdrCount);
  end;
  form1.TimerOutToDia.Enabled := false;
end;

//==============================================================================
//��������� �������
//==============================================================================

//==============================================================================
//
//==============================================================================

constructor Tdata.CreateData;
begin
  countForMG:=0;
  countErrorMG:=0;
  countEvenFraseMGToMG:=0;

  countForMF:=0;
  countErrorMF:=0;
  //���� ��� ������ ������� ��� ���. ������� ���
  flagWtoBusArray:=false;
  //���� ��� ������ �� ����������� ���������� � ���������� (��������� �������)
  graphFlagSlowP := false;
  graphFlagBusP := false;
  graphFlagTempP := false;

  //���� ������ ����� ������� �� �������� �� ����� ���������� ����
  numP := 0;
  numPfast := {0}1;
  porog := 0;
  //���. ����. ����� �������� ������
  modC := false;

  //���������� ����������� ������.
  buffDivide := 0;
  //������� ������ �� fifo �����
  fifoLevelRead := 1;
  //������� ��� ������ � ������ fifo �����
  fifoLevelWrite := 1;
  //������� ���������� ������������ �����
  fifoBufCount := 0;

  //�������� ��� �������� ���������� ����� ���� � ���� ������
  numRetimePointUp := 0;
  numRetimePointDown := 0;

  //���. ���� �������� ��� ���������� ������� ������
  iMasGroup := {0}1;
  bufMarkGroup := 0;
  bufNumGroup:=0;
  flfl := false;
  bufMarkCircle := 0;
  flagCountGroup := false;
  fraseCount := 1;
  groupCount := 1;
  fraseMarkFl := false;
  //���. ���� ����� �������� ������
  qSearchFl := false;
  iMasCircle := {0}1;

  //���������� ���� ��� ������ ������ �����
  firstFraseFl := false;

  //������� ����� ��� ������� ����������� ����
  iBit := 1;
  //����. ����������� �����
  bitSizeWord := 12;
  //������� ����, ��������� ����� ����������� � 1. ����� � 1 �� 16.
  wordNum := 1;
  //������ ��� ����� �����.
  //codStr:='';
  codStr := 0;
  //��������� ������������� ����� ������ ������ ������
  flagOutFraseNum := false;
  //������� ���� ,��������� ����� ����������� � 1. ����� � 1 �� 128.
  myFraseNum := 1;
  //��������� �������� ������� ������
  nMarkerNumGroup := 1;
  //��������� ����. ������� ������
  markerGroup := 0;
  //��������� ����. ������� ������ ������
  markerNumGroup := 0;
  //��������� ����. ���������� ��� ������� ������� ������ �16
  flagL := true;
  startWriteMasGroup := false;
  //���� ��� ������������� ���������� ������� ����� � 1 ����� ������� �����
  flBeg := false;

  //SetLength(busArray,NUM_BUS_ELEM);
  iBusArray:=0;
  //bool:=true;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.Add(signalElemValue: integer); //value= signalElemValue
var
  iOutInFile: integer;
begin
  //����
  if signalElemValue >= porog then
  begin
    //������� ����
    inc(numRetimePointUp);
    //����������� ������� ����� ���� ������
    outStep := round(numRetimePointDown / (10 / 3.145728));
    //���� ��� ���������� �������, �� 1
    if ((numRetimePointUp = 1)and(outStep = 0)) then
    begin
      outStep := 1;
    end;

    for iOutInFile := 1 to outStep do
    begin
      fifoMas[fifoLevelWrite] := 0;
      inc(fifoLevelWrite);
      //������� �������� ����� � �������
      inc(fifoBufCount);
      if (fifoLevelWrite > FIFOSIZE) then
      begin
        fifoLevelWrite := 1;
      end;
    end;
    numRetimePointDown := 0;
  end
  else
  begin
    //������� ����
    inc(numRetimePointDown);
    //����������� ������� ����� ���� ������
    outStep := round(numRetimePointUp / (10 / 3.145728));
    if ((numRetimePointDown = 1)and(outStep = 0)) then
    begin
      outStep := 1;
    end;
    for iOutInFile := 1 to outStep do
    begin
      fifoMas[fifoLevelWrite] := 1;
      inc(fifoLevelWrite);
      //������� �������� ����� � �������
      inc(fifoBufCount);
      if (fifoLevelWrite > FIFOSIZE) then
      begin
        fifoLevelWrite := 1;
      end;
    end;
    numRetimePointUp := 0;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
{procedure TData.AddValueInMasDiaValue(numFOut:integer;step:integer;
  masGSize:integer;var numP:integer );
var
  nPoint:integer;
  begin
  nPoint:=numFOut;
  while nPoint<=masGSize do
  begin
    //���������� ������ ��� 1 �������
    setlength(masDiaValue,numP+1);
    masDiaValue[numP]:=masGroup[nPoint];
    inc(numP);
    nPoint:=nPoint+step;
  end;
end;}
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.SearchFirstFraseMarker;
begin
  //������ �������� ������� ����� � ��������� ������
  current := Read;
  Inc(countForMF);
  //���� ������ �������� �����.
  //����� 24 �.� ����������� ������ ���� �������� ���� ������� � �������� ����� � ���������� ������
  if ((current = 0) and (Read(24) = 1) and (Read(48) = 1) and
      (Read(72) = 1) and (Read(96) = 1) and (Read(120) = 0) and
      (Read(144) = 0) and (Read(168) = 0) and (Read(216) = 1) and
      (Read(240) = 0) and (Read(264) = 0) and (Read(288) = 1) and
      (Read(312) = 1) and (Read(336) = 0) and (Read(360) = 1)) then
  begin
    //����� ������ ������ �������� ����� � � ���������� ����� ��� ���������
    firstFraseFl := true;
    //������� ���������� (����� ����� ������)����� ����� ������� ������ ����� ������ �����������
    pointCount := 383;
    //���������� �� ������� �����
    dec(fifoLevelRead);
    inc(fifoBufCount);
  end
  else
  begin
    Inc(countErrorMF);
  end;

  if countForMF={100}127 then
  begin
    countForMF:=0;
    OutMF(countErrorMF);
    //Form1.Memo1.Lines.Add(IntToStr(22));
    countErrorMF:=0;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.OutToGistGeneral;
begin
  //����� �� ������ ��� ���������� � ����������
  if (graphFlagSlowP) then
  begin
    OutToGistSlowAnl(masElemParam[chanelIndexSlow].numOutElemG,
      masElemParam[chanelIndexSlow].stepOutG,
      {length(masGroup)}masGroupSize, data.numP);
  end;

  //����� �� ������ ������. ����������
  if (graphFlagTempP) then
  begin
    OutToGistTemp(masElemParam[chanelIndexTemp].numOutElemG,
      masElemParam[chanelIndexTemp].stepOutG,
      {length(masGroup)}masGroupSize, data.numP);
  end;

  //����� �� ��������� ��� ������� ����������
  if (graphFlagFastP)and(testOutFalg) then
  begin
    OutToGistFastParam(masElemParam[chanelIndexFast].numOutElemG,
      masElemParam[chanelIndexFast].stepOutG, {length(masGroup)}masGroupSize,
      masElemParam[chanelIndexFast].adressType, data.numPfast,
      masElemParam[chanelIndexFast].bitNumber);
  end;




  // ����� �� ��������� ��� ���
  {if (graphFlagBusP) then
  begin
    OutToGistBusParam(masElemParam[chanelIndexFast].numOutElemG,
      masElemParam[chanelIndexFast].stepOutG, {length(masGroup)}{masGroupSize,
      masElemParam[chanelIndexFast].adressType, data.numPfast,
      masElemParam[chanelIndexFast].bitNumber);
  end;}
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.FillArrayGroup;
begin
  //����� ������� 11 ��������. ������� �����������. ��-������� ���.
  wordInfo := (codStr and 2047) {shr 1};
  //12 �����
  masGroupAll[groupWordCount] := codStr;
  masGroup[groupWordCount] := wordInfo;
  inc(groupWordCount);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.FillArrayCircle;
begin
  masCircle[reqArrayOfCircle][imasCircle] := codStr;
  inc(imasCircle);
  //��������� 65535 ���������
  if imasCircle = {length(masCircle[reqArrayOfCircle])}masCircleSize+1 then
  begin
    imasCircle := 1;
    //������ ����� ��������. ����� � ���� ���
    //���� ����� � ��� ������� �� ����� ����(���� ������ � ����)
    if (tlm.flagWriteTLM) then
    begin
      if infNum = 0 then
      begin
        //M16
        tlm.WriteTLMBlockM16(tlm.msTime);
      end
      else
      begin
        //������ ���������������
        tlm.WriteTLMBlockM08_04_02_01(tlm.msTime);
      end;
      {form1.WriteTLMTimer.Enabled:=true;}
    end;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.CollectMarkNumGroup;
begin
  if ((fraseNum = 2) or (fraseNum = 4) or (fraseNum = 6) or (fraseNum = 8) or
    (fraseNum = 10) or (fraseNum = 12) or (fraseNum = 14)
    ) then
  begin
    //��������� 12 ���, ���� ��� 1
    //�� � ����� ������� ������� 1
    if ((codStr and 2048) = 2048) then
    begin
      markerNumGroup := (markerNumGroup shl 1) or 1;
    end
    else
      //0 � ����� ������� ������� 0
    begin
      markerNumGroup := markerNumGroup shl 1;
    end;
    if fraseNum = 14 then
    begin
      inc(nMarkerNumGroup);
      markerNumGroup := 0;
    end;
  end;
end;

//=============================================================================

//==============================================================================
//
//==============================================================================

procedure TData.CollectMarkGroup;
begin
  //��������� 12 ���, ���� ��� 1 �� � ����� ������� ������� 1
  if ((codStr and 2048) = 2048) then
  begin
    markerGroup := (markerGroup shl 1) or 1;
  end
  else
  begin
    //0 � ����� ������� ������� 0
    markerGroup := markerGroup shl 1;
  end;
end;
//==============================================================================

//==============================================================================
//���� 32-� ��������� ���� � ������� � ����
//==============================================================================
procedure FillSwatWord;
var
  iOrbWord:integer;
  wordToFile:integer;
begin
  iOrbWord:=1;
  wordToFile:=0;
  //���� ���� ������� 2
  while iOrbWord<={length(masGroup)}masGroupSize do
  begin
     //��������� 11 ���, �������� ����� ��� ���
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //����� ������ �����
      //����� 10 ��. �����
      wordToFile:=masGroup[iOrbWord] and 1023; //�1�12
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+1] shl 10)+wordToFile;//�2�12
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+2] shl 11)+wordToFile;//�1�22
      //writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+4;
  end;
  //������ 1 ������ ������� ������   1024 ����� ������
  {while iOrbWord<=length(masGroup)-1 do
  begin
    //��������� 11 ���, �������� ����� ��� ���
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //����� ������ �����
      //����� 10 ��. �����
      wordToFile:=masGroup[iOrbWord] and 1023;
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+2] shl 10)+wordToFile;
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+4] shl 11)+wordToFile;
      writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+5;
  end;

  iOrbWord:=1;
  //������ 2 ������ ������� ������   512 ���� ������
  while iOrbWord<=round(length(masGroup)/2)-1 do
  begin
    //��������� 11 ���, �������� ����� ��� ���
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //����� 10 ��. �����
      wordToFile:=masGroup[iOrbWord] and 1023;
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+2] shl 10)+wordToFile;
      //����. 11 ��. �����
      wordToFile:=(masGroup[iOrbWord+4] shl 11)+wordToFile;
      writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+5;
  end;}
end;
//==============================================================================

//==============================================================================
//���������� ���� ���. ����� � ����� ������
//==============================================================================
procedure TData.FillBitInWord;
begin
  //��������� �������� �� �����. ������ �������� �������� ������
  current := Read;
  //������ � ������� �������� 12 ��������� �����
  if current = 1 then
  begin
    codStr := (codStr shl 1) or 1;
  end
  else
  begin
    codStr := codStr shl 1;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.OutDate;
begin
  //���� ���� ��� ����� //!!!!!
  //FillSwatWord;
  //�������� ������ ��� ������ �� ���������
  form1.TimerOutToDia.Enabled := true;
  //����� �� �������. ����� ���������.
  OutToGistGeneral;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.AnalyseFrase;
begin
  //��� ������ � ���. ��� ������ � ������� �����
  if (flBeg) then
  begin
    flSinxC := true;
  end;
  //���� ������� ������ �� 12 ���
  while iBit <= bitSizeWord do
  begin
    {������� ��� �������� ����� �� 383. ��� �������� ������ ������� �����}
    if pointCount = -1 then
    begin
      //����� ����� ����������� �������
      firstFraseFl := false;
      break;
    end;
    dec(pointCount);

    FillBitInWord;

    if iBit = bitSizeWord then
    begin
      //���� ����� ����� 1 ������ ��� ����� �����
      if wordNum = 1 then
      begin
        //form1.Memo1.Lines.Add('����� �'+IntToStr(fraseNum));
        //��������� ��� �� ����� ����� 128 �����.
        if (flagOutFraseNum) then
        begin
          {if fraseNum=126 then
           begin
            SaveBitToLog('����� 126:'+codStr);
           end;}
          //SaveBitToLog('����� �'+IntToStr(fraseNum)+' ');
          if fraseNum = 1 then
          begin
            //�������� � 0 �.� ������ ������ � 0
            groupWordCount := {0}1;
            //��������� ������ � ������ ������
            startWriteMasGroup := true;
          end;
        end;
        //-----------------------
        //����� ������� �����
        //-----------------------
        //������� ������ �����
        if (myFraseNum mod 2 = 0) then
        begin
          //���� ������� ������ ������
          CollectMarkNumGroup;
          //���� ������� ������
          CollectMarkGroup;

          Inc(countEvenFraseMGToMG);
          
          //��������� �� ������� �� ������� ������ ��� ������ �����
          if ((markerGroup = 114{112}) or (markerGroup = 141)) then
          //����� ������
          begin
            if data.fraseNum <> 128 then
            begin
              if data.flagL = true then
              begin
                data.fraseNum := 128;
              end;
              data.flagL := true;
            end;
            if data.fraseNum = 128 then
            begin
              data.flagL := false;
              //---------------------------
              if data.markerGroup = 114{112} then
              //����� ������ ������
              begin
                //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' ��'); //TO-DO <><><>
                Inc(countForMG);
                //+1 ��
                if countEvenFraseMGToMG<>64 then
                begin
                  //���� �� �� ����
                  Inc(countErrorMG);
                end;

                if countForMG={100}31 then
                begin
                  //������� ����� ����� �� ��
                  OutMG(countErrorMG);
                  countErrorMG:=0;
                  countForMG:=0;
                end;

                countEvenFraseMGToMG:=0;
                //�������� c��� � ������ ������ �������
                //data.groupWordCount:=0;
                //��������� ������ � ������ ������
                //data.startWriteMasGroup:=true;
              end;
              //----------------------------
              //����
              //----------------------------
              if data.markerGroup = 141 then
              //����� ������ �����
              begin
                //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' ��');
                countEvenFraseMGToMG:=0;
                //SaveBitToLog('����� ������ '+'32');
                flBeg := false;
                if (tlm.flagWriteTLM) then
                begin
                  flBeg := true;
                end;
              end;
              //----------------------------
              data.markerGroup := 0;
              //����������� ����� ������ ������ ������
              data.flagOutFraseNum := true;
            end;
          end
          //====
          {else
          begin
            form1.Memo2.Lines.Add(intTostr(markerGroup));
          end;}
          //====
        end;

        //----------------------------------
        inc(data.myFraseNum);
        //��������� ��������� ����,
        //��� ���� ����� �� ����� �� �������.
        //��� ��������� ���������.
        if data.myFraseNum = 129 then
        begin
          data.myFraseNum := 1;
        end;
        inc(data.fraseNum);
        //��������� ��������� ����,
        //��� ���� ����� �� ����� �� �������.
        //��������� ��� ������.
        if data.fraseNum = 129 then
        begin
          data.fraseNum := 1;
        end;
      end;

      // � ������� ����� ���������������� 12 ���,
      // �� ��� ������� �������� �����
      //����� ������ ����� � ���������� ��������
      //SaveBitToLog('C���o �'+IntToStr(wordNum)+
      //' �������� �����:'+IntToStr(codStr));
      if (startWriteMasGroup) then
      begin
        FillArrayGroup;
        //���� �������� ����. � ������� ����� ������
        if (flSinxC) then
        begin
          FillArrayCircle;
        end;
        //��������� �� �������� �� ������ ������
        // ����������� ����� � 0 �� 2047. ������� 2048
        if groupWordCount = {length(masGroup)}masGroupSize+1 then
        begin
          OutDate;
        end;
      end;
      codStr := 0;
      inc(wordNum);
      //�������� ��������� ����, ��� ���� �����
      //�� ����� �� ������� ��������� ����
      if wordNum = 17 then
      begin
        wordNum := 1;
      end;
    end;

    //� ������� ������. �����. ������ � ��� ����� �� ����������
    if flagEnd then
    begin
      form1.TimerOutToDia.Enabled := false;
      data.graphFlagSlowP := false;

      data.graphFlagFastP:= false;
      data.graphFlagTempP:= false;
      break;
    end;
    //������. ������� ����� ���. ����� ������
    inc(iBit);
    if iBit = 13 then
    begin
      iBit := 1;
    end;
  end;
end;

//==============================================================================

//==============================================================================
//���� �������� �������� T22
//�� ���� �������� 12 ��������� ��������
//==============================================================================

function Tdata.BuildFastValueT22(value: integer; fastWordNum: integer): integer;
var
  //����� �������
  fastValBuf: word;
begin
  fastValBuf := 0;
  //�������� ������ ����� �������
  if fastWordNum = 1 then
  begin
    //��������� 12 ���. ������� 17
    {fastValBuf:=value shl 5;
    //��������� 6 �����. �����. 11 ��� ���. ���� 5. 5 ������� �����
    fastValBuf:=fastValBuf shr 11;}
    //1
    if (value and 1024 = 1024) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
    //2
    if (value and 512 = 512) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
    //3
    if (value and 256 = 256) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
    //4
    if (value and 128 = 128) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
    //5
    if (value and 64 = 64) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
    //6 ���
    if (value and 4 = 4) then
    begin
      //�������� � ������� ������ ������ 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //�������� � ������� ������ ������ 0
      fastValBuf := fastValBuf shl 1;
    end;
  end;
  if fastWordNum = 2 then
  begin
    //����������� 6 ������� �����
    fastValBuf := value shl 10; //6 � 16
    //����������� 9 ������� �����. 3 ������� ����.
    fastValBuf := fastValBuf shr 13;
    //4 ���
    if (value and 2 = 2) then
    begin
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      fastValBuf := fastValBuf shl 1;
    end;
    //5 ���
    if (value and 1 = 1) then
    begin
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      fastValBuf := fastValBuf shl 1;
    end;
    //6 ���
    if (value and 2048 = 2048) then
    begin
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      fastValBuf := fastValBuf shl 1;
    end;
  end;
  result := fastValBuf;
end;
//==============================================================================


//==============================================================================
//���� �������� �������� T22
//�� ���� �������� 12 ��������� ��������
//==============================================================================
function Tdata.BuildFastValueT24(value: integer; fastWordNum: integer): integer;
var
  //����� �������. �������� 6 ��������� ��������
  fastValBuf: byte;
begin
  fastValBuf := 0;
  //�������� ������ ����� �������. ������� 6 ���
  if fastWordNum = 1 then
  begin
    fastValBuf:=value and 63;
  end;
  //�������� ������ ����� �������. ������� 6 ���
  if fastWordNum = 2 then
  begin
    fastValBuf:=value and 4032;
  end;
  result := fastValBuf;
end;
//==============================================================================


//==============================================================================
//���� �������� ���
//�� ���� �������� ��� 12 ��������� ��������
//==============================================================================
function Tdata.BuildBusValue(highVal:word;lowerVal:word):word;
var
  busValBuf:word;
  bufH,bufL:word;
begin
  busValBuf:=0;
  bufH:=highVal and 2040;
  bufH:=bufH shr 3;
  bufL:=lowerVal and 2040;
  bufL:=bufL shr 3;
  bufH:=bufH shl 8;
  //� ����� ���������� ������ ����������� 12,3,2 � 1 ���.
  busValBuf:=bufH+bufL;
  //form1.Memo1.Lines.Add(intToStr(busValBuf));
  result:=busValBuf;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function TData.CollectBusArray(var iBusArray:integer):boolean;
var
  orbAdrCount:integer;
  maxPointInAdr:integer;
  nPoint:integer;
  offsetForYalkBus:short;
  highVal:word;
  lowerVal:word;
  iParity:integer;

  iCount:integer;

  lll:integer;

  busArrLen:integer;
begin
  //����� ��� ��� ����������
  if form1.PageControl1.ActivePageIndex = 2 then
  begin
    orbAdrCount:=0;
    while orbAdrCount <= iCountMax - 1 do // iCountMax-1
    begin
      if masElemParam[orbAdrCount].adressType = 6 then
      begin
        iParity:=0;
        //��������� ���������� ����� � ��������� ������
        maxPointInAdr := 0;
        nPoint := masElemParam[orbAdrCount].numOutElemG;
        while nPoint <= {length(masGroup)}masGroupSize do
        begin
          inc(maxPointInAdr);
          nPoint := nPoint + masElemParam[orbAdrCount].stepOutG;
        end;
        offsetForYalkBus := masElemParam[orbAdrCount].stepOutG *
        (masElemParam[orbAdrCount].numOutPoint - 1);
        nPoint := masElemParam[orbAdrCount].numOutElemG + offsetForYalkBus;
        nPoint := nPoint{ - 1};
        // lll:=length(masGroup);
        // form1.Memo1.Lines.Add(intToStr(lll));
        // lll:=length(masGroupAll);
        // form1.Memo1.Lines.Add(intToStr(lll));
        while nPoint<{length(masGroup)}masGroupSize-masElemParam[orbAdrCount].stepOutG do
        begin
          offsetForYalkBus := masElemParam[orbAdrCount].stepOutG *
          (masElemParam[orbAdrCount].numOutPoint - 1);
          nPoint := masElemParam[orbAdrCount].numOutElemG + offsetForYalkBus;
          nPoint := nPoint{ - 1};
          if nPoint=1024 then
          begin
            //form1.Memo1.Lines.Add(intToStr(masGroupAll[nPoint])
            // +' '+intToStr(nPoint));
          end;
          if iParity mod 2 =0 then
          begin
            //���������� �������� ����� ������ �� ������� ������ ����� ���
            highVal:=masGroupAll[nPoint];
            //form1.Memo1.Lines.Add(intToStr(masGroupAll[nPoint])
            // +' '+intToStr(nPoint));
          end
          else
          begin
            //���������� �������� ����� ������ � ������� ������ ����� ���
            lowerVal:=masGroupAll[nPoint];
            //form1.Memo1.Lines.Add(intToStr(masGroupAll[nPoint])
            //+' '+intToStr(nPoint));
            //���� ������ (������������������ �� 65535,65535,65535)
            if  ((BuildBusValue(highVal,lowerVal)=65535)and   //!!77
              (not flagWtoBusArray))  then
            begin
              busArray[iBusArray]:=BuildBusValue(highVal,lowerVal);
              inc(iBusArray);
              if iBusArray=3 then
              begin
                //��������� 3 ��������
                if ((busArray[iBusArray-1]=65535)and(busArray[iBusArray-2]=65535)and
                (busArray[iBusArray-3]=65535)) then
                begin
                  //����� ������, ����� ��������� ������
                  flagWtoBusArray:=true;
                end
                else
                begin
                  //�� �����, ���� � ���������� ��� ������
                  iBusArray:=0;
                  flagWtoBusArray:=false;
                end;
              end;
            end
            else
            begin
              busArray[iBusArray]:=BuildBusValue(highVal,lowerVal);
              inc(iBusArray);
              if iBusArray=32{96} then
              begin
                busArrLen:=length(busArray);
                for iCount:=0 to busArrLen-1 do
                begin
                  //form1.Memo1.Lines.Add(intToStr(busArray[iCount])
                  //+' '+intToStr(iCount));
                end;
              // showMessage('!!!!');
              end;
            end;

            if (flagWtoBusArray) then
            begin
              //������ �� ����� �����. ��������� ������
              busArray[iBusArray]:=BuildBusValue(highVal,lowerVal);
              inc(iBusArray);
            end;
          end;

          inc(iParity);
          inc(masElemParam[orbAdrCount].numOutPoint);
        end;
        if masElemParam[orbAdrCount].numOutPoint > maxPointInAdr then
        begin
          masElemParam[orbAdrCount].numOutPoint := 1;
        end;
      end;
      inc(orbAdrCount);
    end;
  end;

  if iBusArray=96 then
  begin
    iBusArray:=0;
    flagWtoBusArray:=false;
    result:=true;
  end
  else
  begin
    result:=false;
  end;
end;
//==============================================================================

//=============================================================================
//����� �� �����������
//=============================================================================

procedure TData.OutToDia(firstPointValue: integer;outStep: integer;
  masOutSize: integer; var numChanel: integer;typeOfAddres: short;
  numBitOfValue: short; busTh: short; busAdr: short;var numOutPoint: short);
var
  nPoint: integer;
  //����������� ��� ������� �������� T22
  fastValT22: integer;
  //����������� ��� ������� �������� T21
  fastValT21: integer;
  //����������� ��� ������� �������� T24
  fastValT24: integer;
  //���������� ��� ���������� ����������
  //����� ��� ������� ������ ����������� ������
  //���������� ��������������� � ����� ��� �����������
  //����������� ������ ����� �� �����
  maxPointInAdr: integer;
  //���������� ��� ���������� �������� ��� ���������� �������
  offsetForYalkAnalog: short;
  offsetForYalkTemp: short;
  offsetForYalkContact: short;
  offsetForYalkFastParamT22: short;
  offsetForYalkFastParamT21: short;
  offsetForYalkFastParamT24: short;
begin
  //��������� ���������� ����� � ��������� ������
  maxPointInAdr := 0;
  nPoint := firstPointValue;
  while nPoint <= masOutSize do
  begin
    inc(maxPointInAdr);
    nPoint := nPoint + outStep;
  end;

  //����� ������������ ������ ���� ������� ���������� � ���������� ������� �������
  if form1.PageControl1.ActivePageIndex = 0 then
  begin

    //����� ��� ���������� �������   0
    if typeOfAddres = 0 then
    begin
      //����� ������ ����� � ������� firstPointValue ��� �������� ������
      //���������� ��������� �������� ��� ����������� �� 1 ������ ������ 1 �����
      //���������� ��������, ��� ������� ���� ������ ����� ���� ��������
      offsetForYalkAnalog := outStep * (numOutPoint - 1);
      //���������� ������ ������� ��������� �����
      nPoint := firstPointValue + offsetForYalkAnalog;
      //��� ��� ������ ������ � 0
      nPoint := nPoint{ - 1};
      //����� �� ���
      form1.diaSlowAnl.Series[0].AddXY(numChanel, masGroup[nPoint] shr 1);
      //���������� �������� ��������� ����� ������
      inc(numOutPoint);
      //��������� �� ����� �� �� �� ������������ �������� ��� �������� ������
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //������� �������� ���������� ���������� �������
      inc(analogAdrCount);
    end;

    //����� ��� ���������� �������     1
    if typeOfAddres = 1 then
    begin
      offsetForYalkContact := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkContact;
      //��� ��� ������ ������ � 0
      nPoint := nPoint {- 1};
      contVal := OutputValueForBit(masGroup[nPoint], numBitOfValue);
      form1.diaSlowCont.Series[0].AddXY(numChanel - analogAdrCount, contVal);
      inc(numOutPoint);
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //������� �������� ���������� ���������� �������
      inc(contactAdrCount);
      //SaveBitToLog(IntToStr(numChanel-20));
      //if numChanel-20=8 then form1.gistCont.Series[0].Clear;
    end;
  end;

  //����� ��� ������� ����������
  if form1.PageControl1.ActivePageIndex = 1 then
  begin

    //����� ��� ������� ����������   T22
    if typeOfAddres = 2 then
    begin
      //���������� �������� ��� ��������� ������ ��� ���������
      //����� ��� ������� �������������� ������
      //�������� � ������ ����� ������ ����� �����������
      offsetForYalkFastParamT22 := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkFastParamT22;
      //��� ��� ������ ������ � 0
      nPoint := nPoint{ - 1};
      //�������� � ������� ������ ����� T22
      fastValT22 := BuildFastValueT22(masGroupAll[nPoint], numBitOfValue);
      try
        form1.fastDia.Series[0].AddXY(numChanel, fastValT22 {rrr});
      except
        //ShowMessage('111');
      end;
      inc(numOutPoint);
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
    end;

    //����� ��� ������� ����������   T21
    if typeOfAddres = 3 then
    begin
      //���������� �������� ��� ��������� ������ ��� ���������
      //����� ��� ������� �������������� ������
      //�������� � ������ ����� ������ ����� �����������
      offsetForYalkFastParamT21 := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkFastParamT21;
      //��� ��� ������ ������ � 0
      nPoint := nPoint {- 1};
      fastValT21 := masGroup[nPoint] shr 3; //8 ��������
      try
        form1.fastDia.Series[0].AddXY(numChanel, fastValT21);
      except
        //ShowMessage('222');
      end;
      inc(numOutPoint);
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
    end;

    //����� ��� ������� ����������   T24
    if typeOfAddres = 5 then
    begin
      offsetForYalkFastParamT24 := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkFastParamT24;
      nPoint := nPoint {- 1};
      //form1.Memo1.Lines.Add(intToStr(nPoint));
      fastValT24 := BuildFastValueT24(masGroupAll[nPoint], numBitOfValue);
      try
        form1.fastDia.Series[0].AddXY(numChanel, fastValT24);
      except
        //ShowMessage('111');
      end;
      inc(numOutPoint);
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
    end;
  end;

  //����� ��� ���
  if form1.PageControl1.ActivePageIndex = 2 then
  begin
  end;


  //����� ��� ������������� ����������
  if form1.PageControl1.ActivePageIndex = 3 then
  begin
    //����� ��� ������������� �������   7
    if typeOfAddres = 7 then
    begin
      //����� ������ ����� � ������� firstPointValue ��� �������� ������
      //���������� ��������� �������� ��� ����������� �� 1 ������ ������ 1 �����
      //���������� ��������, ��� ������� ���� ������ ����� ���� ��������
      offsetForYalkTemp := outStep * (numOutPoint - 1);
      //���������� ������ ������� ��������� �����
      nPoint := firstPointValue + offsetForYalkTemp;
      //��� ��� ������ ������ � 0
      nPoint := nPoint{ - 1};
      //����� �� ���
      form1.tempDia.Series[0].AddXY(numChanel, masGroup[nPoint] shr 1);
      //���������� �������� ��������� ����� ������
      inc(numOutPoint);
      //��������� �� ����� �� �� �� ������������ �������� ��� �������� ������
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //������� �������� ���������� ���������� �������
      inc(tempAdrCount);
    end;
  end;
end;

//==============================================================================
//����� �� ����������� ���������� ���������
//==============================================================================

procedure TData.OutToGistSlowAnl(firstPointValue: integer; outStep: integer;
  masOutSize: integer; var numP: integer);
var
  iPoint: integer;
begin
  //������� �� ���� ����� ������� ������� ������. ����.
  if (form1.PageControl1.ActivePageIndex = 0) then
  begin
    iPoint := firstPointValue;
    iPoint := iPoint{ - 1};
    while iPoint <= masOutSize-1 do
    begin
      if (numP < form1.gistSlowAnl.BottomAxis.Maximum - 10) then
        form1.gistSlowAnl.Series[0].AddXY(numP, masGroup[iPoint] shr 1);
      inc(numP);
      if (numP = form1.gistSlowAnl.BottomAxis.Maximum - 10) then
      begin
        form1.upGistSlowSize.Enabled := false;
      end;
      if (numP >= form1.gistSlowAnl.BottomAxis.Maximum) then
      begin
        numP := 0;
        form1.Series2.Clear;
        form1.upGistSlowSize.Enabled := true;
        form1.downGistSlowSize.Enabled := true;
      end;
      iPoint := iPoint + outStep;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//����� �� ����������� �������������
//==============================================================================

procedure TData.OutToGistTemp(firstPointValue: integer; outStep: integer;
  masOutSize: integer; var numP: integer);
var
  iPoint: integer;
begin
  //������� �� ���� ����� ������� ������� ������. ����.
  if (form1.PageControl1.ActivePageIndex = 3) then
  begin
    iPoint := firstPointValue;
    iPoint := iPoint{ - 1};
    while iPoint <= masOutSize-1 do
    begin
      if (numP < form1.tempGist.BottomAxis.Maximum - 10) then
        form1.tempGist.Series[0].AddXY(numP, masGroup[iPoint] shr 1);
      inc(numP);
      if (numP = form1.tempGist.BottomAxis.Maximum - 10) then
      begin
        form1.upGistTempSize.Enabled := false;
      end;
      if (numP >= form1.tempGist.BottomAxis.Maximum) then
      begin
        numP := 0;
        form1.lnsrsSeries8.Clear;
        form1.upGistTempSize.Enabled := true;
        form1.downGistTempSize.Enabled := true;
      end;
      iPoint := iPoint + outStep;
    end;
  end;
end;
//==============================================================================



//==============================================================================
//����� �� ����������� ������� ����������
//==============================================================================

procedure TData.OutToGistFastParam(firstPointValue: integer;outStep: integer;
  masOutSize: integer; adrtype: short;var numPfast: integer; numBitOfValue: integer);
var
  iPoint: integer;
  i:integer;
  kk:integer;
begin
  if (form1.PageControl1.ActivePageIndex = 1) then
  begin
    iPoint := firstPointValue;
    iPoint := iPoint{ - 1};
    while iPoint <= masOutSize - 1 do
    begin
      //T22
      if adrType = 2 then
      begin
        if numPfast < form1.fastGist.BottomAxis.Maximum then
        begin
          setlength(masFastVal, numPfast);
          masFastVal[numPfast-1]:=BuildFastValueT22(masGroupAll[iPoint], numBitOfValue);
          inc(numPfast);
          iPoint := iPoint + outStep;
        end
        else
        begin
          //sleep(2);
          form1.fastGist.Series[0].Clear;
          //sleep(2);
          countPastOut := 1;
          if form1.fastGist.BottomAxis.Maximum>length(masFastVal) then
          begin
            form1.fastGist.Series[0].AddArray(masFastVal);
          end;
          //masFastVal:=nil;
          Application.ProcessMessages;
          {sleep(10);
          Application.ProcessMessages;}
          sleep(10);

          {while countPastOut <= numPfast{ - 50} {do
          begin
            if (countPastOut mod 700 = 0) then
            begin
              //sleep(3);
              //Application.ProcessMessages;
            end;
            try
              if ((countPastOut >= form1.fastGist.BottomAxis.Minimum) and
                  (countPastOut <= form1.fastGist.BottomAxis.Maximum) and
                  (countPastOut < {length(masFastVal)}{numPfast)
                 {) then
              begin
                form1.fastGist.Series[0].AddXY(countPastOut,
                masFastVal[countPastOut]);
              end
              else
              begin
                //ShowMessage('ErrorT22!');
              end
            except
              //ShowMessage('ErrorT22!');
            end;
            inc(countPastOut);
          end;}
          //masFastVal := nil;
          //countPastOut := 1;
          numPfast := 1;
        end;
      end;

      //T21
      if adrType = 3 then
      begin
        if numPfast < form1.fastGist.BottomAxis.Maximum then
        begin
          setlength(masFastVal, numPfast);
        
          masFastVal[numPfast-1] := masGroup[iPoint] shr 3;
          inc(numPfast);
          iPoint := iPoint + outStep;
        end
        else
        begin
          //sleep(2);
          {Application.ProcessMessages;
          sleep(2);
          Application.ProcessMessages; }
          form1.fastGist.Series[0].Clear;
          {Application.ProcessMessages;
          sleep(2);
          Application.ProcessMessages;}
          //countPastOut := 1;
          //form1.downGistFastSize.Enabled := false;
          //try

          {while countPastOut<=trunc(form1.fastGist.BottomAxis.Maximum) do
          begin
            if form1.fastGist.BottomAxis.Maximum>length(masFastVal) then
            begin
              //Application.ProcessMessages;
              form1.fastGist.Series[0].AddXY(countPastOut,masFastVal[countPastOut-1]);
              //sleep(1);
              inc(countPastOut);
            end;
          end;}






          if form1.fastGist.BottomAxis.Maximum>length(masFastVal) then
          begin
            form1.fastGist.Series[0].AddArray(masFastVal);
          end;
          //kk:=form1.fastGist.Series[0].Count
          //except
            //ShowMessage('������');
          //end;
          //form1.downGistFastSize.Enabled := true;
          //masFastVal:=nil;
          Application.ProcessMessages;
          //sleep(10);
          sleep(10);
          //Application.ProcessMessages;

          {if countPastOut>=form1.fastGist.BottomAxis.Maximum then
          begin
            form1.fastGist.Series[0].Clear;
            countPastOut := 1;
          end;
          i:=1;
          while i <= numPfast - 30 do
          begin
            if (i mod 700 = 0) then
            begin
              //sleep(3);
             // Application.ProcessMessages;
            end;
            //try
              if ((i >= form1.fastGist.BottomAxis.Minimum) and
                 (i <= form1.fastGist.BottomAxis.Maximum) and
                 (i < {length(masFastVal)}{numPfast)
                {) then
              begin
                form1.fastGist.Series[0].AddXY(countPastOut,masFastVal[i]);
              end;
              //else
              //begin
                //ShowMessage('ErrorT21!');
              //end
            //except
              //ShowMessage('ErrorT21!');
            //end;
            inc(countPastOut);
            inc(i);
          end;
          //sleep(3);
          //masFastVal := nil;}
          //countPastOut := 1;
          numPfast := 1;
        end;
      end;

      //T24
      {if adrType = 5 then
      begin
        if numPfast < form1.fastGist.BottomAxis.Maximum-10 then
        begin
          setlength(masFastVal, numPfast);
          //form1.Memo1.Lines.Add(intToStr(iPoint));
          masFastVal[numPfast-1]:=BuildFastValueT24(masGroupAll[iPoint], numBitOfValue);
          //if numPfast=10 then
          //form1.Memo1.Lines.Add(intToStr(iPoint));
          inc(numPfast);
          iPoint := iPoint + outStep;
        end
        else
        begin
          //sleep(2);
          form1.fastGist.Series[0].Clear;
          //sleep(2);
          countPastOut := 1;
          if form1.fastGist.BottomAxis.Maximum>=length(masFastVal) then
          begin
            form1.fastGist.Series[0].AddArray(masFastVal);
          end;
          //masFastVal:=nil;
          {Application.ProcessMessages;
          sleep(5);
          Application.ProcessMessages;}
          {while countPastOut <= numPfast - 30 do
          begin
            if (countPastOut mod 700 = 0) then
            begin
             // sleep(3);
             // Application.ProcessMessages;
            end;
            try
              if ((countPastOut >= form1.fastGist.BottomAxis.Minimum) and
                  (countPastOut <= form1.fastGist.BottomAxis.Maximum) and
                  (countPastOut < {length(masFastVal)}{numPfast)
                {) then
              begin
                form1.fastGist.Series[0].AddXY(countPastOut,masFastVal[countPastOut]);
              end
              else
              begin
                //ShowMessage('ErrorT22!');
              end
            except
              //ShowMessage('ErrorT22!');
            end;
            inc(countPastOut);
          end;}
          //masFastVal := nil;
         { countPastOut := 1;
          numPfast := 1;
        end;
      end;}
    end;
  end;
end;
//==============================================================================

//==============================================================================
//����� �� ����������� ���������� ���
//==============================================================================
procedure TData.OutToGistBusParam(firstPointValue: integer;outStep: integer;
masOutSize: integer; adrtype: short;var numPfast: integer; numBitOfValue: integer);
var
  iPoint: integer;
  busArrLen:integer;
begin
  //������� �� ���� ����� ������� ������� ������. ����.
  if (form1.PageControl1.ActivePageIndex = 2) then
  begin
    iPoint:=0;
    busArrLen:=length(busArray);
    while iPoint <=busArrLen  do
    begin
      if (numP < form1.busGist.BottomAxis.Maximum - 10) then
      begin
         form1.busGist.Series[0].AddXY(numP, busArray[iPoint]);
      end;
      inc(numP);
      if (numP = form1.busGist.BottomAxis.Maximum - 10) then
      begin
        //form1.upGistSlowSize.Enabled := false;
      end;
      if (numP >= form1.busGist.BottomAxis.Maximum) then
      begin
        numP := 0;
        form1.Series6.Clear;
        //form1.upGistSlowSize.Enabled := true;
        //form1.downGistSlowSize.Enabled := true;
      end;
      iPoint := iPoint + 1;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//��������� ������� ������ � ��������
//==============================================================================

{procedure Tdata.SaveReport;
var
  str: string;
  i: integer;
begin
  //���� � ��� �������������� ��������, ��
  if (ParamStr(1) = 'StartAutoTest') then
  begin
    //��������� ��� �� ������� ��������2.
    //���� ��� �� ���������� ������� ���������� �����
    if (ParamStr(2) = '') then
      //���
    begin
      str := '����_���_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.txt';
      for i := 1 to length(str) do
        if (str[i] = ':') then
          str[i] := '.';
      form1.Memo1.Lines.SaveToFile(ExtractFileDir(ParamStr(0)) + '/Report/' + str);
    end
    else
      //��
    begin
      //��������� �.� � ���������� ������
      AssignFile(ReportFile, ParamStr(2));
      //��������� ���� �� ����� ����
      if (FileExists(ParamStr(2))) then
        //����, ��������� ���� �� ��������
      begin
        Append(ReportFile);
      end
      else
        //���
      begin
        //��������� �� ������
        ReWrite(ReportFile);
      end;
      writeln(ReportFile, form1.Memo1.Text);
      closefile(ReportFile);
    end
  end
  else
    //������ ��������. ���������� �����
  begin
    str := '����_���_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.txt';
    for i := 1 to length(str) do
      if (str[i] = ':') then
        str[i] := '.';
    form1.Memo1.Lines.SaveToFile(ExtractFileDir(ParamStr(0)) + '/Report/' + str);
  end;
end;}
//==============================================================================

//==============================================================================
//������� ��� ��������� �������� ���� �� ������ ���� � ����������������� ��������
//==============================================================================

function Tdata.OutputValueForBit(value: integer; bitNum: integer): short;
var
  sdvig: integer;
begin
  //�������� �� 1 ��� ������, ��� ��� ����
  //�������� �������� �� ��������� �� ���� ��� ���� ��������
  value := value shr 1;
  sdvig := -1;
  case bitNum of
    1:
    begin
      sdvig := 9;
    end;
    2:
    begin
      sdvig := 8;
    end;
    3:
    begin
      sdvig := 7;
    end;
    4:
    begin
      sdvig := 6;
    end;
    5:
    begin
      sdvig := 5;
    end;
    6:
    begin
      sdvig := 4;
    end;
    7:
    begin
      sdvig := 3;
    end;
    8:
    begin
      sdvig := 2;
    end;
    //9 � 10. ��� ���� T05 �� 10 ���
    9:
    begin
      sdvig := 1;
    end;
    10:
    begin
      sdvig := 0;
    end;
  end;
  //��������� ���������� �� ��� ����� �������� ��� �������
  if ((value shr sdvig) and 1 = 1) then
  begin
    result := 1
  end
  else
  begin
    result := 0;
  end;
end;
//==============================================================================

//==============================================================================
//��������� ��� ������ � ��������� ������ . � ���� ����� ������� ��������
//==============================================================================

procedure Tdata.WriteSystemInfo(value: string);
begin
  //����. ����� System � �������� ����������
  AssignFile(SystemFile, 'System');
  //�������� ���  �� ������
  ReWrite(SystemFile);
  //������ � ���� ����������� ��������
  writeln(SystemFile, value);
  //�������� �����
  closefile(SystemFile);
end;
//==============================================================================

//==============================================================================
//������� ���������� �������� ��������.
//���������� ������� �������� � ������������� �������
//==============================================================================

function Tdata.AvrValue(firstOutPoint: integer; nextPointStep: integer;
  masGroupS: integer): integer;
var
  sum: integer;
  pointCh: integer;
begin
  sum := 0;
  pointCh := 0;
  while firstOutPoint <= masGroupS do
  begin
    sum := sum + masGroup[firstOutPoint] shr 1;
    inc(pointCh);
    firstOutPoint := firstOutPoint + nextPointStep;
  end;
  result := round(sum / pointCh);
end;
//==============================================================================

//==============================================================================
//������ ������� ������M16
//==============================================================================
procedure TData.AdressAnalyser(adressString: string; var imasElemParam: integer);
var
  //���������� ��� ��������
  iGraph: integer;
  flagM: boolean;
  //���������� ��� �������� ASCII-���� �������
  codAsciiGraph: integer;
  stepKoef: integer;
  //��������� ��� ���������� ���������
  Ma, Mb, Mc, Md, Me, Mx: integer; //Ma=N1-1;Mb=N2-1;Mc=N3-1; � �.�
  //���� ��� ���������� ������
  //Fa=8, ���� K=0; Fa=4, ���� K=1; Fa=2, ���� K=2; ���������� ��� ������
  Fa, Fb, Fc, Fd, Fe, Fx: integer;
  //�������� ����. � �������, ������� �� �1 ��� �2
  pBeginOffset: integer;
  flagBegin: boolean;
  stepOutGins: integer;
  offset: integer;

  //��������������� ������ � ���� ������ �����
  infStrInt: integer;

  adrLength:Integer;
begin
  stepOutGins := 1;
  offset := 0;
  pBeginOffset := 0;
  Fa := 0;
  Fb := 0;
  Fc := 0;
  Fd := 0;
  Fe := 0;
  Fx := 0;
  flagM := false;
  iGraph := 1;
  flagBegin := false;
  adrLength:=length(adressString);
  while iGraph <= adrLength do
  begin
    //������ ������ ������ ���� ����������� �
    if adressString[iGraph] = 'M' then
    begin
      //� ����.
      flagM := true;
    end;

    if (flagM) then
    begin
      //M16
      if (adressString[iGraph + 1] = '1') and (adressString[iGraph + 2] = '6') then
      begin
        if ((adressString[iGraph + 3] = '�') or (adressString[iGraph + 3] = '�')) then
        begin
          if (adressString[iGraph + 4] = '1') then
          begin
            //������ ���. �������� ��� ������� �� �������
            pBeginOffset := 1;
          end;
          if (adressString[iGraph + 4] = '2') then
          begin
            //������ ���. �������� ��� ������� �� �������
            pBeginOffset := 2;
          end;
          flagBegin := true;
          iGraph := iGraph + 5;
          break;
        end
        else
        begin
          showMessage('������! �������� ����������� ������,'
            + '��������� ��������������� �� �� �������������!');
          //Application.Terminate;
          halt;
        end;
      end
      //���������
      else
      begin
        //��� ��������
        pBeginOffset := 1;
        flagBegin := true;
        iGraph := iGraph + 3;
        break;
      end;
    end;
  end;

  if (flagBegin) then
  begin
    //������������ ����� ���������
    while {(adressString[iGraph]<>' ')} iGraph <= adrLength do
    begin
      codAsciiGraph := ord(adressString[iGraph]);
      // ��������� ������������ ���� � ����� ��������� ����� � ���.
      case codAsciiGraph of
        //����� �(�)
        65, 97:
        begin
          Ma := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fa := 8;
            end;
            1:
            begin
              Fa := 4;
            end;
            2:
            begin
              Fa := 2;
            end;
          end;
          stepOutGins := Fa;
          offset := offset + Ma;
        end;
        //����� B(b)
        66, 98:
        begin
          Mb := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fb := 8;
            end;
            1:
            begin
              Fb := 4;
            end;
            2:
            begin
              Fb := 2;
            end;
          end;
          offset := offset + Mb * stepOutGins;
          stepOutGins := stepOutGins * Fb;
        end;
        //����� C(c)
        67, 99:
        begin
          Mc := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fc := 8;
            end;
            1:
            begin
              Fc := 4;
            end;
            2:
            begin
              Fc := 2;
            end;
          end;
          offset := offset + Mc * stepOutGins;
          stepOutGins := stepOutGins * Fc;
        end;
        //����� D(d)
        68, 100:
        begin
          Md := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fd := 8;
            end;
            1:
            begin
              Fd := 4;
            end;
            2:
            begin
              Fd := 2;
            end;
          end;
          offset := offset + Md * stepOutGins;
          stepOutGins := stepOutGins * Fd;
        end;
        //����� E(e)
        69, 101:
        begin
          Me := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fe := 8;
            end;
            1:
            begin
              Fe := 4;
            end;
            2:
            begin
              Fe := 2;
            end;
          end;
          offset := offset + Me * stepOutGins;
          stepOutGins := stepOutGins * Fe;
        end;
        //����� X(x)
        88, 120:
        begin
          Mx := strToInt(adressString[iGraph + 1]) - 1;
          stepKoef := strToInt(adressString[iGraph + 2]);
          case stepKoef of
            0:
            begin
              Fx := 8;
            end;
            1:
            begin
              Fx := 4;
            end;
            2:
            begin
              Fx := 2;
            end;
          end;
          offset := offset + Mx * stepOutGins;
          stepOutGins := stepOutGins * Fx;
        end;
        //����� T(t)
        84, 116:
        begin
          if ((adressString[iGraph + 1] = '0')and(adressString[iGraph + 2] = '1')) then
          begin
            //T01. ���������� 0.
            masElemParam[imasElemParam].adressType := 0;
            //��������� ����� ����.
            //������������ ������ ��� ����������.
            masElemParam[imasElemParam].bitNumber := 0;
          end;

          if ((adressString[iGraph + 1] = '0')and(adressString[iGraph + 2] = '5')) then
          begin
            //T05. ���������� 1.
            masElemParam[imasElemParam].adressType := 1;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '1')) then
          begin
            //T21 ������� 1.
            masElemParam[imasElemParam].adressType := 3;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '2')) then
          begin
            //T22. ������� 2.
            masElemParam[imasElemParam].adressType := 2;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '3')) then
          begin
            //T23. ������� 3.
            masElemParam[imasElemParam].adressType := 4;
          end;
          //���� ��� ��� ��� �������
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '4')) then
          begin
            //T24 ������� 4.
            masElemParam[imasElemParam].adressType := 5;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '5')) then
          begin
            //T25. ���. ��� ��������
            masElemParam[imasElemParam].adressType := 6;
          end;

          if ((adressString[iGraph + 1] = '1')and(adressString[iGraph + 2] = '1')) then
          begin
            //T11. �������������
            masElemParam[imasElemParam].adressType := 7;
          end;
        end;
        //����� P(p)
        80, 112:
        begin
          //����������� � ���������� ���� �����.
          //� ��������� ��������� ���������� ��� ����� ����������
          //��������� ����� ����. ������������ ������
          //��� ����������. ������������ ��� �������.
          masElemParam[imasElemParam].bitNumber :=
            strToInt(adressString[iGraph + 1] + adressString[iGraph + 2]);
          break;
        end;
      end;
      iGraph := iGraph + 3;
    end;

    infStrInt := StrToInt(adressString[2] + adressString[3]);
    //N1={Ma+Mb*Fa+Mc*Fa*Fb+Md*Fa*Fb*Fc+Me*Fa*Fb*Fc*Fd+Mx*Fa*Fb*Fc*Fd*Fe}
    //�������� ���������� ������ ������� � ����������� �� ��� ����. ������
    //M16
    if infStrInt = 16 then
    begin
      masElemParam[imasElemParam].numOutElemG := pBeginOffset + 2 * offset;
    end
    //���������
    else
    begin
      masElemParam[imasElemParam].numOutElemG := pBeginOffset + offset;
    end;

    //���������� ��� ��� ������� ����. ����� � �����. �� ��������������� ������
    case infStrInt of
      16:
      begin
        masElemParam[imasElemParam].stepOutG := 2 * stepOutGins; //T=Fa*Fb*Fc*Fd*Fe*Fx
      end;
      8:
      begin
        masElemParam[imasElemParam].stepOutG := stepOutGins;
      end;
      4:
      begin
        masElemParam[imasElemParam].stepOutG := round(stepOutGins / 2);
      end;
      2:
      begin
        masElemParam[imasElemParam].stepOutG := round(stepOutGins / 4);
      end;
      1:
      begin
        masElemParam[imasElemParam].stepOutG := round(stepOutGins / 8);
      end;
    end;

    //��������� �� ��������� �������� �������
    //��������� ����� � 1 ��� ���� �������
    masElemParam[imasElemParam].numOutPoint := 1;
    //masElemParam[imasElemParam].numOutElemG:=
      //masElemParam[imasElemParam].numOutElemG+numPoint*
        //masElemParam[imasElemParam].stepOutG; //N=N1+nT
  end;
end;
//==============================================================================

//==============================================================================
//���������� ������� ���������� ������������� ������� �������16
//==============================================================================

procedure TData.FillAdressParam;
var
  //���������� ������� ��� ������� ������ ������ �������
  adrCount: integer;
  //���� ���. �������
  iAdr: integer;
  maxAdrNum:Integer;
begin
  //��������� ������������� �������
  masElemParam := nil;
  iAdr := 0;
  maxAdrNum:=form1.OrbitaAddresMemo.Lines.Count - 1;
  for adrCount := 0 to maxAdrNum  do
  begin
    //��� ������� �� ������� ��������� ����� ��� ��� ���������� �����������
    if  form1.OrbitaAddresMemo.Lines.Strings[adrCount]<>'---' then
    begin
      //�����
      //������� ������ �� ������� ������� ����������
      setlength(masElemParam, iAdr  + 1);
      data.AdressAnalyser(form1.OrbitaAddresMemo.Lines.Strings[adrCount], iAdr);
      inc(iAdr);
    end;
  end;
  //��������� ������������ ���������� �������
  iCountMax := iAdr;
  //���������� ������� ����� ������� ���� � ������
  data.CountAddres;
  //masElemParam:=nil;
end;
//==============================================================================

//==============================================================================
//��������� ��� �������� ������� ����� ������� � ������� ����
//==============================================================================

procedure TData.CountAddres;
var
  //������� �������� ���� ���������� �������
  adrCount: integer;
  masElemParamLen:integer;
begin
  adrCount := 0;
  masElemParamLen:=length(masElemParam);
  while adrCount <=masElemParamLen  - 1 do
  begin
    case masElemParam[adrCount].adressType of
      0:
      begin
        //����������
        inc(acumAnalog);
      end;
      1:
      begin
        //����������
        inc(acumContact);
      end;
      2, 3, 4, 5:
      begin
        //�������
        inc(acumFast);
      end;
      6:
      begin
        //���
        inc(acumBus);
      end;
      7:
      begin
        //�������������
        inc(acumTemp);
      end;
    end;
    inc(adrCount);
  end;
end;
//==============================================================================

//==============================================================================
//������� ���������� �������� ������
//==============================================================================
function TData.SignalPorogCalk(bufMasSize: integer;acpBuf: TShortrArray; reqNumb: word): integer;
var
  //������������ � ����������� �������� ������ � ���
  maxValue, minValue: integer;
  //������� ��� �������� ��. �������
  jSignalPorogCalk: integer;
begin
  //��������� �������� �������
  maxValue := acpBuf[reqNumb xor $1][0];
  minValue := acpBuf[reqNumb xor $1][0];
  for jSignalPorogCalk := 1 to bufMasSize - 1 do
  begin
    //����� ���������.
    if maxValue <= acpBuf[reqNumb xor $1][jSignalPorogCalk] then
    begin
      maxValue := acpBuf[reqNumb xor $1][jSignalPorogCalk];
    end;
    //����� ��������
    if minValue >= acpBuf[reqNumb xor $1][jSignalPorogCalk] then
    begin
      minValue := acpBuf[reqNumb xor $1][jSignalPorogCalk];
    end;
  end;
  //� ����� ������� min � max �������.
  //������� �����. ������� ��������������
  result := (maxValue + minValue) div 2;
  //SignalPorogCalk:=1984 ;
end;
//==============================================================================

//=============================================================================
//������ �������� �� ������ ������
//=============================================================================
function TData.Read(): integer;
begin
  result := fifoMas[fifoLevelRead];
  inc(fifoLevelRead);
  if fifoLevelRead > FIFOSIZE then
  begin
    fifoLevelRead := 1;
  end;
  dec(fifoBufCount);
end;
//=============================================================================

//==============================================================================
//������� ��� ������ �� ������� ���� ����� ������ ���������
//offset -����� ��� ������ ����������� ���������
//============================================================================
function TData.Read(offset: integer): integer;
var
  fifoOffset: integer;
begin
  //�������� �������� ��� ���������� �������
  offset := offset - 1;
  if data.fifoLevelRead + offset > FIFOSIZE then
  begin
    fifoOffset := (data.fifoLevelRead + offset) - FIFOSIZE;
  end
  else
  begin
    fifoOffset := data.fifoLevelRead + offset;
  end;
  result := data.fifoMas[fifoOffset];
end;
//============================================================================

//==============================================================================
//��������� ������ M16
//==============================================================================
procedure TData.TreatmentM16;
begin
  //���� ����� � ����� ������ ������ ����� �����, ���������
  while ((fifoBufCount >= 100000)and(not flagEnd)) do  ///!!!
  begin
    //����� ������� ������ �������� �����
    //����� ���������� ������ ���
    if (not firstFraseFl) then
    begin
      SearchFirstFraseMarker;
      //form1.tmrForTestOrbSignal.Enabled:=True;
    end
    else
    begin
      //���� ����� ������ �� ���������� ������
      AnalyseFrase;
    end;
    // � ������ ������ ����� �� ����������
    {if flagEnd then
    begin
      break;
    end;}
  end;

  //��������� ��� � ������ ��� ����� ������ �� ������������� 200 � ������.
  //��� �������
  if SignalPorogCalk(round(buffDivide/10), buffer,RequestNumber)<=200 then   ///!!! round(buffDivide/10)
  begin
    outMF(127);
    //Form1.Memo1.Lines.Add('11');
    outMG(31);
  end;
end;
//==============================================================================

//==============================================================================
//����� �� ��������� ����� ����� �� ��
//==============================================================================
procedure TData.OutMF(errMF:Integer);
var
  procentErr:Integer;
begin
  if errMF=0 then
  begin
    //����� ��� ��� clWhite
    form1.gProgress1.BackColor:=clWhite;
  end
  else
  begin
    //���� ���� ��� clRed
    form1.gProgress1.BackColor:=clRed;
  end;

  procentErr:=Trunc(errMF/1.27);
  Form1.gProgress1.Progress:=procentErr;
end;
//==============================================================================

//==============================================================================
//����� �� ��������� ����� ����� �� ��
//==============================================================================
procedure TData.OutMG(errMG:Integer);
var
  procentErr:Integer;
begin
  if errMG=0 then
  begin
    //����� ��� ��� clWhite
    form1.gProgress2.BackColor:=clWhite;
  end
  else
  begin
    //���� ���� ��� clRed
    form1.gProgress2.BackColor:=clRed;
  end;
  procentErr:=Trunc(errMG/0.31);
  Form1.gProgress2.Progress:=procentErr;
end;
//==============================================================================

//==============================================================================
//��������� ������ M08,04,02,01
//==============================================================================
procedure TData.TreatmentM8_4_2_1;
begin
  //��������� ����� ������� 3 ��������� ����� ����� ����� �������� ����
  while (fifoBufCount >= MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR * 2) do //!! 3 �� 2
  begin
    //���� ������ ����� ������
    if (not fraseMarkFl) then
    begin
      countPointMrFrToMrFr := FindFraseMark(fifoLevelRead);
      //TestSMFOutDate(20,fifoLevelRead,1230);
      //while (true) do application.processmessages;
      if ((countPointMrFrToMrFr = -1) and (not flagEnd)) then
      begin
        {showMessage('������ ������! ��������� ��������� �� ������ ��� ������� ������ � ����!');
        //closeFile(LogFile);
        acp.AbortProgram(' ', false);
        if ReadThreadErrorNumber <> 0 then
        acp.ShowThreadErrorMessage();
        //else form1.Memo1.Lines.Add(' The program was completed successfully!!!');
        //����
        halt;
        //���� ����� ������ , �� ���������� ������
        if hReadThread <> THANDLE(nil) then
        begin
          //������� �����
          //EndThread(hReadThread);
          CloseHandle(hReadThread);
          sleep(50);
          showMessage('��������� ���� ���������');
          halt;
        end;}
      end;
      //��� ������ ������ ���. �� ����������
      countPointMrFrToMrFr := 0;
      //������ ������ ����� �����
      fraseMarkFl := true;
    end
    else
    //����� ������ �����
    begin
      if (not qSearchFl) then
      begin
        qSearchFl := true;
      end
      else
      begin
        Inc(countForMF);
        //������������� �� ������ ���������� ����� ������
        FifoNextPoint({MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR}minSizeBetweenMrFrToMrFr);
        //FifoNextPoint(10);
        //TestSMFOutDate(10,fifoLevelRead,10);
        //����. ������� ������� �����
        if (QfindFraseMark) then
        begin
          //form1.Memo1.Lines.Add('1220');
          //Writeln(textTestFile,'1220');
          //TestSMFOutDate(10,fifoLevelRead,10);
          //FifoBackPoint(6); //!!!
          //TestSMFOutDate(10,fifoLevelRead,10);
          //orbOk:=True;
          //Form1.Memo1.Lines.Add(IntToStr(fifoLevelRead)+' '+'1220'+' --');

          FillMasGroup(minSizeBetweenMrFrToMrFr, fifoLevelRead,infStr, data.iMasGroup);
        end
        else
        begin
          //��������� � �������� ����� ������
          FifoBackPoint(minSizeBetweenMrFrToMrFr);
          //FifoBackPoint(10);
          //������������� �� ������ ���������� ����� ������
          FifoNextPoint(minSizeBetweenMrFrToMrFr + 1);
          //FifoNextPoint(11);
          //����. ������� ������� �����
          if (QfindFraseMark) then
          begin
             //form1.Memo1.Lines.Add('1221');
             //Writeln(textTestFile,'1221');
            // TestSMFOutDate(10,fifoLevelRead,10);
            //FifoBackPoint(6); //!!!
            //TestSMFOutDate(10,fifoLevelRead,10);
            //orbOk:=True;

            //Form1.Memo1.Lines.Add(IntToStr(fifoLevelRead)+' '+'1221'+' --');

            FillMasGroup(minSizeBetweenMrFrToMrFr + 1, fifoLevelRead, infStr, data.iMasGroup);
          end
          else
          begin
            //������� ����� �� �����
            //��������� � �������� ����� ������.
            FifoBackPoint(minSizeBetweenMrFrToMrFr + 1);
            //��������� �� 2 ����� ������ ����� �� ����� ���������� ������
            FifoNextPoint(2);
            //FifoBackPoint(11);
            //TestSMFOutDate(1230,fifoLevelRead,1230);
            //while (True) do Application.ProcessMessages;
            //������� ������� ������ �� �����, ���� ��������
            countPointMrFrToMrFr := FindFraseMark(fifoLevelRead);
            //��������� 2 ����� � ������� �.� ���������� �� ��� ������
            countPointMrFrToMrFr:=countPointMrFrToMrFr+2;

            //Form1.Memo1.Lines.Add(IntToStr(fifoLevelRead)+' ++');


            Inc(countErrorMF);
            //Form1.Memo1.Lines.Add(IntToStr(countErrorMF)+' '+IntToStr(fifoLevelRead)+' '+IntToStr(countPointMrFrToMrFr));

            if countForMF={100}127 then
            begin
              //while (True) do Application.ProcessMessages; //!!!!
              countForMF:=0;
              //����� ����� �� ������� ����� �� �����
              OutMF(countErrorMF);
              //��������� ���� �� �� ��������� �� � �� �� �������� �������
              if countErrorMF={100}127 then
              begin
                OutMG(31);
              end;
              countErrorMF:=0;
            end;

            //Writeln(textTestFile,intToStr(countPointMrFrToMrFr));
            //form1.Memo1.Lines.Add(IntToStr(countPointMrFrToMrFr));
            if ((countPointMrFrToMrFr = -1) and (not flagEnd)) then
            begin
              {showMessage('������ ������! ��������� ��������� �� ������ � ������ � ����!');
              halt;}
            end;
            FillMasGroup(countPointMrFrToMrFr, fifoLevelRead,infStr, data.iMasGroup);
          end;
        end;
      end;
      //�������� ������� ��� �������� ���������� �������� �����
      if countForMF={100}127 then
      begin
        countForMF:=0;
        OutMF(countErrorMF);
        countErrorMF:=0;
      end;
    end;
  end;
  {if orbOk=False then
  begin
    CloseFile(textTestFile);
    data.graphFlagFastP := false;

    //Application.ProcessMessages;
    sleep(50);
    //Application.ProcessMessages;

    if ((form1.tlmWriteB.Enabled)and
        (not form1.startReadTlmB.Enabled)and
        (not form1.propB.Enabled))  then
    begin
      //��������� ������ � ���
      pModule.STOP_ADC();
    end;
    //�������� ��� ���������� �����
    flagEnd:=true;
    wait(100);
    form2.show;
  end;}
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.ReInitialisation;
begin
  //����� ������
  form1.startReadACP.Enabled := true;
  //������ � tlm
  form1.tlmWriteB.Enabled := false;
  //���������� ������ ������� ���
  //!!!
  //acp.Free;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function Tdata.GenTestAdrCorrect:boolean;
var
  i: integer;
  //������ � ������.
  str: string;
  masEcount: integer;
  rez:boolean;
begin
  rez:=false;
  //�������� �� ������������ ���� �������
  for i := 0 to form1.OrbitaAddresMemo.Lines.Count - 1 do
  begin
    str := '';
    str := form1.OrbitaAddresMemo.Lines.Strings[i][1] +
      form1.OrbitaAddresMemo.Lines.Strings[i][2]+form1.OrbitaAddresMemo.Lines.Strings[i][3];
    //�������� � �� ���������� �� ��� �����������
    if str = '---' then
    begin
      //�������� �� ��������� �������� �����
      Continue;
    end;

    if ((str = 'M16')or(str = 'M08')or(str = 'M04')or(str = 'M02')or(str = 'M01')) then
    begin
      //�������� ����������� ������� ������ �� ��������� ���������������
      case strToInt(str[2] + str[3]) of
        //M16
        16:
        begin
          infNum := 0;
          infStr := 'M16';
        end;
        //M08
        8:
        begin
          infNum := 1;
          infStr := 'M08';
        end;
        //M04
        4:
        begin
          infNum := 2;
          infStr := 'M04';
        end;
        //M02
        2:
        begin
          infNum := 3;
          infStr := 'M02';
        end;
        //M01
        1:
        begin
          infNum := 4;
          infStr := 'M01';
         end;
      end;
    end
    else
    begin
      //ShowMessage('��������� ������������ �������');
      //form1.OrbitaAddresMemo.Clear;
      rez:=false;
      break;
    end;

    if i = form1.OrbitaAddresMemo.Lines.Count - 1 then
    begin
      if data.AditTestAdrCorrect then
      begin
        form1.startReadACP.Enabled := true;
        form1.startReadTlmB.Enabled := true;
        //�������� ����������� ������� ������ �� ��������� ���������������
        //����� �������� ����. ��� ������ ������� ����� ��� �08,04,02,01
        case infNum of
          //M16
          0:
          begin
            masGroupSize := 2048;
          end;
          //M08
          1:
          begin
            masGroupSize := 1024;
            markKoef:=6.357828776;
            widthPartOfMF:=3;
            minSizeBetweenMrFrToMrFr:=1220;
          end;
          //M04
          2:
          begin
            masGroupSize := 512;
            markKoef:=12.715657552;
            widthPartOfMF:=6;
            minSizeBetweenMrFrToMrFr:=1220;//!!!
          end;
          //M02
          3:
          begin
            masGroupSize := 256;
            markKoef:=25.431315104;
            widthPartOfMF:=12;
            minSizeBetweenMrFrToMrFr:=1220;//!!!
          end;
          //M01
          4:
          begin
            masGroupSize := 128;
            markKoef:=50.862630020;
            widthPartOfMF:=25;
            minSizeBetweenMrFrToMrFr:=1220;//!!!
          end;
        end;

        //���������� ��������� � ������� ����� �� ���������������
        masCircleSize:=masGroupSize*32;


        //���. ����. �����. ������� ����� ������
        for masEcount := 1 to FIFOSIZE do
        begin
          data.fifoMas[masEcount] := 9;
        end;

        //�������� ������ ��� ������ ������ 11 ���. �� �������
        //SetLength(masGroup, masGroupSize);
        //�������� ������ ��� ������ ������ 12 ���. ��� ����� �������
        //SetLength(masGroupAll, masGroupSize);
        for masEcount := 1 to masGroupSize do
        begin
          masGroup[masEcount] := 9;
          masGroupAll[masEcount] := 9;
        end;


        //���. ��������� ����� ������. �������� ������ ������� �����
        //0 �����
        data.reqArrayOfCircle := 0;
        //SetLength(masCircle[data.reqArrayOfCircle], masGroupSize * 32);
        //form1.Memo1.Lines.Add(intToStr(length(masCircle[reqArrayOfCircle])));
        //����. ������� �����
        for masEcount := 1 to masGroupSize * 32 do
        begin
          masCircle[data.reqArrayOfCircle][masEcount] := 9;
        end;

        rez:=true;
      end;
    end;
  end;
  result:=rez;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

function Tdata.AditTestAdrCorrect: boolean;
var
  i: integer;
  str: string;
  bool: boolean;
begin
  bool := true;
  //�������� �� ������������ �������
  for i := 0 to form1.OrbitaAddresMemo.Lines.Count - 1 do
  begin
    str := '';
    str := form1.OrbitaAddresMemo.Lines.Strings[i][1] +
    form1.OrbitaAddresMemo.Lines.Strings[i][2] +
    form1.OrbitaAddresMemo.Lines.Strings[i][3];
    if str = infStr then
    begin
    end
    else
    begin
      if  str<>'---' then
      begin
        bool := false;
        ShowMessage('����������� ������ �� �����. ��������� ���������������');
        break;
      end;
    end;
  end;
  result := bool;
end;
//==============================================================================




//M08,04,02,01
//=============================================================================
//
//=============================================================================
procedure TData.WriteToFIFObuf(valueACP: integer);
begin
  fifoMas[fifoLevelWrite] := valueACP;
  inc(fifoLevelWrite);
  inc(fifoBufCount);
  if (fifoLevelWrite > fifoSize) then
  begin
    fifoLevelWrite := 1;
  end;
end;
//==============================================================================

//==============================================================================
//������� ������ �������� �� 0 � 1
//==============================================================================
function TData.SearchP0To1(curPoint:Integer;nextPoint:integer):Boolean;
var
  bool:Boolean;
begin
  bool:=False;
  //��������� ������� ����� ����� �� 0 � 1
  if ((curPoint < porog) and (nextPoint >= porog)) then
  begin
    bool:=True;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//������� ������ �������� �� 0 � 1
//==============================================================================
function TData.SearchP1To0(curPoint:Integer;nextPoint:integer):Boolean;
var
  bool:Boolean;
begin
  bool:=false;
  //��������� ������� ����� ����� �� 1 � 0
  if ((curPoint > porog) and (nextPoint <= porog)) then
  begin
    bool:=True;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//��������� ��� ������������ ������ ������� �����. ������� �������� ������
//==============================================================================
procedure TData.TestSMFOutDate(numPointDown:Integer;numCurPoint:integer;numPointUp:integer);
var
  numP:Integer;
begin
  form1.Memo1.Lines.Add('��������� ��������!!! '+intTostr(porog));

  //�� �����
  for numP:=numCurPoint-numPointDown to  numCurPoint-1 do
  begin
    form1.Memo1.Lines.Add('����� ����� � ������� '+intTostr(numP)+' '+'�������� '+IntToStr(fifoMas[numP]));
  end;

  //����� �����
  for numP:=numCurPoint to  numCurPoint+numPointUp do
  begin
    if numP=numCurPoint then
    begin
      form1.Memo1.Lines.Add('����� ����� � �������!!! '+
        intTostr(numP)+' '+'�������� '+IntToStr(fifoMas[numP]));
    end
    else
    begin
      form1.Memo1.Lines.Add('����� ����� � ������� '+
        intTostr(numP)+' '+'�������� '+IntToStr(fifoMas[numP]));
    end;
  end;
  form1.Memo1.Lines.Add('====================');
end;
//==============================================================================





//==============================================================================
//������� ��� ������ ������� �����. �� ���� ����� ����� � �����.������(������ ����������� ������� ��.)
//�� ������ ����� ����� � �����. ������(������ ����. ������� ��.).
//���������� �����. ����� ����� ��������� ��.
//==============================================================================
function TData.FindFraseMark(var fifoLevelRead: integer): integer;
var
  currentACPVal: integer;
  frMarkSize: integer;

  //ppp:integer;
  startSearch: boolean;
  fl: boolean;
  fl2: boolean;
  sizeFraseInPoint: integer;
  //iOut: integer;
  //m: integer;


  m:integer;

  //������� ������. �����
  iSearch: integer;
  downToUpFl: boolean;
  //���� ���������� ������ ������� �����
  searchOKfl: boolean;
  numPointFromFpToMf:Integer;
begin
  //���������� ����� �� �������
  {searchOKfl := false;
  frMarkSize := 0;
  sizeFraseInPoint := 0;
  //����� ������� ����� ����
  startSearch := false;
  //����� ��� ������ �������� �������� ������ ������
  downToUpFl := false;
  fl := false;
  fl2 := false;
  //���� ������ ����� � (3)2 �������� ����� ����� ����� ���������
  for iSearch := 1 to MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR * 2 do //3 �� 2
  begin
    if (not downToUpFl) then
    begin
      //��������� ������� �����
      currentACPVal := ReadFromFIFObuf;
      //+1 ����� � ������� ����� ����� ��������� ����
      inc(sizeFraseInPoint);
      if ((currentACPVal < porog) and (fifoMas[fifoLevelRead] >= porog)) then
      begin
        fl := true;
      end;
      if ((fl) and (currentACPVal >= porog)) then
      begin
        downToUpFl := true;
        startSearch := true;
        //���������������� ����� �������, ����������� �
        inc(frMarkSize);
      end;
    end;
    if (startSearch) then
    begin
      currentACPVal := ReadFromFIFObuf;
      //+1 ����� � ������� ����� ����� ��������� ����
      inc(sizeFraseInPoint);
      //ppp:=fifoMas[fifoLevelRead-1];
      if currentACPVal >= porog then
      begin
        inc(frMarkSize);
        fl2 := true;
      end;
      if ((fl2) and (currentACPVal < porog)) then
      begin
        if ((frMarkSize >= MARKMINSIZE) and (frMarkSize <= MARKMAXSIZE)) then
        begin
          if (TestMarker(fifoLevelRead - 1, MARKMAXSIZE)) then
          begin
            fifoBackPoint(frMarkSize + 1);
            searchOKfl := true;
            break;
          end
          else
          //�� ������
          begin
            searchOKfl := false;
            break;
          end;
        end;
        frMarkSize := 0;
        downToUpFl := false;
        startSearch := false;
        fl := false;
        fl2 := false;
      end;
    end;
  end;
  if (searchOKfl) then
  //���� ������
  begin
      //���������� ���������� ����� ����� ��������� ����
    result := sizeFraseInPoint - (frMarkSize + 1);
  end
  else
  //��� �������
  begin
    result := -1;
  end;}

  numPointFromFpToMf:=0;
  //��������� ����������� ������� �������� �� 0 � 1
  downToUpFl:=false;
  searchOKfl:=false;
  sizeFraseInPoint := 0;
  // � ���� ������ �����. ����� ����� ��������� ���� ������� �� 0 � 1
  for iSearch := 1 to {MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR}minSizeBetweenMrFrToMrFr * 2 do //3 �� 2
  begin
    //��������� ������� �����
    currentACPVal := ReadFromFIFObuf;
    //+1 ����� � ������� ����� ����� ��������� ����
    inc(sizeFraseInPoint);
    //��������� ������� ����� ����� �� 0 � 1
    //���� ������ ������� �����, �� ������ �� ����
    if ((SearchP0To1(currentACPVal,fifoMas[fifoLevelRead]))and(not downToUpFl)) then
    begin
      //����� ������ �������
      downToUpFl:=true;
      //TestSMFOutDate(5,fifoLevelRead,5);
    end;

    if (downToUpFl) then
    begin
      Inc(numPointFromFpToMf);
      //���� ����� ������� ����� �����
      if ((SearchP0To1(currentACPVal,fifoMas[fifoLevelRead]))or
         (SearchP1To0(currentACPVal,fifoMas[fifoLevelRead]))) then
      begin
        //dec(numPointFromFpToMf);//!! ��� ����� ������� ����� 
        //��������� �� ����� �� ������
        if ((Frac(numPointFromFpToMf/markKoef)>=0.25)and
           (Frac(numPointFromFpToMf/markKoef)<=0.75)) then
         begin
          //TestSMFOutDate(10,fifoLevelRead,10);
          //����� ������
          searchOKfl:=True;
          //����� �� ������
          Break;
         end;
      end;
    end;
  end;
  if (searchOKfl) then
  //���� ������
  begin
    //���������� ���������� ����� ����� ��������� ����
    result := sizeFraseInPoint {- (frMarkSize + 1)};
  end
  else
  //��� �������
  begin
    result := -1;
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.FifoNextPoint(countPoint: integer);
var
  offset: integer;
begin
  //���������� ������� ������ ������
  if ((fifoLevelRead + countPoint) > FIFOSIZE) then
  begin
    //��������� �� ������� ������ ������������� �������� ������ ����� � ����. ������
    offset := (fifoLevelRead + countPoint) - FIFOSIZE;
    fifoLevelRead := offset
  end
  else
  begin
    fifoLevelRead := fifoLevelRead + countPoint;
  end;
  //��������. ����� �� �������� ���. ����� � �����. � fifoLevelRead
  fifoBufCount := fifoBufCount - countPoint;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

function TData.QfindFraseMark: boolean;
var
  testRes: boolean;
begin
  testRes := false;

  //��������� ���. ����. �������
  if (QtestMarker(fifoLevelRead, {MARKMINSIZE}widthPartOfMF)) then
  begin
    testRes := true;
  end;
  {else
  begin
    //���������  ����. ����. �������
    if (QtestMarker(fifoLevelRead, MARKMAXSIZE)) then
    begin
      testRes := true;
    end;
  end;}
  result := testRes;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.FifoBackPoint(countPoint: integer);
var
  offset: integer;
begin
  //���������� ������� ������ �����
  if fifoLevelRead <= countPoint then
  begin
    offset := countPoint - fifoLevelRead;
    fifoLevelRead := FIFOSIZE - offset;
  end
  else
  begin
    fifoLevelRead := fifoLevelRead - countPoint;
  end;
  //������. ����� � �������� ���. ����� � �����. � fifoLevelRead
  fifoBufCount := fifoBufCount + countPoint;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.FillMasGroup(countPointToPrevM: integer;
currentMarkFrBeg: integer; orbInf: string; var iMasGroup: integer);
const
  SIMBOLINWORD = 12;
var
  stepToTransOrbOne: extended;
  countStep: extended;
  wordCount: integer;
  simbCount: integer;
  numWordInByte: integer;
  wordBuf: word;
  //i: integer;
  //j: integer;
  //k: integer;
  //l: integer;
  //offset: integer;
  //stepRealInFloat:int64;
  //testMas:array of testRecord; //!!!
  //iTestMas:integer;//!!!
  //ppp: integer;
  //koef: integer;
begin
  wordBuf := 0;
  //������� ���������� ���� ����� ��������� �� ���������������
  //����� ��������� ������ 2 �����
  numWordInByte := StrToInt(orbInf[3]) * 2;
  //��������� ���������� ����� �����. ������ �� 1 ������ ������
  stepToTransOrbOne := countPointToPrevM / numWordInByte / SIMBOLINWORD;
  //stepToTransOrbOne := markKoef;
  //������������ � ������ ����������� ������� �����
  countStep := ReadFromFIFObufB(countPointToPrevM);
  //countStep := ReadFromFIFObufB(4);
  //��������� � �������� ����, ���. �������� +4 �����
  //countStep := ReadFromFIFObufN(round(countStep), {MARKMAXSIZE}4); //!! 1 �� 2
  wordCount := 1;
  //��������� ������ ������ ������
  while wordCount <= numWordInByte do
  begin
    //�������� ����� ��������������� ������� ������
    if (((wordCount = 1) or (wordCount = {9}StrToInt(orbInf[3])+1)) and (flagCountFrase)) then
    begin
      inc(fraseCount);
      if fraseCount = 129 then
      begin
        fraseCount := 1;
        //������ �����, ������ ������, ������ �����. ��������� ��������� ������ �����
        if ((wordCount = 1) and (groupCount = 1)) then
        begin
          if (tlm.flagWriteTLM) then
          begin
            flSinxC := true;
          end;
        end;
      end;
      //SaveBitToLog(' ����� '+IntToStr(fraseCount));
    end;
    //���� ����� �� �������� ����
    simbCount := SIMBOLINWORD - 1;
    while simbCount >= 0 do
    begin
      //������� ��. � ��� � ���. ���� � �������
      if (fifoMas[round(countStep)] >= porog) then
      begin
        //������ 1 � ������ ���
        wordBuf := wordBuf or (1 shl simbCount);
      end
      else
      begin
        wordBuf := wordBuf or (0 shl simbCount);
      end;
      countStep := countStep + stepToTransOrbOne;
      if round(countStep) > FIFOSIZE then
      begin
        countStep := round(countStep) - FIFOSIZE;
      end;
      dec(simbCount);
    end;
    //���� ������� ������ ������
    //7 ��������� �������� �� �������� � ��������
    if (((fraseCount=2)or(fraseCount=4)or(fraseCount=6)or(fraseCount=8)or
        (fraseCount=10)or(fraseCount=12)or(fraseCount=14))and(wordCount=1)
       ) then
    begin
      if ((wordBuf and 1) <> 0) then
      begin
        bufNumGroup := (bufNumGroup shl 1) + 1;
      end
      else
      begin
        bufNumGroup := (bufNumGroup shl 1) + 0;
      end;
    end;
    if wordCount = {9}StrToInt(orbInf[3])+1 then
      //���� ����� ������ � 1 ����� ������� 12 ��� ��� ����� ������� ������ � �����
      //8 ��������. �� 01110010. �� 10001101
    begin
      Inc(countEvenFraseMGToMG);

      //12 ���
      if ((wordBuf and $800) <> 0) then
      begin
        bufMarkGroup := (bufMarkGroup shl 1) + 1;
      end
      else
      begin
        bufMarkGroup := (bufMarkGroup shl 1) + 0;
      end;

      //����� ��������� �����(�����) �� 64 ������ �����
      //��������� �� ������� �� ������ ������ 8 ���
      if ((bufMarkGroup and 255) = 114{112}) then
      begin
        //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' ��'); //TO-DO<><><>
        //+1 ��
        Inc(countForMG);
        if countEvenFraseMGToMG<>64 then
        begin
          //���� �� �� ����
          Inc(countErrorMG);
          //form1.Memo1.Lines.Add(IntToStr(countErrorMG));
        end;

        if countForMG={100}31 then
        begin
          //������� ����� ����� �� ��
          OutMG(countErrorMG);
          //form1.Memo1.Lines.Add(IntToStr(countErrorMG));
          countErrorMG:=0;
          countForMG:=0;
        end;

        countEvenFraseMGToMG:=0;


        fraseCount := 128;
        //���� ��������� ����
        //flagCountFrase:=true;
        flfl := true;
        //�������� ������ ������
        bufMarkGroup := 0;
        if (flagCountGroup) then
        begin
          inc(groupCount);
          if groupCount = 33 then
          begin
            groupCount := 1;
          end;
        end;
        //break;
      end;

      //��������� �� ������� �� ������ ����� 8 ���
      if ((bufMarkGroup and 255) = 141) then
      begin
        //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' ��');
        countEvenFraseMGToMG:=0;
        groupCount := 32;
        flagCountGroup := true;
        //�������� ������ �����
        bufMarkCircle := 0;
      end;
    end;

    //����� ������� �����
    //1 � 1 ���� 1 ����� 16 ����� 1 ������
    if ((wordCount = 1)and(fraseCount=16)and(groupCount=1))then
    begin
      if ((wordBuf and 1) = 1) then
      begin
        //������ ����� ������
        bufNumGroup:=0;
      end
      else
      begin
        //������ ����� �� ������
      end;
    end;

    //�������� ����������, ����������� 12 � 1 ���
    if (flagCountFrase) then
    begin
      //������ � ������ � �������� ����� 11 ���
      masGroup[iMasGroup] := wordBuf and 2047;{((wordBuf and 2047) shr 1)} {wordBuf} //!!!
      //������ � ������ � �������� ����� 12 ���
      masGroupAll[iMasGroup] := wordBuf and 4095;{((wordBuf and 2047) shr 1)} {wordBuf} //!!!
      inc(iMasGroup);
      //���� �������� ����. � ������� ����� ������
      if (flSinxC) then
      begin
        //������ � ���� 12 ������ ��������(���� ������)
        masCircle[reqArrayOfCircle][imasCircle] := {((} wordBuf { and 2046) shr 1)};
        inc(imasCircle);
        //��������� 32767 ���������
        if imasCircle = {length(masCircle[reqArrayOfCircle])}masCircleSize+1 then
        begin
          //form1.Memo1.Lines.Add(intToStr(length(masCircle[reqArrayOfCircle])));
          imasCircle := 1;
          //������ ����� ��������. ����� � ���� ���
          //���� ����� � ��� ������� �� ����� ����(���� ������ � ����)
          if (tlm.flagWriteTLM) then
          begin
            if infNum = 0 then
            begin
              //M16
              tlm.WriteTLMBlockM16(tlm.msTime);
            end
            else
            begin
              //������ ���������������
              tlm.WriteTLMBlockM08_04_02_01(tlm.msTime);
            end;
            {form1.WriteTLMTimer.Enabled:=true;}
          end;
        end;
      end;

      //��������� 1023 ��������
      if iMasGroup = {1024}{1025}masGroupSize+1 then //!!!!
      begin
        iMasGroup := 1;
        //�������� ������ ������ �� ���������
        form1.TimerOutToDia.Enabled := true;
        //��������� ������� �� 97 �������� ���  0..96
        {if (CollectBusArray(iBusArray)) then
          begin
           //��� ������ ������ �� ��������� ���
            form1.TimerOutToDiaBus.Enabled := true;
          end;  }
        //����� ���� �������� �� ���������
        OutToGistGeneral;
        { if (graphFlag) then
          begin
            OutToGist(masElemParam[chanelIndex].numOutElemG,
            masElemParam[chanelIndex].stepOutG,
            length(masGroup),numP);
          end;}
      end;
    end;

    wordBuf := 0;
    if ((wordCount = {16}numWordInByte) and (flfl)) then
    begin
      flagCountFrase := true;
    end;

    //!!!
    if (flagEnd) then
    begin
      form1.TimerOutToDia.Enabled := false;
      data.graphFlagSlowP := false;

      data.graphFlagTempP := false;
      data.graphFlagFastP := false;
      break;
    end;
    inc(wordCount);
  end;
end;
//==============================================================================

//=============================================================================
//
//=============================================================================
function TData.ReadFromFIFObuf: integer;
begin
  result := fifoMas[fifoLevelRead];
  inc(fifoLevelRead);
  if fifoLevelRead > {=} fifoSize then
  begin
    fifoLevelRead := 1;
  end;
  dec(fifoBufCount);
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

function TData.TestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
var
  i: integer;
  j: integer;
  testFlag: boolean;
begin
  i := begNumPoint;
  if i < 1 then
  begin
    i := FIFOSIZE;
  end;
  testFlag := true;
  for j := 1 to pointCounter do
  begin
    //���� ���� ����� ������ ������. ������ ��� �� ������
    //��������� �� ������� �� �� ������� ����� ������ � ��� �����. �����. � ������
    if i > FIFOSIZE then
    begin
      i := 1;
    end;
    if fifoMas[i] >= porog then
    begin
      testFlag := false;
    end;
    inc(i);
    //!!!
    if (flagEnd) then
    begin
      testFlag := false;
      break;
    end;
  end;
  result := testFlag;
end;
//==============================================================================

//==============================================================================
//������� ������ ������� ���������� ������ ������� �����
//==============================================================================
function TData.TestMFOnes(curNumPoint:Integer;numOnes:integer):Boolean;
var
  j:Integer;
  i:Integer;
  bool:Boolean;
  //flag:boolean;
begin
  bool:=true;
  //flag:=false;

  //TestSMFOutDate(10,curNumPoint,10);

 // if (not flag) then
  //begin
  //������������ � ������������������ ������ �������
  for j:=1 to numOnes do
  begin
    Dec(curNumPoint);
    if curNumPoint < 1 then
    begin
      curNumPoint := FIFOSIZE;
    end;
  end;
    //flag:=true;
  //end;

  //TestSMFOutDate(10,curNumPoint,10);

  for i:=1 to numOnes do
  begin
    if curNumPoint > FIFOSIZE then
    begin
      curNumPoint := 1;
    end;
    //Form1.Memo1.Lines.Add('�������');
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint]));
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint+1]));
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint+2]));
    if fifoMas[curNumPoint] < porog then
    begin
      bool:= false;
      break;
    end;
    Inc(curNumPoint);
  end;


  result:=bool;
end;
//==============================================================================

//==============================================================================
//������� ������ ������� ���������� ����� ������� �����
//==============================================================================
function TData.TestMFNull(curNumPoint:Integer;numNulls:integer):Boolean;
var
  bool:boolean;
  i:Integer;
begin
  bool:=true;
  for i:=1 to numNulls do
  begin
    if curNumPoint > FIFOSIZE then
    begin
      curNumPoint := 1;
    end;
    //Form1.Memo1.Lines.Add('����');
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint]));
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint+1]));
    //Form1.Memo1.Lines.Add(IntToStr(fifoMas[curNumPoint+2]));
    if fifoMas[curNumPoint] >= porog then
    begin
      bool:= false;
      break;
    end;
    Inc(curNumPoint);
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================

function TData.QtestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
var
  i: integer;
  j: integer;
  testFlag: boolean;
  m:integer;
begin
  //���������������� ������� ����� �������� �������
  i := begNumPoint;

  testFlag := false;

  if TestMFOnes(i,pointCounter) then
  begin
    if TestMFNull(i,pointCounter) then
    begin
      //��� ������
      testFlag:=true;
    end;
  end;
  {

  testFlag := true;
  //��������� ��� ������ ���������� ����������� ������ ������������
  for j := 1 to pointCounter do
  begin
    if i > FIFOSIZE then
    begin
      i := 1;
    end;

    {form1.Memo1.Lines.Add(inttostr(i-1220));
    form1.Memo1.Lines.Add(inttostr(i));

    for m:=i-3000 to i+3000 do
    begin
      form1.Memo1.Lines.Add(inttostr(m)+'   '+intTostr(fifoMas[m]));
    end;



    while (true) do application.processmessages; }







   { if fifoMas[i] < porog then
    begin
      testFlag := false;
      break;
    end;
    //!!!
    if (flagEnd) then
    begin
      testFlag := false;
      break;
    end;
    inc(i);
  end;
  //��������� ��� ����� ����. ����� ������ ��������� ������� �� �����
  if (testFlag) then
  begin
    for j := 1 to pointCounter do
    begin
      if i > FIFOSIZE then
      begin
        i := 1;
      end;
      if fifoMas[i] >= porog then
      begin
        testFlag := false;
        break;
      end;
      //!!!
      if (flagEnd) then
      begin
        testFlag := false;
        break;
      end;
      inc(i);
    end;
  end; }
  result := testFlag;
end;
//==============================================================================

//==============================================================================
//������� ��� ������ �� ������� ���� ������� ��������  offset -����� ��� ������ ����������� ���������
//============================================================================
function TData.ReadFromFIFObufB(offset: integer): integer;
var
  fifoOffset: integer;
begin
  //�������� �������� ��� ���������� �������
  //offset:=offset-1;
  if data.fifoLevelRead - offset < 1 then
  begin
    fifoOffset := FIFOSIZE - abs(data.fifoLevelRead - offset);
  end
  else
  begin
    fifoOffset := data.fifoLevelRead - offset;
  end;
  result := {data.fifoMas[} fifoOffset {]};
end;
//============================================================================

//==============================================================================
//������� ��� ������ �� ������� ���� ������� ��������  offset -����� ��� ������ ����������� ���������
//============================================================================

function TData.ReadFromFIFObufN(prevMarkFrBeg: integer; offset: integer): integer;
var
  fifoOffset: integer;
begin
  //�������� �������� ��� ���������� �������
  //offset:=offset-1;
  if prevMarkFrBeg + offset > FIFOSIZE then
  begin
    fifoOffset := (prevMarkFrBeg + offset) - FIFOSIZE;
  end
  else
  begin
    fifoOffset := prevMarkFrBeg + offset;
  end;
  result := {data.fifoMas[} fifoOffset {]};
end;
//============================================================================

procedure TForm1.upGistFastSizeClick(Sender: TObject);
begin
  form1.downGistFastSize.Enabled := true;
  //wait(1);
  testOutFalg:=false;
  //Application.ProcessMessages;
  sleep(50);
  //Application.ProcessMessages;
  if form1.fastGist.BottomAxis.Maximum <= form1.fastGist.BottomAxis.Minimum + {600}400 then
  begin
    form1.upGistFastSize.Enabled := false
  end
  else
  begin
    form1.fastGist.BottomAxis.Maximum := form1.fastGist.BottomAxis.Maximum - 20;
    //data.masFastVal:=nil;
    //setlength(data.masFastVal, trunc(form1.fastGist.BottomAxis.Maximum));
  end;
  testOutFalg:=true;
end;

procedure TForm1.downGistFastSizeClick(Sender: TObject);
begin
  testOutFalg:=false;
  form1.upGistFastSize.Enabled := true;
  sleep(50);
  //wait(1);
  //form1.Label5.Caption:=floatTostr(form1.fastGist.BottomAxis.Maximum);
  form1.fastGist.BottomAxis.Maximum := form1.fastGist.BottomAxis.Maximum + 20;
  if form1.fastGist.BottomAxis.Maximum >= {1800}2000 then
  begin
    form1.downGistFastSize.Enabled := false;
  end;
  testOutFalg:=true;
end;

procedure TForm1.tlmWriteBClick(Sender: TObject);
begin
  cOut:=0;
  if tlm.tlmBFlag then
  //������ ������ � ���
  begin
    form1.tlmWriteB.Caption := '0 Mb';
    //���� ����� � ��� �� �� ����� ��������� �����
    form1.startReadACP.Enabled:=false;
    //��� ����. �������� ��������� � 1 ��
    tlm.iOneGC := 4;
    tlm.StartWriteTLM;
    tlm.WriteTLMhead;
    //���� ������������� ��� ������ � ������ �����
    data.flSinxC := false;
    //��������� ������ ������ � ���� ���
    tlm.flagWriteTLM := true;
    //������������� ���� ������ ������ ����� � ����
    tlm.flagFirstWrite := true;
    tlm.flagEndWrite := false;
  end
  else
  //��������� ������ � ���
  begin
    //�������. ���� ��� �����. ������ � ������ �����
    data.flBeg := false;
    //���� ������������� ��� ������ � ������ �����
    data.flSinxC := false;
    tlm.flagWriteTLM := false;
    //form1.WriteTLMTimer.Enabled:=false;
    tlm.flagEndWrite := true;
    closeFile(tlm.PtlmFile);
    tlm.countWriteByteInFile := 0;
    tlm.precision := 0;
    form1.tlmWriteB.Caption := '������';
    //form1.Memo1.Lines.Add('���������� ���������� ������(������) '+
    //intToStr(tlm.blockNumInfile));
    ShowMessage('���� �������!');
    //���� tlm ��������, ����� ��������� �����
    form1.startReadACP.Enabled:=true;
  end;
  //�� ������� � �������� � ��������
  tlm.tlmBFlag := not tlm.tlmBFlag;
end;

procedure TForm1.startReadTlmBClick(Sender: TObject);
begin
  //���������� ��������������� ��������
  form1.fastGist.AllowZoom:=true;
  form1.fastGist.AllowPanning:=pmBoth;
  form1.gistSlowAnl.AllowZoom:=true;
  form1.gistSlowAnl.AllowPanning:=pmBoth;
  form1.tempGist.AllowZoom:=True;
  form1.tempGist.AllowPanning:=pmBoth;

  testOutFalg:=true;
  //�������. �������� ��� �����. �����. ������� ���� �������
  //��
  acumAnalog := 0;
  //����.
  acumTemp:=0;
  //��
  acumContact := 0;
  //�
  acumFast := 0;
  //����� ��������� � ��������� ���������
  data.ReInitialisation;
  data.Free;
  data := Tdata.CreateData;
  //������������ ���. ������.
  form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
  //��������� ����������� ������ �������
  GetAddrList;
  //��������� ������ ���������� �������
  SetOrbAddr;

  //�������� ������������ ������� �������
  if data.GenTestAdrCorrect then
  begin
    //������ ��� ������ � ���
    tlm := Ttlm.CreateTLM;
    //��������� �������� ��������
    form1.tlmPSpeed.Position := 3;
    form1.tlmPSpeed.Enabled:=true;
    //���������� ������� ����������
    data.FillAdressParam;
    ShowMessage('�������� ���� .tlm ��� ���������������!');
    form1.startReadACP.Enabled := false;
    //������� ��� ��������� �����
    tlm.OutFileName;
  end
  else
  begin
    showMessage('��������� ������������ �������!');
  end;
end;

procedure TForm1.Series4Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (data.graphFlagFastP) then
  begin
    data.graphFlagFastP := false;
    form1.Timer1.Enabled:=false;
    form1.fastGist.Series[0].Clear;
  end
  else
  begin
    //data.masFastVal := nil; //!!!
    //wait(1);
    //��������� ���������� ���������� � ���������� ������� �� �����
    data.chanelIndexFast := ValueIndex + acumAnalog + acumContact+acumTemp;
    //���������� ������������ ��� � ����������� �� ����
    //T22
    if masElemParam[data.chanelIndexFast].adressType = 2 then
    begin
      form1.fastGist.LeftAxis.Maximum := 64;
      form1.fastGist.LeftAxis.Minimum := 0;
    end;
    //T21
    if masElemParam[data.chanelIndexFast].adressType = 3 then
    begin
      form1.fastGist.LeftAxis.Maximum := 256;
      form1.fastGist.LeftAxis.Minimum := 0;
    end;
    //T24
    if masElemParam[data.chanelIndexFast].adressType = 5 then
    begin
      form1.fastGist.LeftAxis.Maximum := 64;
      form1.fastGist.LeftAxis.Minimum := 0;
    end;
    form1.Timer1.Enabled:=true;
    //����� ���������
    data.graphFlagFastP := true;
  end;
end;

procedure TForm1.TimerPlayTlmTimer(Sender: TObject);
begin
  if tlm.fFlag then
  begin
    tlm.ParseBlock(tlm.tlmPlaySpeed)
  end
  else
  begin
    form1.diaSlowAnl.Series[0].Clear;
    form1.diaSlowCont.Series[0].Clear;
    form1.fastDia.Series[0].Clear;
    form1.fastGist.Series[0].Clear;
    form1.gistSlowAnl.Series[0].Clear;
  end;
end;

procedure TForm1.playClick(Sender: TObject);
begin
  form1.TimerPlayTlm.Enabled := true;
end;

procedure TForm1.pauseClick(Sender: TObject);
begin
  form1.TimerPlayTlm.Enabled := false;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  if ((form1.TrackBar1.Position <= form1.TrackBar1.Max) and
      (form1.TrackBar1.Position >= form1.TrackBar1.Min)) then
  begin
    form1.TimerPlayTlm.Enabled := false;
    //tlm.stream.Seek(SIZEBLOCKPREF,soFromCurrent);
    //288 ����������������� �������� ��� ����������� ������ �� �����
    tlm.stream.Position := (form1.TrackBar1.Position - 1) * tlm.sizeBlock + MAXHEADSIZE;
    //form1.Memo1.Lines.Add(intToStr(tlm.stream.Position));
    form1.TimerPlayTlm.Enabled := true;
  end
end;

procedure TForm1.stopClick(Sender: TObject);
begin
  form1.propB.Enabled := true;
  //����. ������� ������ �����
  form1.TimerPlayTlm.Enabled := false;
  form1.TrackBar1.Enabled := false;
  //���� ������ ������
  form1.PanelPlayer.Enabled := false;
  //����� ������ ������
  form1.startReadACP.Enabled := true;
  form1.startReadTlmB.Enabled := true;
  //����� �������� � ������
  form1.TrackBar1.Position := 1;
  form1.fileNameLabel.Caption := '';
  form1.orbTimeLabel.Caption := '';
  //���������� ������������
  tlm.fFlag := false;
  form1.TimerPlayTlm.Enabled := false;
  //����� �����
  tlm.stream.Free;
  wait(10);
  form1.diaSlowAnl.Series[0].Clear;
  form1.diaSlowCont.Series[0].Clear;
  form1.fastDia.Series[0].Clear;
  form1.fastGist.Series[0].Clear;
  form1.gistSlowAnl.Series[0].Clear;
end;

procedure TForm1.tlmPSpeedChange(Sender: TObject);
begin
  if form1.TrackBar1.Enabled then
  begin
    form1.TimerPlayTlm.Enabled := false;
  end;
  case self.tlmPSpeed.Position of
    0:
    begin
      tlm.tlmPlaySpeed := 1;
    end;
    1:
    begin
      tlm.tlmPlaySpeed := 2;
    end;
    2:
    begin
      tlm.tlmPlaySpeed := 3;
    end;
    3:
    begin
      tlm.tlmPlaySpeed := 4;
    end;
    4:
    begin
      tlm.tlmPlaySpeed := 5;
    end;
    5:
    begin
      tlm.tlmPlaySpeed := 6;
    end;
    6:
    begin
      tlm.tlmPlaySpeed := 7;
    end;
    7:
    begin
      tlm.tlmPlaySpeed := 8;
    end;
  end;
  if form1.TrackBar1.Enabled then
  begin
    form1.TimerPlayTlm.Enabled := true;
  end;
end;

procedure TForm1.propBClick(Sender: TObject);
begin
  //��� ����� �������� ������� ������ ���. �������.
  form1.OrbitaAddresMemo.Clear;
  ShowMessage('�������� ���� ������� ������!');
  form1.OpenDialog2.InitialDir:=ExtractFileDir(ParamStr(0))+'\ConfigDir';;
  //�������� � �����. ���� ��������.
  if form1.OpenDialog2.Execute then
  begin
    propIniFile:=TIniFile.Create(ExtractFileDir(ParamStr(0))+'\ConfigDir\property.ini');
    //propStrPath:=propIniFile.ReadString('lastPropFile','path','');
    //������ ���� �� ����� ��������
    propIniFile.WriteString('lastPropFile','path',form1.OpenDialog2.FileName);
    //������� ��������� ����.
    propStrPath:=propIniFile.ReadString('lastPropFile','path','');
    propIniFile.Free;
    //�������� ������ ����������� ��������
    form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
    //��������� ����������� ������ �������
    GetAddrList;
    //��������� ������ ���������� �������
    SetOrbAddr;

    form1.startReadACP.Enabled := true;
    form1.startReadTlmB.Enabled := true;
    form1.saveAdrB.Enabled:=true;
  end
  else
  //�� ������
  begin
    ShowMessage('���� ������� ������ �� ������!');
  end;
end;

procedure TForm1.saveAdrBClick(Sender: TObject);
var
  strOut:string;
begin
  strOut:=ExtractFileName(propStrPath){RightStr(propStrPath,7)};
  showMessage('���� ������� '+strOut+' �������!');
  form1.OrbitaAddresMemo.Lines.SaveToFile(propStrPath);
  wait(10);
end;

procedure TForm1.Series5Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (data.graphFlagBusP) then
  begin
    form1.busGist.Series[0].Clear;
    data.graphFlagBusP := false;
  end
  else
  begin
    data.chanelIndexBus := ValueIndex+acumAnalog + acumContact+acumTemp+acumFast;
    data.graphFlagBusP := true;
  end;
end;

procedure TForm1.TimerOutToDiaBusTimer(Sender: TObject);
var
iBus:integer;
busArrayLen:Integer;
begin
  form1.busGist.Series[0].Clear;
  //sleep(3);
  busArrayLen:=length(data.busArray);
  for iBus:=0 to busArrayLen  do
  begin
    form1.busDia.Series[0].AddXY(iBus, data.busArray[iBus]);
  end;
  form1.TimerOutToDiaBus.Enabled := false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  {if ((form1.upGistFastSize.Enabled)and(form1.downGistFastSize.Enabled)) then
  begin
    form1.upGistFastSize.Enabled:=false;
    form1.downGistFastSize.Enabled:=false;
  end
  else
  begin
    form1.upGistFastSize.Enabled:=true;
    form1.downGistFastSize.Enabled:=true;
  end;}
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  WinExec(PChar('OrbitaMAll.exe'), SW_ShowNormal);
end;

procedure TForm1.tmrForTestOrbSignalTimer(Sender: TObject);
begin
  if orbOkCounter>=40000 then
  begin
    orbOkCounter:=0;
    if (orbOk) then
    begin
      //������ ������
      form1.tmrForTestOrbSignal.Enabled:=false;
    end
    else
    begin
      form1.tmrForTestOrbSignal.Enabled:=false;
      ShowMessage('������ ������ �� ������! ��������� ������!');
      data.graphFlagFastP := false;

      //Application.ProcessMessages;
      sleep(50);
      //Application.ProcessMessages;

      if ((form1.tlmWriteB.Enabled)and
          (not form1.startReadTlmB.Enabled)and
          (not form1.propB.Enabled))  then
      begin
        //��������� ������ � ���
        pModule.STOP_ADC();
      end;
      //�������� ��� ���������� �����
      flagEnd:=true;
      wait(20);
      //�������� ���������� �� �����������.
      Application.Terminate;
    end;
  end;
end;

procedure TForm1.Series7Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //�������� ������� � ����. � � ������ �����������
  //���� ������ ��� ����������� � ��������
  //form1.OrbitaAddresMemo.Enabled:= not form1.OrbitaAddresMemo.Enabled;
  //form1.Memo1.Enabled:= not form1.Memo1.Enabled;
  if (data.graphFlagTempP) then
  begin
    form1.tempGist.Series[0].Clear;
    data.graphFlagTempP := false;
  end
  else
  begin
    data.graphFlagTempP := true;
    //form1.dia.Canvas.MoveTo(form1.dia.Width-1051,form1.dia.Height-33);
    data.chanelIndexTemp := ValueIndex;
  end;
end;

procedure TForm1.upGistTempSizeClick(Sender: TObject);
begin
  form1.downGistTempSize.Enabled := true;
  if form1.tempGist.BottomAxis.Maximum <=form1.tempGist.BottomAxis.Minimum + 20 then
  begin
    form1.upGistTempSize.Enabled := false
  end
  else
  begin
    form1.tempGist.BottomAxis.Maximum := form1.tempGist.BottomAxis.Maximum - 10;
  end;
end;

procedure TForm1.downGistTempSizeClick(Sender: TObject);
begin
  form1.upGistTempSize.Enabled := true;
  form1.tempGist.BottomAxis.Maximum := form1.tempGist.BottomAxis.Maximum + 10;
  if form1.tempGist.BottomAxis.Maximum >= 700 then
  begin
    form1.downGistTempSize.Enabled := false;
  end;
end;

end.

