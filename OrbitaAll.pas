unit OrbitaAll;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, StdCtrls, Series, TeEngine, TeeProcs, Chart, ExtCtrls,
  Lusbapi, {Visa_h,} Math, Buttons, ComCtrls, xpman, DateUtils,
  MPlayer,iniFiles,StrUtils,syncobjs,ExitForm, Gauges;
//Lusbapi-библиотека для работы с АЦП Е20-10
//Visa_h-библиотека для работы с генератором и вольтметром

const
  //АЦП
  // частота ввода данных
  ADCRATE: double = 10000.0; //3145.728
  // кол-во активных каналов
  CHANNELSQUANTITY: WORD = $01;
  //размер кольцевого буфера(хранит Орбитовкие биты)
  FIFOSIZE = 2500000;
  //размер массива группы. В каждой ячейке хранится значение слова в 10-ом формате
  SIZEMASGROUP=2048;
  //количество блоков(циклов Орбиты обрабатываемых за один проход)
  NUMBLOCK = 4;
  SIZEBLOCKPREF = 32;
  MAXHEADSIZE = 256;

  //M08,04,02,01
  // размеры маркера 1/2 размера бита
  MARKMINSIZE = 3;
  MARKMAXSIZE = 4;
  //мин колич точек между маркерами
  MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR = 1220;
  //количество точек выводимое за 1 раз на график
  NUMPOINTINTCOUT = 10;

  //колич. значений в массиве БУС
  NUM_BUS_ELEM=96;
  //знач. маркера БУС.
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

  //новый тип. Реализация так называемого двойного буфера.
  TShortrArray = array[0..1] of array of SHORT;

  //тип двойного буфера (для буфера цикла)
  TDBufCircleArray = array[0..1] of array[1..SIZEMASGROUP*32] of word;

  Ttlm = class(TObject)
    //файл тлм
    //PtlmFile:file of byte;
    //переменная для работы с файлом тлм
    PtlmFile: file;
    //для генерации имени тлм файла
    fileName: string;
    //время создания файла tlm в формате unixtime
    msTime: cardinal;
    //номер записываемого блока
    blockNumInfile: Cardinal;
    //колич. слов в блоке
    wordNumInBlock: Cardinal;
    //время с момента запуска записи
    timeBlock: cardinal;
    //резерв1
    rez: cardinal;
    //признак КПСЕВ
    prKPSEV: cardinal;
    //получаем текущую дату
    nowTime: TDateTime;
    //ч
    hour: byte;
    //м
    minute: byte;
    //сек
    sec: byte;
    //mc
    mSec: word;
    //mcs
    mcSec: byte;
    //резерв2
    rez1M08_04_02_01:word;
    rez1M16: byte;
    //поле признака
    prSEV: byte;
    error: byte;
    //резерв3
    rez2: cardinal;
    //для запуска и остановки записи в тлм
    flagWriteTLM: boolean;

    //байтовый массив заголовка и счетчик работы с ним
    tlmHeadByteArray: array of byte;
    iTlmHeadByteArray: integer;

    //байтовый массив заголовка и счетчик работы с ним
    tlmBlockByteArray: array of byte;
    iTlmBlockByteArray: integer;

    //флаг записи первого блока
    flagFirstWrite: boolean;
    //флаг для дозаписи блока
    flagEndWrite: boolean;
    //счетчик для установки бита в 1 ГЦ
    iOneGC: integer;
    //количество записаных байт в файл тлм
    countWriteByteInFile: int64;
    //нач. точность вывода запис. байт.
    precision: integer;
    stream: TFileStream;
    //количество блоков обр. за 1 проход
    tlmPlaySpeed: integer;
    //флаг синхронизации для правильного выключения таймера
    fFlag: boolean;
    //флаг для определения вести запись в тлм или останавливать ее
    tlmBFlag: boolean;
    //количество байт в блоке тлм  в зависимости от информативности
    sizeBlock: integer;
    //байтовый массив блока
    //blockOrbArr: array  of byte;
    //байтовые массивы блока в зависимости от информативности
    arr1: array[0..131103] of byte;
    arr2: array[0..65567] of byte;
    arr3: array[0..32799] of byte;
    arr4: array[0..16415] of byte;
    arr5: array[0..8223] of byte;

    //запись побайтно заголовка файла. формир. буфера
    procedure WriteToFile(str: string); overload;
    //запись нулевых значений в заголовок файла ТЛМ
    procedure WriteToFile(nullVal: byte); overload;
    //запись побайтно префиксов и блоков. форм. буфера
    procedure WriteByteToByte(multiByteValue: cardinal); overload;
    procedure WriteByteToByte(multiByteValue: word); overload;
    procedure WriteByteToByte(multiByteValue: byte); overload;
    //вывод на форму количества записаных в файл Мбайт
    procedure OutTLMfileSize(numWriteByteInFile: int64; var numValBefore: integer);
    //запись заголовка
    procedure WriteTLMhead;
    //запись блока M16
    procedure WriteTLMBlockM16(msStartFile: cardinal);
    //запись блока M08_04_02_01
    procedure WriteTLMBlockM08_04_02_01(msStartFile: cardinal);
    //запись блока данных с прибора инф. M16
    procedure WriteCircleM16;
    //запись блока данных с прибора инф. M08_04_02_01
    procedure WriteCircleM08_04_02_01;
    //нач. иниц объекта
    constructor CreateTLM;
    //запуск записи в ТЛМ
    procedure StartWriteTLM;
    //вывод названия файла
    procedure OutFileName;
    //подготовка к работе с тлм файлом
    procedure BeginWork;
    //разбор переданного количества блоков Орб. файла
    procedure ParseBlock(countBlock: word);
    //сбор массива группы
    procedure CollectOrbGroup;
    //сбор времени блока
    procedure CollectBlockTime;
    function ConvTimeToStr(t: cardinal): string;
  end;

  //тип элемента массива для вывода на график
type
  channelOutParam = record
    //номер первой точки в массиве группы
    numOutElemG: integer;
    //шаг до след. номера точки в массиве группы
    stepOutG: integer;
    //0-аналоговый адрес. 1-контактный адрес. 2-быстрые параметры
    adressType: short;
    //номер бита в значении, для получ. значения контактного канала.
    //0-аналоговый канал. 1-8 номера битов.
    bitNumber: short;
    //номер потока для БУС.
    numBusThread: short;
    //адрес БУС.
    adrBus: short;
    //номер адреса в таблице для БУС
    numAdrInTable: short;
    //номер 1 канала в пакете БУС
    numAdrInBusPocket: short;
    //номер 2 канала в пакете БУС
    numAdrInBusPocket2: short;
    //!!! номер текущей точки для вывода на гистограмму
    numOutPoint: short;
  end;

  Tdata = class(TObject)
    //флаг для вычисления порога 1 раз
    modC: boolean;
    //переменная размерности буфера данных с АЦП.
    buffDivide: integer;
    //номер выводимой точки на гистограмму
    numP: integer;
    numPfast: integer;
    // порог(среднее значение сигнала которое будет проверяться разбора сигнала)
    porog: integer;
    //для хранения значения контактного канала
    contVal: integer;
    //счетчик количества повторяющихся точек выше порога
    numRetimePointUp: integer;
    //счетчик количества повторяющихся точек ниже порога
    numRetimePointDown: integer;
    //переменная числа выводов в файл
    outStep: integer;

    //счетчик буфера для разбора массива
    fifoBufCount: integer;
    //счетчик для записи в массив fifo
    fifoLevelWrite: integer;
    //счетчик чтения из fifo
    fifoLevelRead: integer;

    //массив для хранения битов орбиты
    fifoMas: array[1..FIFOSIZE] of integer;
    //счетчик для заполнения аналоговых параметров БУС
    masAnlBusChCount: integer;
    //флаг показывающий что первая фраза найдена
    firstFraseFl: boolean;
    //текущее значение измерения из кольцевого буфера
    current: integer;

    //количество точек через которое должен начаться след. маркер
    pointCount: integer;
    //счетчик для сбора 12 разр. слова Орбиты
    iBit: integer;
    //переменная разрядность кода. количество битов в слове.
    bitSizeWord: integer;

    //аккум. 12 разр. слова Орбиты
    codStr: word;
    //счетчик номера слова Орбиты
    wordNum: integer;
    //счетчик групп
    groupWordCount: integer;
    //счетчик фраз
    fraseNum: integer;

    //переменная для моей внутренней нумерации групп
    myFraseNum: integer;
    //беззнаковая. 8 битов.
    markerNumGroup: byte;
    //для нумерации выводов номеров маркеров групп в файл
    nMarkerNumGroup: integer;
    //знаковая. 8 битов
    markerGroup: byte;
    //для сбора слов Орбиты
    flagL: boolean;

    //флаг вывода фраз, что до этого была найдена 128 фраза
    flagOutFraseNum: boolean;

    //аккум. 11 разр. слова Орбиты. на графики
    wordInfo: integer;
    //разр. записи в массив группы
    startWriteMasGroup: boolean;
    //массив для хранения значения слов Орбиты.11 младших битов
    {masGroup:array[1..SIZEMASGROUP] of word;}

    //массив для хранения значения слов Орбиты.12 битов
    {masGroupAll:array[1..SIZEMASGROUP] of word;}

    //для двойной буферизации
    reqArrayOfCircle: short;
    //для заполнения  masCircle
    imasCircle: integer;
    //для заполнения массива цикла с начала 1 слово первой фразы первой группы
    flSinxC: boolean;
    // вспомог. переменная для flSinxC
    flBeg: boolean;

    //вывод.аналоговые и контактные каналы
    graphFlagSlowP: boolean;
    //вывод.температурные параметры
    graphFlagTempP: boolean;
    //вывод. быстрые каналы
    graphFlagFastP: boolean;
    //вывод. БУС каналы
    graphFlagBusP: boolean;

    //счетчик для вывода на график быстрых параметров
    countPastOut: integer;
    //массив из которого выводим быстрые значения
    masFastVal: array{[1..100000]} of double;
    //номер канала на гистограмме значения
    //которого будут выводится на график медл.
    chanelIndexSlow: integer;
    //номер канала на гистограмме значения
    //которого будут выводится на график медл.
    chanelIndexTemp: integer;
    //номер канала на гистограмме значения которого
    //будут выводится на график быст.
    chanelIndexFast: integer;
    //номер канала на гистограмме значения которого
    //будут выводится на график БУС
    chanelIndexBus:integer;
    //счетчики для подсчета адресов аналоговых и контактных каналов
    analogAdrCount: integer;
    contactAdrCount: integer;
    tempAdrCount:Integer;
    //bool:boolean;

    //----------------------------------- M08,04,02,01
    fraseMarkFl: boolean;
    countPointMrFrToMrFr: integer;
    //флаг для осущ. быстрого поиска маркера фразы
    qSearchFl: boolean;
    iMasGroup: integer;
    //флаг для начала счета фраз
    flagCountFrase: boolean;
    //счетчик фраз
    fraseCount: integer;
    //счетчик групп
    groupCount: integer;
    //буфер для сбора маркера группы
    bufMarkGroup: int64;
    //7 разрядное значение с 0 до 127 номера группы
    bufNumGroup:byte;
    flfl: boolean;
    //флаг дял начала подсчета групп
    flagCountGroup: boolean;
    //буфер для сбора маркера цикла
    bufMarkCircle: int64;
    //массив значений слов БУС.
    busArray:array of word;
    //счетчик заполненных слов БУС
    iBusArray:integer;
    //флаг для поиска маркера для зап. массива БУС
    flagWtoBusArray:boolean;
    //коеф. для поиска маркера фразы для М08,04,02,01 зависит от информативности
    markKoef:Double;
    //ширина в точках половины маркера фразы в завис от информативности.
    //3=111000,6=1111110000000
    widthPartOfMF:integer;
    //количество точек между маркерами фраз в завис. от информативности
    minSizeBetweenMrFrToMrFr:Integer;
    //счетчик для подсчета маркеров фраз от 1 до 100
    countForMF:Integer;
    //счетчик ошибок поиска маркера фразы за 100 раз
    countErrorMF:Integer;

    //счетчик четных фраз от маркера группы до маркера группы
    countEvenFraseMGToMG:integer;
    //счетчик для подсчета маркеров групп от 1 до 100
    countForMG:Integer;
    //счетчик ошибок поиска маркера группы за 100 раз
    countErrorMG:Integer;

    procedure OutMF(errMF:Integer);
    procedure OutMG(errMG:Integer);
    //проверка наличия нужного колич единиц маркера фразы
    function TestMFOnes(curNumPoint:Integer;numOnes:integer):Boolean;
    //проверка наличия нужного колич нулей маркера фразы
    function TestMFNull(curNumPoint:Integer;numNulls:integer):Boolean;
    //вспомогательная процедура для вывода данных маркетра фразы
    procedure TestSMFOutDate(numPointDown:Integer;numCurPoint:integer;numPointUp:integer);
    //Функция поиска перехода из 0 в 1
    function SearchP0To1(curPoint:Integer;nextPoint:integer):Boolean;
    //Функция поиска перехода из 1 в 0
    function SearchP1To0(curPoint:Integer;nextPoint:integer):Boolean;
    //Вывод данных на графики
    procedure OutDate;
    //запись бита орбиты в слово
    procedure FillBitInWord;
    //разбор фразы
    procedure AnalyseFrase;
    //сбор быстрого параметра T22
    function BuildFastValueT22(value: integer; fastWordNum: integer): integer;
    //сбор быстрого параметра T24
    function BuildFastValueT24(value: integer; fastWordNum: integer): integer;
    //сбор контактного параметра
    function OutputValueForBit(value: integer; bitNum: integer): short;
    //поиск маркера фразы
    procedure SearchFirstFraseMarker;
    //общая спроцедура вывода на гистограммы
    procedure OutToGistGeneral;
    //заполнение массива группы
    procedure FillArrayGroup;
    //заполнение массива цикла
    procedure FillArrayCircle;
    //сбор маркера номера группы
    procedure CollectMarkNumGroup;
    //сбор маркера группы
    procedure CollectMarkGroup;
    //procedure AddValueInMasDiaValue(numFOut:integer;step:integer;
      //masGSize:integer;var numP:integer);
    //вывод на гистограмму
    procedure OutToDia(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numChanel: integer; typeOfAddres: short;
      numBitOfValue: short; busTh: short; busAdr: short; var numOutPoint: short);
    //вывод на гистограмму аналоговые
    procedure OutToGistSlowAnl(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numP: integer);
    //вывод на гистограмму температурные
    procedure OutToGistTemp(firstPointValue: integer; outStep: integer;
      masOutSize: integer; var numP: integer);
    //вывод на гистограмму быстрые
    procedure OutToGistFastParam(firstPointValue: integer; outStep: integer;
      masOutSize: integer; adrtype: short;
      var numPfast: integer; numBitOfValue: integer);
    //вывод на гистограмму БУС
    procedure OutToGistBusParam(firstPointValue: integer; outStep: integer;
      masOutSize: integer; adrtype: short;
      var numPfast: integer; numBitOfValue: integer);
    
    //Процедура для осуществления разбора адреса Орбиты
      // и заполнения массива номеров точек для осущ. вывода на график
    procedure AdressAnalyser(adressString: string; var imasElemParam: integer);
    procedure FillAdressParam;
    //подсчет скольок каких адресов в конфиге было передано
    procedure CountAddres;
    function SignalPorogCalk(bufMasSize: integer; acpBuf: TShortrArray;
      reqNumb: word): integer;
    procedure Add(signalElemValue: integer);
    //обработка сигнала для M16
    procedure TreatmentM16;
    ////обработка сигнала для M08,04,02,01
    procedure TreatmentM8_4_2_1;
    function Read(): integer; overload;
    function Read(offset: integer): integer; overload;
    //подготовка программы к приему или чтению данных
    procedure ReInitialisation;
    //проверка соответствия адресов Орбиты
    function GenTestAdrCorrect:boolean;
    //проверка соотв. инф. загруж. адресам
    function AditTestAdrCorrect: boolean;
    //сохранение отчета
    //procedure SaveReport;
    //для работы с системным файлом(признак проверки туда пишем(system))
    procedure WriteSystemInfo(value: string);
    //подсчет среднего значения в массиве группы
    function AvrValue(firstOutPoint: integer; nextPointStep: integer;
      masGroupS: integer): integer;
    constructor CreateData;

    //m08,04,02,01
    //
    procedure WriteToFIFObuf(valueACP: integer);
    //поиск первого маркера
    function FindFraseMark(var fifoLevelRead: integer): integer;
    //переход на нужное количество точек вперед
    procedure FifoNextPoint(countPoint: integer);
    //быстрый поиск маркера фразы
    function QfindFraseMark: boolean;
    //передаем начало предидущего маркера (номер точки),
    //начало текущего маркера, информативность Орбиты
    procedure FillMasGroup(countPointToPrevM: integer;
      currentMarkFrBeg: integer; orbInf: string; var iMasGroup: integer);
    //переход на нужное количество точек назад
    procedure FifoBackPoint(countPoint: integer);
    //чтение 1 значения с кольц.буф
    function ReadFromFIFObuf: integer;
    function TestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
    function QtestMarker(begNumPoint: integer; const pointCounter: integer): boolean;
    function ReadFromFIFObufB(offset: integer): integer;
    function ReadFromFIFObufN(prevMarkFrBeg: integer; offset: integer): integer;
    function BuildBusValue(highVal:word;lowerVal:word):word;
    function CollectBusArray(var iBusArray:integer):boolean;
  end;

  Tacp = class(TObject)

    //функция для работы с Ацп в отдельномм потоке
    function ReadThread: DWORD;
    //вывод сообщения об ошибке
    procedure AbortProgram(ErrorString: string; AbortionFlag: bool = true);
    function WaitingForRequestCompleted(var ReadOv: OVERLAPPED): boolean;
    procedure ShowThreadErrorMessage;
    //иниц.
    constructor InitApc;
    procedure CreateApc;

  end;

  //тип записи псевдомассива
type
  adrElement = record
    litera: char;
    n: short;
    k: short;
  end;

var
  Form1: TForm1;

  //===================================
  //Переменные для работы с АЦП
  //===================================

  //=============================
  //Параметры приборов.
  //=============================
  //RS485
  //переменная для хранения ip-адреса адаптера RS485 (ini-файл)
  HostAdapterRS485: string;
  //переменная для хранения номера порта для адаптера
  PortAdapterRS485: integer;
  //ИСД1
  //переменная для хранения ip-адреса первого ИСД (ini-файл)
  HostISD1: string;
  //ИСД2
  //переменная для хранения ip-адреса второго ИСД (ini-файл)
  HostISD2: string;
  //Генератор
  //переменная для хранения идентификатора генератора
  RigolDg1022: string;
  //Вольтметр
  m_defaultRM_usbtmc, m_instr_usbtmc: array[0..3] of LongWord;
  viAttr: Longword = $3FFF001A;
  Timeout: integer = 1000; //7000
  //==============================

  //==============================
  //Работа с файлами
  //==============================
  //файловая переменная для работы с системным файлом
  systemFile: Text;
  //файловая переменная для формирования отчета проверки в файл
  reportFile: Text;
  //файл данных с АЦП
  LogFile: text;
  //==============================

  //класс для работы с сигналом Орбита
  data: Tdata;
  //класс для работы с TLM
  tlm: Ttlm;
  //класс для работы с АЦП
  acp: Tacp;

  //опис. массив для параметров адресов
  masElemParam: array of channelOutParam;

  arrAddrOk:array of string;

  //счетчик хранит максим. число адреосв Орбиты
  iCountMax: integer;
  //кол. аналоговых каналов
  acumAnalog: integer;
  //колич. температурных каналов
  acumTemp:Integer;
  //кол. контактных
  acumContact: integer;
  //кол. быстрых
  acumFast: integer;
  //кол. БУС каналов
  acumBus:integer;
  //количество Орбитовских слов в массиве группы от информативности
  masGroupSize: integer;
  //количество Орбитовских слов в массиве цикла от информативности
  masCircleSize:cardinal;
  masGroup: array[1..SIZEMASGROUP] of word;
  masGroupAll: array[1..SIZEMASGROUP] of word;
  //хранит целиковый цикл
  masCircle: TDBufCircleArray;
  //номер информативности Орбиты
  infNum: integer;
  //строка с информативностью Орбиты
  infStr: string;

  // идентификатор потока ввода
  hReadThread: THANDLE;
  ReadTid: DWORD;
  // флажок завершения потоков ввода данных
  IsReadThreadComplete: boolean;
  // экранный счетчик-индикатор
  Counter, OldCounter: WORD;
  // версия библиотеки Rtusbapi.dll
  DllVersion: DWORD;
  // идентификатор устройства
  ModuleHandle: THandle;
  // скорость работы шины USB
  UsbSpeed: BYTE;
  // структура с полной информацией о модуле
  ModuleDescription: MODULE_DESCRIPTION_E2010;
  // состояние процесса сбора данных
  DataState: DATA_STATE_E2010;
  // буфер пользовательского ППЗУ
  UserFlash: USER_FLASH_E2010;
  // структура параметров работы АЦП
  ap: ADC_PARS_E2010;
  // кол-во отсчетов в запросе ReadData
  DataStep: DWORD;
  // интерфейс модуля E20-10
  pModule: ILE2010;
  // название модуля
  ModuleName: string;
  // указатель на буфер для данных
  Buffer: TShortrArray;
  //номер запроса
  RequestNumber: WORD;
  // вспомогательная стр.
  Str: string;
  // столько блоков по DataStep отсчётов нужно собрать в файл
  NBlockToRead: WORD; // = 4*20;
  //массив OVERLAPPED структур из двух элементов
  ReadOv: array[0..1] of OVERLAPPED;
  // массив структур с параметрами запроса на ввод/вывод данных
  IoReq: array[0..1] of IO_REQUEST_LUSBAPI;
  // номер ошибки при выполнения потока сбора данных
  ReadThreadErrorNumber: WORD;

  //счетчик для подсчета циклов чтения
  countC: integer;

  //переменная для ini файла для запоминания пути последнего файла настроек
  propIniFile:TiniFile;
  propStrPath:string;


  flagEnd:boolean;

  //файл для 32-разр. слов
  //swtFile:text;

  cOut:integer;
  csk:TCriticalSection;

  boolFlg:boolean;

  testOutFalg:boolean;

  //textTestFile:Text;
  //флаг что сигнал Орбиты нашли
  orbOk:Boolean;
  orbOkCounter:integer;
implementation

//uses Unit1;

{$R *.dfm}

//==============================================================================
//Процедуры отвечающие за вывод в файл
//==============================================================================
//формирование файла логов

{procedure SaveBitToLog(str: string);
begin
  Writeln(LogFile,str);
  exit
end;}
//==============================================================================

//==============================================================================
//Функция задержки
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
      //исключаем пустые строки
      //выделим память на элемент массива параметров
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
  //очищаем список адресов
  form1.OrbitaAddresMemo.Clear;
  maxAdrNum:=Length(arrAddrOk)-1;
  for iAdr:=0 to maxAdrNum do
  begin
    form1.OrbitaAddresMemo.Lines.Add(arrAddrOk[iAdr]);
  end;
end;
//==============================================================================

//==============================================================================
//Функции по работе с АЦП
//==============================================================================

// Отображение ошибок возникших во время работы потока сбора данных
//==============================================================================

procedure Tacp.ShowThreadErrorMessage;
begin
  case ReadThreadErrorNumber of
    $0: ;
    $1: showMessage(' ADC Thread: STOP_ADC() --> Bad! :(((');
    $2: showMessage(' ADC Thread: ReadData() --> Bad :(((');
    $3: showMessage(' ADC Thread: Waiting data Error! :(((');
    // если программа была злобно прервана, предъявим ноту протеста
    $4: showMessage(' ADC Thread: The program was terminated! :(((');
    $5: showMessage(' ADC Thread: Writing data file error! :(((');
    $6: showMessage(' ADC Thread: START_ADC() --> Bad :(((');
    $7: showMessage(' ADC Thread: GET_DATA_STATE() --> Bad :(((');
    $8: showMessage(' ADC Thread: BUFFER OVERRUN --> Bad :(((');
    $9: showMessage(' ADC Thread: Can''t cancel' +
         ' pending input and output (I/O) operations! :(((');
    $10: showMessage('Ошибка! Порог не определен!');

    else
      showMessage(' ADC Thread: Unknown error! :(((');
  end;
end;
//==============================================================================

//==============================================================================
// Аварийное завершение программы. Вспомогательная подпрограмма для основной
//==============================================================================

procedure Tacp.AbortProgram(ErrorString: string; AbortionFlag: bool = true);
var
  i: WORD;
begin
  // освободим интерфейс модуля
  if pModule <> nil then
  begin
    // освободим интерфейс модуля
    if not pModule.ReleaseLInstance() then
    begin
      //form1.Memo1.Lines.Add('ReleaseLInstance() --> Bad')
      showMessage('ReleaseLInstance() --> Bad')
    end
    else
    begin
      //showMessage('ReleaseLInstance() --> OK');
      //form1.Memo1.Lines.Add('ReleaseLInstance() --> OK');
      //обнулим указатель на интерфейс модуля
      pModule := nil;
    end;
    // освободим память из-под буферов данных
    for i := 0 to 1 do
    begin
      Buffer[i] := nil;
    end;
    // если нужно - выводим сообщение с ошибкой
    if ErrorString <> ' ' then
    begin
      MessageBox(HWND(nil),pCHAR(ErrorString),'ОШИБКА!!!', MB_OK + MB_ICONINFORMATION);
    end;
    // если нужно - аварийно завершаем программу
    if AbortionFlag = true then
    begin
      halt;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//      Функция запускаемая в качестве отдельного потока
//             для сбора данных c модуля E20-10
//==============================================================================
function Tacp.ReadThread: DWORD;
var
  indJ: integer;
  iReadThread: WORD;
  m:integer;
begin
  // остановим работу АЦП и одновременно сбросим USB-канал чтения данных
  if not pModule.STOP_ADC() then
  begin
    ReadThreadErrorNumber := 1;
    IsReadThreadComplete := true;
    result := 1;
    exit;
  end;

  // формируем необходимые для сбора данных структуры
  for iReadThread := 0 to 1 do
  begin
    // инициализация структуры типа OVERLAPPED
    ZeroMemory(@ReadOv[iReadThread], sizeof(OVERLAPPED));
    // создаём событие для асинхронного запроса
    ReadOv[iReadThread].hEvent := CreateEvent(nil, FALSE, FALSE, nil);
    // формируем структуру IoReq
    IoReq[iReadThread].Buffer := Pointer(Buffer[iReadThread]);
    IoReq[iReadThread].NumberOfWordsToPass := DataStep;
    IoReq[iReadThread].NumberOfWordsPassed := 0;
    IoReq[iReadThread].Overlapped := @ReadOv[iReadThread];
    IoReq[iReadThread].TimeOut := Round(Int(DataStep / ap.KadrRate)) + 1000;
  end;

  // заранее закажем первый асинхронный сбор данных в Buffer
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

  //сбор данных
  if pModule.START_ADC() then
  begin
    while hReadThread <> THANDLE(nil) do
    begin
      RequestNumber := RequestNumber xor $1;
      // сделаем запрос на очередную порции вводимых данных
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
      // попробуем получить текущее состояние процесса сбора данных
      if not pModule.GET_DATA_STATE(@DataState) then
      begin
        ReadThreadErrorNumber := 7;
        break;
      end;
      // теперь можно проверить этот признак переполнения
      // внутреннего буфера модуля
      if (DataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
      begin
        ReadThreadErrorNumber := 8;
        break;
      end;
      //При первом проходе считаем пороговое значение
      if (not data.modC) then
      begin
        data.buffDivide := length(buffer[RequestNumber xor $1]);
        //Высчитываем значения порога для дальнейшего анализа массива.
        data.porog := data.SignalPorogCalk(Round(data.buffDivide/10), buffer,RequestNumber); //!!! Round(data.buffDivide/10)
        //data.modC := true;
      end;

     { for m:=1 to 3000 do
      begin
      form1.Memo1.Lines.Add(inttostr(m)+'  '+intTostr(buffer[RequestNumber xor $1][m]));
      end;



      while (true) do application.processmessages; }



      //проверяем, что сигнал Орбиты подан.
      if data.porog>200 then
      begin
        //Проверяем выбранную информативность
        indJ := 0;
        form2.Hide;
        //M16
        if infNum = 0 then
        begin
          //если не закончена работа с ацп
          if not flagEnd then
          begin
            //переписываем данные в кольц буфер.
            while indJ < data.buffDivide do
            begin
              data.Add(Buffer[RequestNumber xor $1][indJ]);
              inc(indJ);
            end;
            //разбираем М16
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
            //разбираем М8_4_2_1
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
          //остановим работу с АЦП
          pModule.STOP_ADC();
        end;
        //завершим все работающие циклы
        flagEnd:=true;
        wait(100); }

        data.modC := false;
        form2.show;

      end;

      // были ли ошибки или пользователь прервал ввод данных?
      if ReadThreadErrorNumber <> 0 then
      begin
        break;
      end
      else
      begin
        //Sleep(20);
      end;

      // увеличиваем счётчик полученных блоков данных(проходов)
      inc(countC);
      {if countC = 12 then
      begin
        form1.Label2.Caption:=IntToStr(countC);
      end;}

      //сброс счетчика циклов чтения. Для работы вечно=).
      if (countC = 32767) then
      begin
        countC := 0;
      end;
      //form1.Label2.Caption := IntToStr(countC);
    end;
  //закрываем считывание.Перестаем запрашивать данные.
  end
  else
  begin
    ReadThreadErrorNumber := 6;
  end;
  // остановим сбор данных c АЦП
  // !!!ВАЖНО!!! Если необходима достоверная информация о целостности
  // ВСЕХ собраных данных, то функцию STOP_ADC() следует выполнять не позднее,
  // чем через 800 мс после окончания ввода последней порции данных.
  // Для заданной частоты сбора данных в 5 МГц эта величина определяет время
  // переполнения внутренненого FIFO буфера модуля, который имеет размер 8 Мб.
  if not pModule.STOP_ADC() then
  begin
    ReadThreadErrorNumber := 1;
  end;
  acp.ShowThreadErrorMessage();
  // если нужно - анализируем окончательный признак
  //переполнения внутреннего буфера модуля
  if (DataState.BufferOverrun <> (1 shl BUFFER_OVERRUN_E2010)) then
  begin
    // попробуем получить окончательный состояние процесса сбора данных
    if not pModule.GET_DATA_STATE(@DataState) then
    begin
      ReadThreadErrorNumber := 7
    end
    // теперь можно проверить этот признак
    //переполнения внутреннего буфера модуля
    else
    begin
      if (DataState.BufferOverrun = (1 shl BUFFER_OVERRUN_E2010)) then
      begin
        ReadThreadErrorNumber := 8;
      end;
    end
  end;
  // если надо, то прервём все незавершённые асинхронные запросы
  if not CancelIo(ModuleHandle) then
  begin
    ReadThreadErrorNumber := 9;
  end;
  // освободим идентификаторы событий
  CloseHandle(IoReq[0].Overlapped.hEvent);
  CloseHandle(IoReq[1].Overlapped.hEvent);
  // задержечка
  //Sleep(100);
  //после сброса очищаем все графики
  form1.diaSlowAnl.Series[0].Clear;
  form1.gistSlowAnl.Series[0].Clear;
  form1.diaSlowCont.Series[0].Clear;
  form1.fastDia.Series[0].Clear;
  form1.fastGist.Series[0].Clear;
  Form1.tempDia.Series[0].Clear;
  Form1.tempGist.Series[0].Clear;
  //после окончательного сброса делаем доступным прием и чтение.
  form1.startReadACP.Enabled:=true;
  form1.startReadTlmB.Enabled:=true;
  result := 0;
end;
//=============================================================================

//==============================================================================
// Ожидание завершения выполнения очередного запроса на сбор данных
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
        // ошибка ожидания ввода очередной порции данных
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
  //разм. мас АЦП
  DataStep := 1024 * 1024;
  //счетчик проходов АЦП
  countC := 0;
  // Инициализация флага ошибки. ошибок нет 0. сбросим флаги ошибки потока ввода
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
  //Проверка параметров АЦП.
  //============================================================================
  //проверим версию используемой DLL библиотеки
  //процедура получения Dll версии библиотеки для работы с АЦП
  DllVersion := GetDllVersion;

  //Версия DLL не соответствует.
  if DllVersion <> CURRENT_VERSION_LUSBAPI then
  begin
    Str := 'Неверная версия DLL библиотеки Lusbapi.dll! ' + #10#13 +
    '           Текущая: ' + IntToStr(DllVersion shr 16) +
    '.' + IntToStr(DllVersion and $FFFF) + '.' +
    ' Требуется: ' + IntToStr(CURRENT_VERSION_LUSBAPI shr 16) +
    '.' + IntToStr(CURRENT_VERSION_LUSBAPI and $FFFF) + '.';
    //была получена ошибка касаемо версии, вывели её в
    //системную информацию и закончили выполнение проги.
    AbortProgram(Str);
  end;

  //попробуем получить указатель на интерфейс для модуля E20-10
  //Получаем адрес АЦП в системе
  pModule := CreateLInstance(pCHAR('e2010'));

  //устройство не подключено, указатель nil
  if pModule = nil then
  begin
    AbortProgram('Не могу найти интерфейс модуля E20-10!');
  end;

  // попробуем обнаружить модуль E20-10 в
  //первых MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI виртуальных слотах
  {for iGeneralTh := 0 to (MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI - 1) do
    begin
      if pModule.OpenLDevice(iGeneralTh) then
        begin
          AbortProgram('Не могу найти интерфейс модуля E20-10!');
        end;
    end;}

  //проводим поиск e20-10 в нулевом виртуальном слоте
  iGeneralTh := 0;
  if not pModule.OpenLDevice(iGeneralTh) then
  begin
    AbortProgram('Не могу найти интерфейс модуля E20-10!');
  end;

  //определяем скрость работы USB
  if not pModule.GetUsbSpeed(@UsbSpeed) then
  begin
    AbortProgram(' Не могу определить скорость работы шины USB')
  end;

  {// теперь отобразим скорость работы шины USB}
  if UsbSpeed = USB11_LUSBAPI then
  begin
    Str := 'Full-Speed Mode (12 Mbit/s)';
  end
  else
  begin
    //480 МБит/c   . КОД 1
    Str := 'High-Speed Mode (480 Mbit/s)';
  end;



  //iGeneralTh:=0;
  // что-нибудь обнаружили?
  //Определяем определилось ли устройство. Если нет, то выводим ошибку.
  {if iGeneralTh = MAX_VIRTUAL_SLOTS_QUANTITY_LUSBAPI then
  begin
    AbortProgram('Не удалось обнаружить модуль E20-10' +
      'в первых 127 виртуальных слотах!');
  end
  else
  begin
    //не нашли ничего
    //вывод адреса устройства
    //form1.Memo1.Lines.Add(Format('OpenLDevice(%u) --> OK', [iGeneralTh]));
  end; }

  // получим идентификатор устройства
  //ModuleHandle := pModule.GetModuleHandle();

  //прочитаем название модуля в текущем виртуальном слоте
  //присвоение модулю АЦП виртуального названия
  ModuleName := '0123456';
  //ModuleName := 'E20-10';


  //Название записалось и считать получилось его?
  if not pModule.GetModuleName(pCHAR(ModuleName)) then
  begin
    AbortProgram('Не могу прочитать название модуля!')
  end;


  {// проверим, что это модуль E20-10}
  if Boolean(AnsiCompareStr(ModuleName, 'E20-10')) then
  begin
    AbortProgram('Обнаруженный модуль не является E20-10!');
  end;

  // Образ для ПЛИС возьмём из соответствующего ресурса DLL библиотеки Lusbapi.dll
  if not pModule.LOAD_MODULE(nil) then
  begin
    AbortProgram('Не могу загрузить модуль E20-10!');
  end;

  if not pModule.TEST_MODULE() then
  begin
    AbortProgram('Ошибка в загрузке модуля E20-10!');
  end;

  if not pModule.GET_MODULE_DESCRIPTION(@ModuleDescription) then
  begin
    AbortProgram('Не могу получить информацию о модуле!');
  end;

  if not pModule.READ_FLASH_ARRAY(@UserFlash) then
  begin
    AbortProgram('Не могу прочитать пользовательское ППЗУ!');
  end;

  if not pModule.GET_ADC_PARS(@ap) then
  begin
    AbortProgram('Не могу получить текущие параметры ввода данных!');
  end;


  if ModuleDescription.Module.Revision = BYTE(REVISIONS_E2010[REVISION_A_E2010]) then
  begin
    // запретим автоматическую корректировку данных на уровне модуля (для Rev.A)
    ap.IsAdcCorrectionEnabled := FALSE
  end
  else
  begin
    //разрешим автоматическую корректировку
    //данных на уровне модуля (для Rev.B и выше)
    ap.IsAdcCorrectionEnabled := TRUE;
    ap.SynchroPars.StartDelay := 0;
    ap.SynchroPars.StopAfterNKadrs := 0;
    ap.SynchroPars.SynchroAdMode := NO_ANALOG_SYNCHRO_E2010;
    //ap.SynchroPars.SynchroAdMode:=ANALOG_SYNCHRO_ON_HIGH_LEVEL_E2010;
    ap.SynchroPars.SynchroAdChannel := $0;
    ap.SynchroPars.SynchroAdPorog := 0;
    ap.SynchroPars.IsBlockDataMarkerEnabled := $0;
  end;

  // внутренний старт сбора с АЦП
  ap.SynchroPars.StartSource := INT_ADC_START_E2010;

  // внешний старт сбора с АЦП
  // ap.SynchroPars.StartSource := EXT_ADC_START_ON_RISING_EDGE_E2010;

  // внутренние тактовые импульсы АЦП
  ap.SynchroPars.SynhroSource := INT_ADC_CLOCK_E2010;

  // фиксация факта перегрузки входных каналов при помощи
  //маркеров в отсчёте АЦП (только для Rev.A)
  // ap.OverloadMode := MARKER_OVERLOAD_E2010;

  // обычная фиксация факта перегрузки входных каналов
  //путём ограничения отсчёта АЦП (только для Rev.A)
  ap.OverloadMode := CLIPPING_OVERLOAD_E2010;

  // кол-во активных каналов
  ap.ChannelsQuantity := CHANNELSQUANTITY;

  //-
  // если активных каналов больше 1.
  {for iGeneralTh := 0 to (ap.ChannelsQuantity - 1) do
    begin
      ap.ControlTable[iGeneralTh] := iGeneralTh;
    end;}

  //запиcываем номер канала в нулевой элемент контрольного массив
  {if (strtoint(form1.ComboBox1.Text)<>0) then }
    //ap.ControlTable[0]:=1;  //присваиваем номер канала(1)

  //+
  // частоту сбора будем устанавливать в зависимости от скорости USB
  // частота АЦП данных в кГц
  // соответствует константе
  ap.AdcRate := AdcRate;
  // в зависимости от скорости USB выставляем
  //межкадровую задержку и размер запроса.
  if UsbSpeed = USB11_LUSBAPI then
  begin
    // межкадровая задержка в мс.
    //Через какое время время будет приходить ответ с АЦП.
    // 12 Mbit/s
    ap.InterKadrDelay := 0.01;
    DataStep := 256 * 1024; // размер запроса
  end
  else
  begin
    // межкадровая задержка в мс  . 1/131072= 0.00007. 7 микро секунд.
    // 480 Mbit/s
    ap.InterKadrDelay := 0.0;
    DataStep := 1024 * 1024; // размер запроса
  end;

  // конфигурим входные каналы . Настройка 4-х аналоговых каналов.
  {for iGeneralTh := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
    begin
      // входной диапазон 3В
      ap.InputRange[iGeneralTh] := ADC_INPUT_RANGE_3000mV_E2010;
      // источник входа - сигнал
      ap.InputSwitch[iGeneralTh] := ADC_INPUT_SIGNAL_E2010;
    end;}

  iGeneralTh := 0;
  // входной диапазон 3В
  ap.InputRange[iGeneralTh] := ADC_INPUT_RANGE_3000mV_E2010;
  // источник входа - сигнал
  ap.InputSwitch[iGeneralTh] := ADC_INPUT_SIGNAL_E2010;

  // передаём в структуру параметров работы АЦП корректировочные коэффициенты АЦП
  //задаем погрешность и параметры измерения АЦП аналоговых сигналов
  {for iGeneralTh := 0 to (ADC_INPUT_RANGES_QUANTITY_E2010 - 1) do
    begin
      for jGeneralTh := 0 to (ADC_CHANNELS_QUANTITY_E2010 - 1) do
        begin
          // корректировка смещения
          ap.AdcOffsetCoefs[iGeneralTh][jGeneralTh] :=
            ModuleDescription.Adc.OffsetCalibration[jGeneralTh +
              iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
          // корректировка масштаба
          ap.AdcScaleCoefs[iGeneralTh][jGeneralTh] :=
            ModuleDescription.Adc.ScaleCalibration[jGeneralTh +
              iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
        end;
    end;}

  iGeneralTh:=0;
  jGeneralTh:=0;
  // корректировка смещения
  ap.AdcOffsetCoefs[iGeneralTh][jGeneralTh] :=
    ModuleDescription.Adc.OffsetCalibration[jGeneralTh +
      iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];
  // корректировка масштаба
  ap.AdcScaleCoefs[iGeneralTh][jGeneralTh] :=
    ModuleDescription.Adc.ScaleCalibration[jGeneralTh +
      iGeneralTh * ADC_CHANNELS_QUANTITY_E2010];

  // передадим в модуль требуемые параметры по вводу данных
  // записываем параметры ввода в АЦП
  // не удалось записать
  if not pModule.SET_ADC_PARS(@ap) then
  begin
    AbortProgram('Не могу установить параметры ввода данных!');
  end;


  // попробуем выделить нужное кол-во памяти под буфера данных
  for iGeneralTh := 0 to 1 do
  begin
    SetLength(Buffer[iGeneralTh], DataStep);
    ZeroMemory(Buffer[iGeneralTh], DataStep * SizeOf(SHORT));
  end;

  // запустим поток сбора данных
  hReadThread := BeginThread(nil, 0, @Tacp.ReadThread, nil, 0, ReadTid);
  if hReadThread = THANDLE(nil) then
  begin
    AbortProgram('Не могу запустить поток сбора данных!');
  end;
end;
//==============================================================================

//==============================================================================
//Функции по работе с файлом ТЛМ
//==============================================================================

//=============================================================================
//
//=============================================================================

constructor Ttlm.CreateTLM;
begin
  //установим размерность блока в файле тлм в зависимоти от информативности
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

  //по умолчанию пишем в тлм
  tlmBFlag := true;
  //количество блоков за проход
  tlmPlaySpeed := 4;
  //при иниц. записи в файл тлм нет
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
  //зависит от кол. байт переданной переменной
  for j := 1 to SizeOf(nullVal) do
  begin
    SetLength(tlmHeadByteArray, iTlmHeadByteArray + 1);
    tlmHeadByteArray[iTlmHeadByteArray] := nullVal and 255;
    inc(iTlmHeadByteArray);
    //записываем на место младшего байта старший
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
  //зависит от кол. байт переданной переменной
  for j := 1 to SizeOf(multiByteValue) do
  begin
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //записываем на место младшего байта старший
    multiByteValue := multiByteValue shr 8 {(j*8)};
  end;
end;

//for word value

procedure Ttlm.WriteByteToByte(multiByteValue: word);
var
  j: integer;
begin
  //зависит от кол. байт переданной переменной
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //write(PtlmFile,multiByteValue);
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //записываем на место младшего байта старший
    multiByteValue := multiByteValue shr 8 {(j*8)};
  end;
end;

//for byte value

procedure Ttlm.WriteByteToByte(multiByteValue: byte);
var
  j: integer;
begin
  //зависит от кол. байт переданной переменной
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //write(PtlmFile,multiByteValue);
    SetLength(tlmBlockByteArray, iTlmBlockByteArray + 1);
    tlmBlockByteArray[iTlmBlockByteArray] := multiByteValue and 255;
    inc(iTlmBlockByteArray);
    //записываем на место младшего байта старший
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
    //12 разрядное слово Орбиты + бит 1ГЦ+пр КПСЕВ+внутр телеметрия+
    //+пр. начала цикла . M8 65535 байт 32768 слов Орбиты
    if i = 1{0} then
    begin
      //проверяем что это начало цикла и устанавливаем бит начала цикла
      //в 1 слове
     //16 бит в 1. начало цикла
    { data.masCircle[data.reqArrayOfCircle][i]:=
       data.masCircle[data.reqArrayOfCircle][i] or 32768;}
    end;
    if iOneGC = 4 then
    begin
      //13 бит в 1. метка 1 Гц
      masCircle[data.reqArrayOfCircle][i] :=masCircle[data.reqArrayOfCircle][i] or 4096;
      iOneGC := 1;
    end;

    //запись 16 битного значения побайтно с младшего
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
    //12 разрядное слово Орбиты + бит 1ГЦ+пр КПСЕВ+внутр телеметрия+
    //+пр. начала цикла . M8 65535 байт 32768 слов Орбиты
    if i = 1{0} then
    begin
      //проверяем что это начало цикла и устанавливаем бит начала цикла
      //в 1 слове
     //16 бит в 1. начало цикла
      {masCircle[data.reqArrayOfCircle][i] :=     ///!!!!! добавлен коммент
        masCircle[data.reqArrayOfCircle][i] or 32768;}
    end;
    if iOneGC = 4 then
    begin
      //12 бит в 1. метка 1 Гц
      masCircle[data.reqArrayOfCircle][i] :=
        masCircle[data.reqArrayOfCircle][i] or 4096;
      iOneGC := 1;
    end;

    //запись 16 битного значения побайтно с младшего
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
  //счетчик записанных байт заголовка
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

  //открывыем файл на запись блока байт
  AssignFile(PtlmFile, ExtractFileDir(ParamStr(0)) + '/Report/' + fileName);
  //под запись 1 байта, если будет больше запишется больше
  ReWrite(PtlmFile, 1);
  //запишем в файл содержимое дин. буфера элементы*размер одного элемента в байтах
  BlockWrite(PtlmFile, tlmHeadByteArray[0], length(tlmHeadByteArray) * sizeOf(byte)); //!!!
  //записываем количество записанных в файл бaйт
  countWriteByteInFile := length(tlmHeadByteArray);
  closeFile(PtlmFile);

  //нач. иниц. номера запис. блока . с одного
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
    //в случае если файл открыли успешно
    //масштабируем трек бар
    tlm.BeginWork;
    //для завершения проигрывания файла  любой момент
    tlm.fFlag := true;
    //1 нажатие
    form1.startReadTlmB.Enabled := not form1.startReadTlmB.Enabled;
    form1.propB.Enabled := false;
    form1.TrackBar1.Enabled := true;
    //делаем доступным проигрыватель
    form1.PanelPlayer.Enabled := true;
  end
  else
  begin
    showMessage('Не удалось открыть файл!');
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
  //Выведем размер файла в MByte. 1 знак до запятой и 2 после.
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
  //счетчик записанных байт блока
  iTlmBlockByteArray := 0;
  //pref
  //block num (4b)
  WriteByteToByte(blockNumInfile);
  //word in block (4b)
  WriteByteToByte(wordNumInBlock);
  //time in mc (4b)
  timeBlock := (DateTimeToUnix(Time) * 1000) - msStartFile;
  WriteByteToByte(timeBlock);
  {2 раза по 4 байта(8b)}
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
  //если была нажата кнопка окончания записи, то дописываем цикл до конца
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
  //записываем количество запис. байт
  countWriteByteInFile := countWriteByteInFile + length(tlmBlockByteArray);
  //выводим размер записанного файла в байтах
  OutTLMfileSize(countWriteByteInFile, precision);

  tlmBlockByteArray := nil;
  //form1.Memo1.Lines.Add(intToStr(iTlmBlockByteArray));
  iTlmBlockByteArray := 0;

  //для проверки
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
  //счетчик записанных байт блока
  iTlmBlockByteArray := 0;
  //pref
  //block num (4b)
  WriteByteToByte(blockNumInfile);
  //word in block (4b)
  WriteByteToByte(wordNumInBlock);
  //time in mc (4b)
  timeBlock := (DateTimeToUnix(Time) * 1000) - msStartFile;
  WriteByteToByte(timeBlock);
  //2 раза по 4 байта(8b)
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
  //если была нажата кнопка окончания записи, то дописываем цикл до конца
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

  //записываем количество запис. байт
  countWriteByteInFile := countWriteByteInFile + length(tlmBlockByteArray);
  //выводим размер записанного файла в байтах
  OutTLMfileSize(countWriteByteInFile, precision);

  tlmBlockByteArray := nil;
  //form1.Memo1.Lines.Add(intToStr(iTlmBlockByteArray));
  iTlmBlockByteArray := 0;

  //для проверки
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
  //открытие файла на чтение
  stream := TFileStream.Create(form1.OpenDialog1.FileName, fmOpenRead);
  //1 блок М16 131104 байта
  form1.TrackBar1.Max := round((stream.Size - MAXHEADSIZE) / SIZEBLOCK);
  //сдвинемся в файле на размер заголовка
  stream.Seek(MAXHEADSIZE, soFromCurrent);
  //смещаемся от начала блока на размер префикса
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
      //часы
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
      //мин.
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
    //сек
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
  //счетчик перебора блоков(циклов)
  i, jG: integer;
  iMasGroupPars: integer;
  time: cardinal;
  iT: integer;
  str: string;
  arrLength:Integer;
begin
  //form1.Memo1.Lines.Add(intToStr(countBlock));
  i := 1;
  //разбираем и выводим блок за блоком. для каждой информативности свой статический массив
  while i <= countBlock do
  begin
    try
      //счетчик для сбора времени
      iT := 11;
      case infNum of
        //M16
        0:
        begin
          //читаем из файла блок без учета префикса
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
          //сдвигаемся от начала блока на размер префикса
          jG := SIZEBLOCKPREF; {+1} //!!!!!

          arrLength:=length(arr1);
          //разбиваем цикл на группы и выводим погрупно на график
          while jG <=arrLength  - 1 do
          begin
            //собираем массив группы
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //собираем 11 разрядное значение для вывода
              masGroup[iMasGroupPars] := ((arr1[jG + 1] shl 8) +
              arr1[jG]) and 2047;
              //содержит 12 разрядное значение для сбора быстрых каналов
              masGroupAll[iMasGroupPars] := ((arr1[jG + 1] shl 8) +
              arr1[jG]) and 4095;
              jG := jG + 2;
            end;
            //собрали запупустили вывод на диаграммы
            form1.TimerOutToDia.Enabled := true;
            //вывод на графики. Общая процедура.
            data.OutToGistGeneral;
          end;
        end;
        //M08
        1:
        begin
          //читаем из файла блок без учета префикса
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
          //сдвигаемся от начала блока на размер префикса
          jG := SIZEBLOCKPREF; {+1} //!!!!!

          arrLength:=length(arr2);
          //разбиваем цикл на группы и выводим погрупно на график
          while jG <= arrLength - 1 do
          begin
            //собираем массив группы
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //собираем 11 разрядное значение для вывода
              masGroup[iMasGroupPars] := ((arr2[jG + 1] shl 8) +
              arr2[jG]) and 2047;
              //содержит 12 разрядное значение для сбора быстрых каналов
              masGroupAll[iMasGroupPars] := ((arr2[jG + 1] shl 8) +
              arr2[jG]) and 4095;
              jG := jG + 2;
            end;
            //собрали запупустили вывод на диаграммы
            form1.TimerOutToDia.Enabled := true;
            //вывод на графики. Общая процедура.
            data.OutToGistGeneral;
          end;
         end;
        //M04
        2:
        begin
          //читаем из файла блок без учета префикса
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
          //сдвигаемся от начала блока на размер префикса
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr3);
          //разбиваем цикл на группы и выводим погрупно на график
          while jG <= arrLength - 1 do
          begin
            //собираем массив группы
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize  do
            begin
              //собираем 11 разрядное значение для вывода
              masGroup[iMasGroupPars] := ((arr3[jG + 1] shl 8) +
              arr3[jG]) and 2047;
              //содержит 12 разрядное значение для сбора быстрых каналов
              masGroupAll[iMasGroupPars] := ((arr3[jG + 1] shl 8) +
              arr3[jG]) and 4095;
              jG := jG + 2;
            end;
            //собрали запупустили вывод на диаграммы
            form1.TimerOutToDia.Enabled := true;
            //вывод на графики. Общая процедура.
            data.OutToGistGeneral;
          end;
        end;
        //M02
        3:
        begin
          //читаем из файла блок без учета префикса
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
          //сдвигаемся от начала блока на размер префикса
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr4);
          //разбиваем цикл на группы и выводим погрупно на график
          while jG <=arrLength  - 1 do
          begin
            //собираем массив группы
            //CollectOrbGroup;
            for iMasGroupPars := {0}1 to masGroupSize do
            begin
              //собираем 11 разрядное значение для вывода
              masGroup[iMasGroupPars] := ((arr4[jG + 1] shl 8) +
              arr4[jG]) and 2047;
              //содержит 12 разрядное значение для сбора быстрых каналов
              masGroupAll[iMasGroupPars] := ((arr4[jG + 1] shl 8) +
              arr4[jG]) and 4095;
              jG := jG + 2;
            end;
            //собрали запупустили вывод на диаграммы
            form1.TimerOutToDia.Enabled := true;
            //вывод на графики. Общая процедура.
            data.OutToGistGeneral;
          end;
        end;
        //M01
        4:
        begin
          //читаем из файла блок без учета префикса
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
          //сдвигаемся от начала блока на размер префикса
          jG := SIZEBLOCKPREF; {+1} //!!!!!
          arrLength:=length(arr5);
          //разбиваем цикл на группы и выводим погрупно на график
          while jG <=arrLength - 1 do
          begin
            //собираем массив группы
            //CollectOrbGroup;
            for iMasGroupPars := 1{0} to masGroupSize do
            begin
              //собираем 11 разрядное значение для вывода
              masGroup[iMasGroupPars] := ((arr5[jG + 1] shl 8) +
              arr5[jG]) and 2047;
              //содержит 12 разрядное значение для сбора быстрых каналов
              masGroupAll[iMasGroupPars] := ((arr5[jG + 1] shl 8) +
              arr5[jG]) and 4095;
              jG := jG + 2;
            end;
            //собрали запупустили вывод на диаграммы
            form1.TimerOutToDia.Enabled := true;
            //вывод на графики. Общая процедура.
            data.OutToGistGeneral;
          end;
        end;
      end;
      form1.TrackBar1.Position := form1.TrackBar1.Position +form1.TrackBar1.PageSize;
    finally
      //проверяем каждый раз дошли ли до конца файла.
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
  //проиниц. счетчики для подсч. колич. каждого типа адресов
  //ам
  acumAnalog := 0;
  //темп
  acumTemp:=0;
  //ак
  acumContact := 0;
  //б
  acumFast := 0;
  //бус
  acumBus := 0;
  //перезагрузим акт. адреса.
  form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
  //Получение правильного списка адресов
  GetAddrList;
  //Установка списка правильных адресов
  SetOrbAddr; 
  //отключение масштабирования
  form1.gistSlowAnl.AllowZoom:=false;
  form1.gistSlowAnl.AllowPanning:=pmNone;

  form1.fastGist.AllowZoom:=false;
  form1.fastGist.AllowPanning:=pmNone;

  form1.tempGist.AllowZoom:=False;
  form1.tempGist.AllowPanning:=pmNone;
  //проверим правильность адресов
  if (data.GenTestAdrCorrect) then
  begin
    //объект для работы с ТЛМ
    tlm := Ttlm.CreateTLM;
    //положение ползунка скорости
    form1.tlmPSpeed.Position := 3;
    form1.tlmPSpeed.Enabled:=true;
    if form1.startReadACP.Caption = 'Прием' then
    //старт
    begin
      //AssignFile(textTestFile,'TextTestFile.txt');
      //Rewrite(textTestFile);
      //AssignFile(swtFile,ExtractFileDir(ParamStr(0)) + '/Report/' + '777.txt');
      //ReWrite(swtFile);
      //проиниц. флаг выхода из всех циклов
      flagEnd:=false;
      //заполнение массива параметров
      data.FillAdressParam;
      form1.startReadACP.Caption := 'Стоп';
      //режим работы приема
      form1.tlmWriteB.Enabled := true;
      form1.startReadTlmB.Enabled:=false;
      form1.propB.Enabled:=false;

      //Подготовка АЦП к работе
      if  (not boolFlg) then
      begin
        acp := Tacp.InitApc;
        //подготовимся к работе с АЦП
        acp.CreateApc;
        //включаем сбор данных с АЦП
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
    //стоп
    begin

      //closeFile(swtFile);
      {form1.startReadACP.Caption := 'Прием';
      form1.startReadACP.Enabled:=false;
      form1.tlmWriteB.Enabled := false;
      form1.propB.Enabled:=true;
      //flagEnd:=true;
      // wait(50);
      //подготовка к работе с 0
      //data.Free;
      //data := Tdata.CreateData;
      pModule.STOP_ADC();
      //flagEnd:=true;
      //wait(50);
      WaitForSingleObject(hReadThread,1500);
      //Если поток создан , то завершение потока
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
        //остановим работу с АЦП
        pModule.STOP_ADC();
      end;
      //завершим все работающие циклы
      flagEnd:=true;
      wait(20);
      //while (True) do Application.ProcessMessages; //!!!!
      WinExec(PChar('OrbitaMAll.exe'), SW_ShowNormal);
      wait(20);
      //завершим приложение по человечески.
      Application.Terminate;
    end;
  end
  else
  begin
    ShowMessage('Проверьте правильность адресов!');
  end;
end;

//закрытие программы и следовательно должны закрываться
//все открытые потоки если они в работе.

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //если закрытие приложения при приеме то остановим работу с АЦП. перед закрытием.
  if ((form1.tlmWriteB.Enabled)and(not form1.startReadTlmB.Enabled)and
      (not form1.propB.Enabled))  then
  begin
    //остановим работу с АЦП
    pModule.STOP_ADC();
  end;

  //завершим все работающие циклы
  flagEnd:=true;
  wait(20);
  //завершим приложение по человечески.
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
  //объект для работы с сигналом
  data := tdata.CreateData;
  //настройка графиков
  form1.diaSlowAnl.LeftAxis.Maximum := 1025.0;
  form1.gistSlowAnl.BottomAxis.Maximum := 300;
  form1.gistSlowAnl.BottomAxis.Minimum := 0;
  form1.gistSlowAnl.LeftAxis.Maximum := 1025;
  form1.gistSlowAnl.LeftAxis.Minimum := 0;
  path:=ExtractFileDir(ParamStr(0))+'\ConfigDir\property.ini';
  propIniFile:=TIniFile.Create(path);
  //читаем из файла содержимое строки параметра path.
  propStrPath:=propIniFile.ReadString('lastPropFile','path','');
  //проверяем есть ли такой файл настроек на ПК.
  if FileExists(propStrPath) then
  begin
    //есть, но это первый запуск ПО
    if propStrPath='' then
    begin
      //доступность начальных инструментов
      //адр. Орб.
      form1.propB.Enabled := true;
      //прием
      form1.startReadACP.Enabled := false;
      //чтение
      form1.startReadTlmB.Enabled := false;
      //запись в tlm
      form1.tlmWriteB.Enabled := false;
      //панель чтения
      form1.PanelPlayer.Enabled := false;
      //ползунок положения в файле
      form1.TrackBar1.Enabled := false;
      //ползунок скорости
      form1.tlmPSpeed.Enabled:=false;
      //сохранение в файл адресов
      form1.saveAdrB.Enabled:=false;
    end
    else
    //есть.
    begin
      form1.propB.Enabled := true;
      form1.startReadACP.Enabled := true;
      form1.startReadTlmB.Enabled := true;
      form1.tlmWriteB.Enabled := false;
      form1.PanelPlayer.Enabled := false;
      form1.TrackBar1.Enabled := false;
      form1.tlmPSpeed.Enabled:=false;
      form1.saveAdrB.Enabled:=true;
      //загрузка файла адресов в рабочий список адресов
      form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
      //Получение правильного списка адресов
      GetAddrList;
      //Установка списка правильных адресов
      SetOrbAddr;
    end;
  end
  else
  //такого файла нет. Перезапишем его.
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
  //закрытли файл настроек
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
  //избегаем доступа к мемо. и в случае доступности
  //мемо делаем его недоступным и наоборот
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
  //осуществление разбора очередной строки адреса.
  orbAdrCount := 0;
  //счетчик для подсчета количества аналоговых каналов
  data.analogAdrCount := 0;
  //счетчик для подсчета количества контактных каналов
  data.contactAdrCount := 0;
  //счетчик для подсчета количества аналоговых каналов
  data.tempAdrCount := 0;
  //отчистка формы для предидущей группы
  form1.diaSlowAnl.Series[0].Clear;
  form1.diaSlowCont.Series[0].Clear;
  form1.fastDia.Series[0].Clear;
  form1.tempDia.Series[0].Clear;
  //sleep(3);
  //последовательно разбираем строка за строкой адреса
  //Орбиты, вынимаем нужные значения и выводим на график
  while orbAdrCount <= iCountMax - 1 do // iCountMax-1
  begin
    data.OutToDia(masElemParam[orbAdrCount].numOutElemG,
      masElemParam[orbAdrCount].stepOutG, {length(masGroup)}masGroupSize, //Остановка11
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
//Объектные функции
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
  //флаг для поиска маркера для зап. массива БУС
  flagWtoBusArray:=false;
  //флаг для вывода на гистограмму аналоговых и контактных (медленных каналов)
  graphFlagSlowP := false;
  graphFlagBusP := false;
  graphFlagTempP := false;

  //если больше одной вкладки на странице то одной переменной мало
  numP := 0;
  numPfast := {0}1;
  porog := 0;
  //нач. иниц. флага подсчета порога
  modC := false;

  //переменная размерности буфера.
  buffDivide := 0;
  //счетчик чтения из fifo битов
  fifoLevelRead := 1;
  //счетчик для записи в массив fifo битов
  fifoLevelWrite := 1;
  //счетчик количества обработанных точек
  fifoBufCount := 0;

  //счетчики для подсчета количества точек выше и ниже полога
  numRetimePointUp := 0;
  numRetimePointDown := 0;

  //нач. иниц счетчика для заполнения массива группы
  iMasGroup := {0}1;
  bufMarkGroup := 0;
  bufNumGroup:=0;
  flfl := false;
  bufMarkCircle := 0;
  flagCountGroup := false;
  fraseCount := 1;
  groupCount := 1;
  fraseMarkFl := false;
  //нач. иниц флага быстрого поиска
  qSearchFl := false;
  iMasCircle := {0}1;

  //переменная флаг для поиска первой фразы
  firstFraseFl := false;

  //счетчик битов для отсчета размерности слов
  iBit := 1;
  //иниц. размерности слова
  bitSizeWord := 12;
  //счетчик слов, нумерация будет происходить с 1. Слова с 1 по 16.
  wordNum := 1;
  //строка для сбора слова.
  //codStr:='';
  codStr := 0;
  //начальная инициализация флага вывода номера группы
  flagOutFraseNum := false;
  //счетчик фраз ,нумерация будет происходить с 1. Фразы с 1 по 128.
  myFraseNum := 1;
  //нумерация маркеров номеров группы
  nMarkerNumGroup := 1;
  //начальная иниц. маркера группы
  markerGroup := 0;
  //начальная иниц. маркера номера группы
  markerNumGroup := 0;
  //начальная иниц. переменных для разбора сигнала Орбиты М16
  flagL := true;
  startWriteMasGroup := false;
  //флаг для синхронизации заполнения массива цикла с 1 слова первого цикла
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
  //выше
  if signalElemValue >= porog then
  begin
    //счетчик выше
    inc(numRetimePointUp);
    //анализируем счетчик точек ниже порога
    outStep := round(numRetimePointDown / (10 / 3.145728));
    //если шаг получается нулевым, то 1
    if ((numRetimePointUp = 1)and(outStep = 0)) then
    begin
      outStep := 1;
    end;

    for iOutInFile := 1 to outStep do
    begin
      fifoMas[fifoLevelWrite] := 0;
      inc(fifoLevelWrite);
      //сколько значений лежит в массиве
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
    //счетчик ниже
    inc(numRetimePointDown);
    //анализируем счетчик точек выше порога
    outStep := round(numRetimePointUp / (10 / 3.145728));
    if ((numRetimePointDown = 1)and(outStep = 0)) then
    begin
      outStep := 1;
    end;
    for iOutInFile := 1 to outStep do
    begin
      fifoMas[fifoLevelWrite] := 1;
      inc(fifoLevelWrite);
      //сколько значений лежит в массиве
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
    //заказываем память под 1 элемент
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
  //читаем значение текущей точки в кольцевом буфере
  current := Read;
  Inc(countForMF);
  //ищем первую нечетную фразу.
  //через 24 т.к анализируем первые биты нечетных слов начиная с нечетной фразы и заканчивая четной
  if ((current = 0) and (Read(24) = 1) and (Read(48) = 1) and
      (Read(72) = 1) and (Read(96) = 1) and (Read(120) = 0) and
      (Read(144) = 0) and (Read(168) = 0) and (Read(216) = 1) and
      (Read(240) = 0) and (Read(264) = 0) and (Read(288) = 1) and
      (Read(312) = 1) and (Read(336) = 0) and (Read(360) = 1)) then
  begin
    //нашли маркер первой нечетной фразы и в дальнейшем будем его проверять
    firstFraseFl := true;
    //счетчик количества (битов слова орбиты)точек через который маркер фразы должен повториться
    pointCount := 383;
    //сдвигаемся на прошлую точку
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
  //вывод на график для контактных и аналоговых
  if (graphFlagSlowP) then
  begin
    OutToGistSlowAnl(masElemParam[chanelIndexSlow].numOutElemG,
      masElemParam[chanelIndexSlow].stepOutG,
      {length(masGroup)}masGroupSize, data.numP);
  end;

  //вывод на график темпер. параметров
  if (graphFlagTempP) then
  begin
    OutToGistTemp(masElemParam[chanelIndexTemp].numOutElemG,
      masElemParam[chanelIndexTemp].stepOutG,
      {length(masGroup)}masGroupSize, data.numP);
  end;

  //вывод на диаграмму для быстрых параметров
  if (graphFlagFastP)and(testOutFalg) then
  begin
    OutToGistFastParam(masElemParam[chanelIndexFast].numOutElemG,
      masElemParam[chanelIndexFast].stepOutG, {length(masGroup)}masGroupSize,
      masElemParam[chanelIndexFast].adressType, data.numPfast,
      masElemParam[chanelIndexFast].bitNumber);
  end;




  // вывод на диаграмму для БУС
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
  //берем младшие 11 разрядов. старший отбрасываем. МЧ-младший бит.
  wordInfo := (codStr and 2047) {shr 1};
  //12 битов
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
  //Заполнили 65535 элементов
  if imasCircle = {length(masCircle[reqArrayOfCircle])}masCircleSize+1 then
  begin
    imasCircle := 1;
    //массив цикла заполнен. пишем в файл ТЛМ
    //если запис в тлм активна то пишем блок(цикл Орбиты в него)
    if (tlm.flagWriteTLM) then
    begin
      if infNum = 0 then
      begin
        //M16
        tlm.WriteTLMBlockM16(tlm.msTime);
      end
      else
      begin
        //другие информативности
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
    //проверяем 12 бит, если там 1
    //то в конец маркера запишем 1
    if ((codStr and 2048) = 2048) then
    begin
      markerNumGroup := (markerNumGroup shl 1) or 1;
    end
    else
      //0 в конец маркера запишем 0
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
  //проверяем 12 бит, если там 1 то в конец маркера запишем 1
  if ((codStr and 2048) = 2048) then
  begin
    markerGroup := (markerGroup shl 1) or 1;
  end
  else
  begin
    //0 в конец маркера запишем 0
    markerGroup := markerGroup shl 1;
  end;
end;
//==============================================================================

//==============================================================================
//Сбор 32-х разрядных слов и выводим в файл
//==============================================================================
procedure FillSwatWord;
var
  iOrbWord:integer;
  wordToFile:integer;
begin
  iOrbWord:=1;
  wordToFile:=0;
  //сбор слов вариант 2
  while iOrbWord<={length(masGroup)}masGroupSize do
  begin
     //проверяем 11 бит, холостое слово или нет
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //нашли начало слова
      //взяли 10 мл. битов
      wordToFile:=masGroup[iOrbWord] and 1023; //П1А12
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+1] shl 10)+wordToFile;//П2А12
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+2] shl 11)+wordToFile;//П1А22
      //writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+4;
  end;
  //разбор 1 потока массива группы   1024 слова Орбиты
  {while iOrbWord<=length(masGroup)-1 do
  begin
    //проверяем 11 бит, холостое слово или нет
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //нашли начало слова
      //взяли 10 мл. битов
      wordToFile:=masGroup[iOrbWord] and 1023;
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+2] shl 10)+wordToFile;
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+4] shl 11)+wordToFile;
      writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+5;
  end;

  iOrbWord:=1;
  //разбор 2 потока массива группы   512 слов Орбиты
  while iOrbWord<=round(length(masGroup)/2)-1 do
  begin
    //проверяем 11 бит, холостое слово или нет
    if (masGroup[iOrbWord] and 1024)=1024 then
    begin
      //взяли 10 мл. битов
      wordToFile:=masGroup[iOrbWord] and 1023;
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+2] shl 10)+wordToFile;
      //след. 11 ст. битов
      wordToFile:=(masGroup[iOrbWord+4] shl 11)+wordToFile;
      writeln(swtFile,intToStr(wordToFile));
    end;
    iOrbWord:=iOrbWord+5;
  end;}
end;
//==============================================================================

//==============================================================================
//Заполнение бита Орб. слова в слово Орбиты
//==============================================================================
procedure TData.FillBitInWord;
begin
  //считываем значение из кольц. буфера согласно счетчику чтения
  current := Read;
  //строка в которую собираем 12 разрядное слово
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
  //сбор слов для Свята //!!!!!
  //FillSwatWord;
  //включаем таймер для вывода на диаграммы
  form1.TimerOutToDia.Enabled := true;
  //вывод на графики. Общая процедура.
  OutToGistGeneral;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TData.AnalyseFrase;
begin
  //для вывода в тлм. Для записи с первого цикла
  if (flBeg) then
  begin
    flSinxC := true;
  end;
  //цикл разбора данных по 12 бит
  while iBit <= bitSizeWord do
  begin
    {счетчик для подсчета точек по 383. Для быстрого поиска маркера фразы}
    if pointCount = -1 then
    begin
      //сброс флага найденности маркера
      firstFraseFl := false;
      break;
    end;
    dec(pointCount);

    FillBitInWord;

    if iBit = bitSizeWord then
    begin
      //если номер слова 1 значит это новая фраза
      if wordNum = 1 then
      begin
        //form1.Memo1.Lines.Add('Фраза №'+IntToStr(fraseNum));
        //проверяем что до этого нашли 128 фразу.
        if (flagOutFraseNum) then
        begin
          {if fraseNum=126 then
           begin
            SaveBitToLog('Фраза 126:'+codStr);
           end;}
          //SaveBitToLog('Фраза №'+IntToStr(fraseNum)+' ');
          if fraseNum = 1 then
          begin
            //нумеруем с 0 т.к массив группы с 0
            groupWordCount := {0}1;
            //разрешаем запись в массив группы
            startWriteMasGroup := true;
          end;
        end;
        //-----------------------
        //поиск маркера фразы
        //-----------------------
        //смотрим четную фразу
        if (myFraseNum mod 2 = 0) then
        begin
          //сбор маркера номера группы
          CollectMarkNumGroup;
          //сбор маркера группы
          CollectMarkGroup;

          Inc(countEvenFraseMGToMG);
          
          //проверяем не собрали ли маркера группы или маркер цикла
          if ((markerGroup = 114{112}) or (markerGroup = 141)) then
          //нашли маркер
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
              //нашли маркер группы
              begin
                //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' МГ'); //TO-DO <><><>
                Inc(countForMG);
                //+1 МГ
                if countEvenFraseMGToMG<>64 then
                begin
                  //сбой по МГ есть
                  Inc(countErrorMG);
                end;

                if countForMG={100}31 then
                begin
                  //выводим число сбоев по МГ
                  OutMG(countErrorMG);
                  countErrorMG:=0;
                  countForMG:=0;
                end;

                countEvenFraseMGToMG:=0;
                //счетчику cлов в группе начало массива
                //data.groupWordCount:=0;
                //разрешаем запись в массив группы
                //data.startWriteMasGroup:=true;
              end;
              //----------------------------
              //цикл
              //----------------------------
              if data.markerGroup = 141 then
              //нашли маркер цикла
              begin
                //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' МЦ');
                countEvenFraseMGToMG:=0;
                //SaveBitToLog('Номер группы '+'32');
                flBeg := false;
                if (tlm.flagWriteTLM) then
                begin
                  flBeg := true;
                end;
              end;
              //----------------------------
              data.markerGroup := 0;
              //выставление флага вывода номера группы
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
        //проверяем нумерацию фраз,
        //для того чтобы не выйти за границы.
        //Моя внутреняя нумерация.
        if data.myFraseNum = 129 then
        begin
          data.myFraseNum := 1;
        end;
        inc(data.fraseNum);
        //проверяем нумерацию фраз,
        //для того чтобы не выйти за границы.
        //Нумерация для вывода.
        if data.fraseNum = 129 then
        begin
          data.fraseNum := 1;
        end;
      end;

      // к моменту когда проанализировали 12 бит,
      // мы уже собрали значение слова
      //вывод номера слова и собранного значения
      //SaveBitToLog('Cловo №'+IntToStr(wordNum)+
      //' Значение слова:'+IntToStr(codStr));
      if (startWriteMasGroup) then
      begin
        FillArrayGroup;
        //если включена синх. с началом цикла Орбиты
        if (flSinxC) then
        begin
          FillArrayCircle;
        end;
        //проверяем не заполнен ли массив группы
        // орбитовские слова с 0 по 2047. счетчик 2048
        if groupWordCount = {length(masGroup)}masGroupSize+1 then
        begin
          OutDate;
        end;
      end;
      codStr := 0;
      inc(wordNum);
      //проверка нумерации слов, для того чтобы
      //не выйти за границы нумерации слов
      if wordNum = 17 then
      begin
        wordNum := 1;
      end;
    end;

    //в случаем принуд. оконч. работы с АЦП выйти из выполнения
    if flagEnd then
    begin
      form1.TimerOutToDia.Enabled := false;
      data.graphFlagSlowP := false;

      data.graphFlagFastP:= false;
      data.graphFlagTempP:= false;
      break;
    end;
    //увелич. счетчик битов соб. слова Орбиты
    inc(iBit);
    if iBit = 13 then
    begin
      iBit := 1;
    end;
  end;
end;

//==============================================================================

//==============================================================================
//Сбор быстрого значения T22
//на вход приходит 12 разрядное значение
//==============================================================================

function Tdata.BuildFastValueT22(value: integer; fastWordNum: integer): integer;
var
  //буфер быстрых
  fastValBuf: word;
begin
  fastValBuf := 0;
  //собираем первое слово быстрых
  if fastWordNum = 1 then
  begin
    //отбросили 12 бит. сделали 17
    {fastValBuf:=value shl 5;
    //отбросили 6 младш. битов. 11 бит инф. стал 5. 5 старших битов
    fastValBuf:=fastValBuf shr 11;}
    //1
    if (value and 1024 = 1024) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
    //2
    if (value and 512 = 512) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
    //3
    if (value and 256 = 256) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
    //4
    if (value and 128 = 128) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
    //5
    if (value and 64 = 64) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
    //6 бит
    if (value and 4 = 4) then
    begin
      //записали в младший разряд буфера 1
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      //записали в младший разряд буфера 0
      fastValBuf := fastValBuf shl 1;
    end;
  end;
  if fastWordNum = 2 then
  begin
    //отбрасываем 6 старших битов
    fastValBuf := value shl 10; //6 в 16
    //отбрасываем 9 младших битов. 3 старших бита.
    fastValBuf := fastValBuf shr 13;
    //4 бит
    if (value and 2 = 2) then
    begin
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      fastValBuf := fastValBuf shl 1;
    end;
    //5 бит
    if (value and 1 = 1) then
    begin
      fastValBuf := (fastValBuf shl 1) or 1;
    end
    else
    begin
      fastValBuf := fastValBuf shl 1;
    end;
    //6 бит
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
//Сбор быстрого значения T22
//на вход приходит 12 разрядное значение
//==============================================================================
function Tdata.BuildFastValueT24(value: integer; fastWordNum: integer): integer;
var
  //буфер быстрых. собираем 6 разрядное значение
  fastValBuf: byte;
begin
  fastValBuf := 0;
  //собираем первое слово быстрых. младшие 6 бит
  if fastWordNum = 1 then
  begin
    fastValBuf:=value and 63;
  end;
  //собираем второе слово быстрых. старшие 6 бит
  if fastWordNum = 2 then
  begin
    fastValBuf:=value and 4032;
  end;
  result := fastValBuf;
end;
//==============================================================================


//==============================================================================
//Сбор значения БУС
//на вход приходит два 12 разрядных значений
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
  //в обоих переданных словах отбрасываем 12,3,2 и 1 бит.
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
  //вывод для БУС параметров
  if form1.PageControl1.ActivePageIndex = 2 then
  begin
    orbAdrCount:=0;
    while orbAdrCount <= iCountMax - 1 do // iCountMax-1
    begin
      if masElemParam[orbAdrCount].adressType = 6 then
      begin
        iParity:=0;
        //вычисляем количество точек в пришедшем адресе
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
            //запоминаем значение слова Орбиты со старшим байтом слова БУС
            highVal:=masGroupAll[nPoint];
            //form1.Memo1.Lines.Add(intToStr(masGroupAll[nPoint])
            // +' '+intToStr(nPoint));
          end
          else
          begin
            //запоминаем значение слова Орбиты с младшим байтом слова БУС
            lowerVal:=masGroupAll[nPoint];
            //form1.Memo1.Lines.Add(intToStr(masGroupAll[nPoint])
            //+' '+intToStr(nPoint));
            //ищем маркер (последовательность из 65535,65535,65535)
            if  ((BuildBusValue(highVal,lowerVal)=65535)and   //!!77
              (not flagWtoBusArray))  then
            begin
              busArray[iBusArray]:=BuildBusValue(highVal,lowerVal);
              inc(iBusArray);
              if iBusArray=3 then
              begin
                //заполнили 3 значения
                if ((busArray[iBusArray-1]=65535)and(busArray[iBusArray-2]=65535)and
                (busArray[iBusArray-3]=65535)) then
                begin
                  //нашли теперь, можем заполнять массив
                  flagWtoBusArray:=true;
                end
                else
                begin
                  //не нашли, ищем и записываем все заново
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
              //маркер до этого нашли. заполняем массив
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
//Вывод на гистограмму
//=============================================================================

procedure TData.OutToDia(firstPointValue: integer;outStep: integer;
  masOutSize: integer; var numChanel: integer;typeOfAddres: short;
  numBitOfValue: short; busTh: short; busAdr: short;var numOutPoint: short);
var
  nPoint: integer;
  //аккумулятор для быстрых значений T22
  fastValT22: integer;
  //аккумулятор для быстрых значений T21
  fastValT21: integer;
  //аккумулятор для быстрых значений T24
  fastValT24: integer;
  //переменная для вычисления количества
  //точек для каждого нового приходящего адреса
  //переменная вспомогательная и нужна для организации
  //цикличности вывода точек по одной
  maxPointInAdr: integer;
  //переменная для вычисления смещения для аналоговых каналов
  offsetForYalkAnalog: short;
  offsetForYalkTemp: short;
  offsetForYalkContact: short;
  offsetForYalkFastParamT22: short;
  offsetForYalkFastParamT21: short;
  offsetForYalkFastParamT24: short;
begin
  //вычисляем количество точек в пришедшем адресе
  maxPointInAdr := 0;
  nPoint := firstPointValue;
  while nPoint <= masOutSize do
  begin
    inc(maxPointInAdr);
    nPoint := nPoint + outStep;
  end;

  //вывод производится только если вкладка аналоговых и контактных каналов активна
  if form1.PageControl1.ActivePageIndex = 0 then
  begin

    //вывод для аналоговых каналов   0
    if typeOfAddres = 0 then
    begin
      //вывод первой точки в массиве firstPointValue для текущего адреса
      //необходимо учитывать смещение для отображения за 1 проход адреса 1 точки
      //вычисление смещения, для каждого типа адреса будет свое смещение
      offsetForYalkAnalog := outStep * (numOutPoint - 1);
      //вычисление номера текущей выводимой точки
      nPoint := firstPointValue + offsetForYalkAnalog;
      //так как массив группы с 0
      nPoint := nPoint{ - 1};
      //вывод на диа
      form1.diaSlowAnl.Series[0].AddXY(numChanel, masGroup[nPoint] shr 1);
      //увеличение счетчика выводимой точки адреса
      inc(numOutPoint);
      //проверяем не вышли ли мы за максимальный диапазон для текущего адреса
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //счетчик подсчета количества аналоговых адресов
      inc(analogAdrCount);
    end;

    //вывод для контактных каналов     1
    if typeOfAddres = 1 then
    begin
      offsetForYalkContact := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkContact;
      //так как массив группы с 0
      nPoint := nPoint {- 1};
      contVal := OutputValueForBit(masGroup[nPoint], numBitOfValue);
      form1.diaSlowCont.Series[0].AddXY(numChanel - analogAdrCount, contVal);
      inc(numOutPoint);
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //счетчик подсчета количества контактных адресов
      inc(contactAdrCount);
      //SaveBitToLog(IntToStr(numChanel-20));
      //if numChanel-20=8 then form1.gistCont.Series[0].Clear;
    end;
  end;

  //вывод для быстрых параметров
  if form1.PageControl1.ActivePageIndex = 1 then
  begin

    //вывод для быстрых параметров   T22
    if typeOfAddres = 2 then
    begin
      //вычисление смещения для вынимания каждый раз следующей
      //точки для данного анализируемого адреса
      //смещение в записи этого адреса будет запоминатся
      offsetForYalkFastParamT22 := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkFastParamT22;
      //так как массив группы с 0
      nPoint := nPoint{ - 1};
      //собираем и выводим первое слово T22
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

    //вывод для быстрых параметров   T21
    if typeOfAddres = 3 then
    begin
      //вычисление смещения для вынимания каждый раз следующей
      //точки для данного анализируемого адреса
      //смещение в записи этого адреса будет запоминатся
      offsetForYalkFastParamT21 := outStep * (numOutPoint - 1);
      nPoint := firstPointValue + offsetForYalkFastParamT21;
      //так как массив группы с 0
      nPoint := nPoint {- 1};
      fastValT21 := masGroup[nPoint] shr 3; //8 разрядов
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

    //вывод для быстрых параметров   T24
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

  //вывод для БУС
  if form1.PageControl1.ActivePageIndex = 2 then
  begin
  end;


  //вывод для температурных параметров
  if form1.PageControl1.ActivePageIndex = 3 then
  begin
    //вывод для температурных каналов   7
    if typeOfAddres = 7 then
    begin
      //вывод первой точки в массиве firstPointValue для текущего адреса
      //необходимо учитывать смещение для отображения за 1 проход адреса 1 точки
      //вычисление смещения, для каждого типа адреса будет свое смещение
      offsetForYalkTemp := outStep * (numOutPoint - 1);
      //вычисление номера текущей выводимой точки
      nPoint := firstPointValue + offsetForYalkTemp;
      //так как массив группы с 0
      nPoint := nPoint{ - 1};
      //вывод на диа
      form1.tempDia.Series[0].AddXY(numChanel, masGroup[nPoint] shr 1);
      //увеличение счетчика выводимой точки адреса
      inc(numOutPoint);
      //проверяем не вышли ли мы за максимальный диапазон для текущего адреса
      if numOutPoint > maxPointInAdr then
      begin
        numOutPoint := 1;
      end;
      //счетчик подсчета количества аналоговых адресов
      inc(tempAdrCount);
    end;
  end;
end;

//==============================================================================
//Вывод на гистограмму аналоговых медленных
//==============================================================================

procedure TData.OutToGistSlowAnl(firstPointValue: integer; outStep: integer;
  masOutSize: integer; var numP: integer);
var
  iPoint: integer;
begin
  //выводим на гист когда активна вкладка аналог. медл.
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
//Вывод на гистограмму температурных
//==============================================================================

procedure TData.OutToGistTemp(firstPointValue: integer; outStep: integer;
  masOutSize: integer; var numP: integer);
var
  iPoint: integer;
begin
  //выводим на гист когда активна вкладка аналог. медл.
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
//Вывод на гистограмму быстрых параметров
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
            //ShowMessage('ошибка');
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
//Вывод на гистограмму параметров БУС
//==============================================================================
procedure TData.OutToGistBusParam(firstPointValue: integer;outStep: integer;
masOutSize: integer; adrtype: short;var numPfast: integer; numBitOfValue: integer);
var
  iPoint: integer;
  busArrLen:integer;
begin
  //выводим на гист когда активна вкладка аналог. медл.
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
//Процедура ведения отчета о проверке
//==============================================================================

{procedure Tdata.SaveReport;
var
  str: string;
  i: integer;
begin
  //если у нас автоматическая проверка, то
  if (ParamStr(1) = 'StartAutoTest') then
  begin
    //проверяем был ли передан параметр2.
    //Если нет то генерируем обычный внутренний отчет
    if (ParamStr(2) = '') then
      //нет
    begin
      str := 'Тест_ЯЛК_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.txt';
      for i := 1 to length(str) do
        if (str[i] = ':') then
          str[i] := '.';
      form1.Memo1.Lines.SaveToFile(ExtractFileDir(ParamStr(0)) + '/Report/' + str);
    end
    else
      //да
    begin
      //связываем ф.п с переданным файлом
      AssignFile(ReportFile, ParamStr(2));
      //проверяем есть ли такой файл
      if (FileExists(ParamStr(2))) then
        //есть, открываем файл на дозапись
      begin
        Append(ReportFile);
      end
      else
        //нет
      begin
        //открываем на запись
        ReWrite(ReportFile);
      end;
      writeln(ReportFile, form1.Memo1.Text);
      closefile(ReportFile);
    end
  end
  else
    //ручная проверка. внутренний отчет
  begin
    str := 'Тест_ЯЛК_' + DateToStr(Date) + '_' + TimeToStr(Time) + '.txt';
    for i := 1 to length(str) do
      if (str[i] = ':') then
        str[i] := '.';
    form1.Memo1.Lines.SaveToFile(ExtractFileDir(ParamStr(0)) + '/Report/' + str);
  end;
end;}
//==============================================================================

//==============================================================================
//Функция для получения значения бита по номеру бита и непосредственному значению
//==============================================================================

function Tdata.OutputValueForBit(value: integer; bitNum: integer): short;
var
  sdvig: integer;
begin
  //сдвигаем на 1 бит вправо, так как сюда
  //приходит значение не сдвинутое на него для прав значения
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
    //9 и 10. для типа T05 из 10 бит
    9:
    begin
      sdvig := 1;
    end;
    10:
    begin
      sdvig := 0;
    end;
  end;
  //проверяем установлен ли бит номер которого был передан
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
//Процедура для работы с системным файлом . В него пишем признак проверки
//==============================================================================

procedure Tdata.WriteSystemInfo(value: string);
begin
  //связ. файла System с файловой переменной
  AssignFile(SystemFile, 'System');
  //открытие его  на запись
  ReWrite(SystemFile);
  //запись в файл переданного значения
  writeln(SystemFile, value);
  //закрытие файла
  closefile(SystemFile);
end;
//==============================================================================

//==============================================================================
//Функция вычисления среднего значения.
//Возвращает среднее значение в целочисленном формате
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
//Разбор адресов ОрбитыM16
//==============================================================================
procedure TData.AdressAnalyser(adressString: string; var imasElemParam: integer);
var
  //Объявление для графиков
  iGraph: integer;
  flagM: boolean;
  //переменная для хранения ASCII-кода символа
  codAsciiGraph: integer;
  stepKoef: integer;
  //Множители для вычисления координат
  Ma, Mb, Mc, Md, Me, Mx: integer; //Ma=N1-1;Mb=N2-1;Mc=N3-1; и т.д
  //фазы для вычисления адреса
  //Fa=8, если K=0; Fa=4, если K=1; Fa=2, если K=2; аналогично для других
  Fa, Fb, Fc, Fd, Fe, Fx: integer;
  //начально смещ. в массиве, зависит от П1 или П2
  pBeginOffset: integer;
  flagBegin: boolean;
  stepOutGins: integer;
  offset: integer;

  //информативность адреса в виде целого числа
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
    //первый символ должен быть обязательно М
    if adressString[iGraph] = 'M' then
    begin
      //М есть.
      flagM := true;
    end;

    if (flagM) then
    begin
      //M16
      if (adressString[iGraph + 1] = '1') and (adressString[iGraph + 2] = '6') then
      begin
        if ((adressString[iGraph + 3] = 'П') or (adressString[iGraph + 3] = 'п')) then
        begin
          if (adressString[iGraph + 4] = '1') then
          begin
            //задаем нач. смещение для выборки из массива
            pBeginOffset := 1;
          end;
          if (adressString[iGraph + 4] = '2') then
          begin
            //задаем нач. смещение для выборки из массива
            pBeginOffset := 2;
          end;
          flagBegin := true;
          iGraph := iGraph + 5;
          break;
        end
        else
        begin
          showMessage('Ошибка! Проверте разбираемые адреса,'
            + 'выбранная информативность им не соответствует!');
          //Application.Terminate;
          halt;
        end;
      end
      //остальные
      else
      begin
        //нач смещение
        pBeginOffset := 1;
        flagBegin := true;
        iGraph := iGraph + 3;
        break;
      end;
    end;
  end;

  if (flagBegin) then
  begin
    //обязательную часть проверили
    while {(adressString[iGraph]<>' ')} iGraph <= adrLength do
    begin
      codAsciiGraph := ord(adressString[iGraph]);
      // заполняем коэффициенты чтоб в конце посчитать номер и шаг.
      case codAsciiGraph of
        //Поиск А(а)
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
        //Поиск B(b)
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
        //Поиск C(c)
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
        //Поиск D(d)
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
        //Поиск E(e)
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
        //Поиск X(x)
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
        //Поиск T(t)
        84, 116:
        begin
          if ((adressString[iGraph + 1] = '0')and(adressString[iGraph + 2] = '1')) then
          begin
            //T01. Аналоговый 0.
            masElemParam[imasElemParam].adressType := 0;
            //указываем номер бита.
            //Используется только для контактных.
            masElemParam[imasElemParam].bitNumber := 0;
          end;

          if ((adressString[iGraph + 1] = '0')and(adressString[iGraph + 2] = '5')) then
          begin
            //T05. Контактный 1.
            masElemParam[imasElemParam].adressType := 1;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '1')) then
          begin
            //T21 Быстрый 1.
            masElemParam[imasElemParam].adressType := 3;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '2')) then
          begin
            //T22. Быстрый 2.
            masElemParam[imasElemParam].adressType := 2;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '3')) then
          begin
            //T23. Быстрый 3.
            masElemParam[imasElemParam].adressType := 4;
          end;
          //свой тип для ГРЦ Макеева
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '4')) then
          begin
            //T24 Быстрый 4.
            masElemParam[imasElemParam].adressType := 5;
          end;
          if ((adressString[iGraph + 1] = '2')and(adressString[iGraph + 2] = '5')) then
          begin
            //T25. БУС. Для проверки
            masElemParam[imasElemParam].adressType := 6;
          end;

          if ((adressString[iGraph + 1] = '1')and(adressString[iGraph + 2] = '1')) then
          begin
            //T11. Температурный
            masElemParam[imasElemParam].adressType := 7;
          end;
        end;
        //Поиск P(p)
        80, 112:
        begin
          //вытаскиваем и записываем одну цифру.
          //и указываем булевской переменной что адрес контактный
          //указываем номер бита. Используется только
          //для контактных. Присваивание для системы.
          masElemParam[imasElemParam].bitNumber :=
            strToInt(adressString[iGraph + 1] + adressString[iGraph + 2]);
          break;
        end;
      end;
      iGraph := iGraph + 3;
    end;

    infStrInt := StrToInt(adressString[2] + adressString[3]);
    //N1={Ma+Mb*Fa+Mc*Fa*Fb+Md*Fa*Fb*Fc+Me*Fa*Fb*Fc*Fd+Mx*Fa*Fb*Fc*Fd*Fe}
    //выбираем правильный первый элемент в зависимости от инф разб. адреса
    //M16
    if infStrInt = 16 then
    begin
      masElemParam[imasElemParam].numOutElemG := pBeginOffset + 2 * offset;
    end
    //остальные
    else
    begin
      masElemParam[imasElemParam].numOutElemG := pBeginOffset + offset;
    end;

    //выставляем шаг для выборки след. точки в завис. от информативности адреса
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

    //установим по умолчанию значение текущей
    //выводимой точки в 1 для всех адресов
    masElemParam[imasElemParam].numOutPoint := 1;
    //masElemParam[imasElemParam].numOutElemG:=
      //masElemParam[imasElemParam].numOutElemG+numPoint*
        //masElemParam[imasElemParam].stepOutG; //N=N1+nT
  end;
end;
//==============================================================================

//==============================================================================
//Заполнения массива параметров анализируемых адресов ОрбитыМ16
//==============================================================================

procedure TData.FillAdressParam;
var
  //переменная счетчик для разбора только нужных адресов
  adrCount: integer;
  //макс кол. адресов
  iAdr: integer;
  maxAdrNum:Integer;
begin
  //Обнуление динамического массива
  masElemParam := nil;
  iAdr := 0;
  maxAdrNum:=form1.OrbitaAddresMemo.Lines.Count - 1;
  for adrCount := 0 to maxAdrNum  do
  begin
    //при пробеге по адресам проверяем адрес это или логический разделитель
    if  form1.OrbitaAddresMemo.Lines.Strings[adrCount]<>'---' then
    begin
      //адрес
      //выделим память на элемент массива параметров
      setlength(masElemParam, iAdr  + 1);
      data.AdressAnalyser(form1.OrbitaAddresMemo.Lines.Strings[adrCount], iAdr);
      inc(iAdr);
    end;
  end;
  //запомнием максимальное количество адресов
  iCountMax := iAdr;
  //подсчитаем сколько каких адресов есть в работе
  data.CountAddres;
  //masElemParam:=nil;
end;
//==============================================================================

//==============================================================================
//Процедура для подсчета сколько каких адресов в конфиге есть
//==============================================================================

procedure TData.CountAddres;
var
  //счетчик перебора всех переданных адресов
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
        //аналоговые
        inc(acumAnalog);
      end;
      1:
      begin
        //контактные
        inc(acumContact);
      end;
      2, 3, 4, 5:
      begin
        //быстрые
        inc(acumFast);
      end;
      6:
      begin
        //БУС
        inc(acumBus);
      end;
      7:
      begin
        //температурные
        inc(acumTemp);
      end;
    end;
    inc(adrCount);
  end;
end;
//==============================================================================

//==============================================================================
//Подсчет порогового значения данных
//==============================================================================
function TData.SignalPorogCalk(bufMasSize: integer;acpBuf: TShortrArray; reqNumb: word): integer;
var
  //максимальное и минимальное значение данных с АЦП
  maxValue, minValue: integer;
  //счетчик для перебора эл. массива
  jSignalPorogCalk: integer;
begin
  //начальные значения массива
  maxValue := acpBuf[reqNumb xor $1][0];
  minValue := acpBuf[reqNumb xor $1][0];
  for jSignalPorogCalk := 1 to bufMasSize - 1 do
  begin
    //поиск максимума.
    if maxValue <= acpBuf[reqNumb xor $1][jSignalPorogCalk] then
    begin
      maxValue := acpBuf[reqNumb xor $1][jSignalPorogCalk];
    end;
    //поиск минимума
    if minValue >= acpBuf[reqNumb xor $1][jSignalPorogCalk] then
    begin
      minValue := acpBuf[reqNumb xor $1][jSignalPorogCalk];
    end;
  end;
  //к этому моменту min и max найдены.
  //считаем порог. среднее арифметическое
  result := (maxValue + minValue) div 2;
  //SignalPorogCalk:=1984 ;
end;
//==============================================================================

//=============================================================================
//Чтение значения из масива Орбиты
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
//Функция для чтения из массива фифо битов Орбиты побуферно
//offset -сдвиг для чтения необходимых элементов
//============================================================================
function TData.Read(offset: integer): integer;
var
  fifoOffset: integer;
begin
  //изменяем смещение для правильной выборки
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
//Обработка данных M16
//==============================================================================
procedure TData.TreatmentM16;
begin
  //пока точек в кольц буфере больше этого числа, разбираем
  while ((fifoBufCount >= 100000)and(not flagEnd)) do  ///!!!
  begin
    //поиск маркера первой нечетной фразы
    //поиск происходит каждый раз
    if (not firstFraseFl) then
    begin
      SearchFirstFraseMarker;
      //form1.tmrForTestOrbSignal.Enabled:=True;
    end
    else
    begin
      //если нашли маркер то производим разбор
      AnalyseFrase;
    end;
    // в случае сброса выход из выполнения
    {if flagEnd then
    begin
      break;
    end;}
  end;

  //проверяем что в буфере АЦП порог данных не соответствует 200 и меньше.
  //нет сигнала
  if SignalPorogCalk(round(buffDivide/10), buffer,RequestNumber)<=200 then   ///!!! round(buffDivide/10)
  begin
    outMF(127);
    //Form1.Memo1.Lines.Add('11');
    outMG(31);
  end;
end;
//==============================================================================

//==============================================================================
//Вывод на диаграмму число сбоев по МФ
//==============================================================================
procedure TData.OutMF(errMF:Integer);
var
  procentErr:Integer;
begin
  if errMF=0 then
  begin
    //сбоев нет фон clWhite
    form1.gProgress1.BackColor:=clWhite;
  end
  else
  begin
    //сбои есть фон clRed
    form1.gProgress1.BackColor:=clRed;
  end;

  procentErr:=Trunc(errMF/1.27);
  Form1.gProgress1.Progress:=procentErr;
end;
//==============================================================================

//==============================================================================
//Вывод на диаграмму число сбоев по МГ
//==============================================================================
procedure TData.OutMG(errMG:Integer);
var
  procentErr:Integer;
begin
  if errMG=0 then
  begin
    //сбоев нет фон clWhite
    form1.gProgress2.BackColor:=clWhite;
  end
  else
  begin
    //сбои есть фон clRed
    form1.gProgress2.BackColor:=clRed;
  end;
  procentErr:=Trunc(errMG/0.31);
  Form1.gProgress2.Progress:=procentErr;
end;
//==============================================================================

//==============================================================================
//Обработка данных M08,04,02,01
//==============================================================================
procedure TData.TreatmentM8_4_2_1;
begin
  //ограничим поиск маркера 3 размерами колич точек между маркерам фраз
  while (fifoBufCount >= MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR * 2) do //!! 3 на 2
  begin
    //ищем маркер фразы первый
    if (not fraseMarkFl) then
    begin
      countPointMrFrToMrFr := FindFraseMark(fifoLevelRead);
      //TestSMFOutDate(20,fifoLevelRead,1230);
      //while (true) do application.processmessages;
      if ((countPointMrFrToMrFr = -1) and (not flagEnd)) then
      begin
        {showMessage('Ошибка работы! Проверьте подключен ли прибор или наличие данных с него!');
        //closeFile(LogFile);
        acp.AbortProgram(' ', false);
        if ReadThreadErrorNumber <> 0 then
        acp.ShowThreadErrorMessage();
        //else form1.Memo1.Lines.Add(' The program was completed successfully!!!');
        //тест
        halt;
        //Если поток создан , то завершение потока
        if hReadThread <> THANDLE(nil) then
        begin
          //закрыли поток
          //EndThread(hReadThread);
          CloseHandle(hReadThread);
          sleep(50);
          showMessage('Программа была завершена');
          halt;
        end;}
      end;
      //при первом поиске рез. не достоверны
      countPointMrFrToMrFr := 0;
      //первый маркер фразы нашли
      fraseMarkFl := true;
    end
    else
    //нашли маркер фразы
    begin
      if (not qSearchFl) then
      begin
        qSearchFl := true;
      end
      else
      begin
        Inc(countForMF);
        //переместились на нужное количество точек вперед
        FifoNextPoint({MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR}minSizeBetweenMrFrToMrFr);
        //FifoNextPoint(10);
        //TestSMFOutDate(10,fifoLevelRead,10);
        //пров. наличия маркера фразы
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
          //вернулись к исходной точке поиска
          FifoBackPoint(minSizeBetweenMrFrToMrFr);
          //FifoBackPoint(10);
          //переместились на нужное количество точек вперед
          FifoNextPoint(minSizeBetweenMrFrToMrFr + 1);
          //FifoNextPoint(11);
          //пров. наличия маркера фразы
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
            //быстрым точки не нашли
            //вернулись к исходной точке поиска.
            FifoBackPoint(minSizeBetweenMrFrToMrFr + 1);
            //смещаемся на 2 точки вперед чтобы не найти предидущий маркер
            FifoNextPoint(2);
            //FifoBackPoint(11);
            //TestSMFOutDate(1230,fifoLevelRead,1230);
            //while (True) do Application.ProcessMessages;
            //быстрым поиском маркер не нашли, ищем основным
            countPointMrFrToMrFr := FindFraseMark(fifoLevelRead);
            //добавляем 2 точки в подсчет т.к сместились на них вперед
            countPointMrFrToMrFr:=countPointMrFrToMrFr+2;

            //Form1.Memo1.Lines.Add(IntToStr(fifoLevelRead)+' ++');


            Inc(countErrorMF);
            //Form1.Memo1.Lines.Add(IntToStr(countErrorMF)+' '+IntToStr(fifoLevelRead)+' '+IntToStr(countPointMrFrToMrFr));

            if countForMF={100}127 then
            begin
              //while (True) do Application.ProcessMessages; //!!!!
              countForMF:=0;
              //вывод сбоев по маркеру фразы на форму
              OutMF(countErrorMF);
              //проверяем если МФ не находится то и МГ не найдется подавно
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
              {showMessage('Ошибка работы! Проверьте подключен ли прибор и данные с него!');
              halt;}
            end;
            FillMasGroup(countPointMrFrToMrFr, fifoLevelRead,infStr, data.iMasGroup);
          end;
        end;
      end;
      //проверим счетчик для подсчета количества маркеров фразы
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
      //остановим работу с АЦП
      pModule.STOP_ADC();
    end;
    //завершим все работающие циклы
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
  //прием доступ
  form1.startReadACP.Enabled := true;
  //запись в tlm
  form1.tlmWriteB.Enabled := false;
  //особождаем память объекта ацп
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
  //строка с информ.
  str: string;
  masEcount: integer;
  rez:boolean;
begin
  rez:=false;
  //проверка на корректность всех адресов
  for i := 0 to form1.OrbitaAddresMemo.Lines.Count - 1 do
  begin
    str := '';
    str := form1.OrbitaAddresMemo.Lines.Strings[i][1] +
      form1.OrbitaAddresMemo.Lines.Strings[i][2]+form1.OrbitaAddresMemo.Lines.Strings[i][3];
    //проверим а не логический ли это разделитель
    if str = '---' then
    begin
      //перейдем на следующую итерацию цикла
      Continue;
    end;

    if ((str = 'M16')or(str = 'M08')or(str = 'M04')or(str = 'M02')or(str = 'M01')) then
    begin
      //выставим размерность массива группы от выбранной информативности
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
      //ShowMessage('Проверьте правильность адресов');
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
        //выставим размерность массива группы от выбранной информативности
        //также выставим коэф. для поиска маркера фразы для М08,04,02,01
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

        //количество элементов в массиве цикла от информативности
        masCircleSize:=masGroupSize*32;


        //нач. иниц. кольц. массива битов Орбиты
        for masEcount := 1 to FIFOSIZE do
        begin
          data.fifoMas[masEcount] := 9;
        end;

        //выделили память под массив группы 11 бит. на графики
        //SetLength(masGroup, masGroupSize);
        //выделили память под массив группы 12 бит. для сбора быстрых
        //SetLength(masGroupAll, masGroupSize);
        for masEcount := 1 to masGroupSize do
        begin
          masGroup[masEcount] := 9;
          masGroupAll[masEcount] := 9;
        end;


        //нач. релизация флага перекл. двойного буфера массива цикла
        //0 буфер
        data.reqArrayOfCircle := 0;
        //SetLength(masCircle[data.reqArrayOfCircle], masGroupSize * 32);
        //form1.Memo1.Lines.Add(intToStr(length(masCircle[reqArrayOfCircle])));
        //иниц. массива цикла
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
  //проверка на корректность адресов
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
        ShowMessage('Загруженные адреса не соотв. выбранной информативности');
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
//Функция поиска перехода из 0 в 1
//==============================================================================
function TData.SearchP0To1(curPoint:Integer;nextPoint:integer):Boolean;
var
  bool:Boolean;
begin
  bool:=False;
  //проверяем переход через порог из 0 в 1
  if ((curPoint < porog) and (nextPoint >= porog)) then
  begin
    bool:=True;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//Функция поиска перехода из 0 в 1
//==============================================================================
function TData.SearchP1To0(curPoint:Integer;nextPoint:integer):Boolean;
var
  bool:Boolean;
begin
  bool:=false;
  //проверяем переход через порог из 1 в 0
  if ((curPoint > porog) and (nextPoint <= porog)) then
  begin
    bool:=True;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//Процедура для тестирования поиска маркера фразы. Выводит наглядно данные
//==============================================================================
procedure TData.TestSMFOutDate(numPointDown:Integer;numCurPoint:integer;numPointUp:integer);
var
  numP:Integer;
begin
  form1.Memo1.Lines.Add('Пороговое значение!!! '+intTostr(porog));

  //до точки
  for numP:=numCurPoint-numPointDown to  numCurPoint-1 do
  begin
    form1.Memo1.Lines.Add('Номер точки в массиве '+intTostr(numP)+' '+'Значение '+IntToStr(fifoMas[numP]));
  end;

  //после точки
  for numP:=numCurPoint to  numCurPoint+numPointUp do
  begin
    if numP=numCurPoint then
    begin
      form1.Memo1.Lines.Add('Номер точки в массиве!!! '+
        intTostr(numP)+' '+'Значение '+IntToStr(fifoMas[numP]));
    end
    else
    begin
      form1.Memo1.Lines.Add('Номер точки в массиве '+
        intTostr(numP)+' '+'Значение '+IntToStr(fifoMas[numP]));
    end;
  end;
  form1.Memo1.Lines.Add('====================');
end;
//==============================================================================





//==============================================================================
//Функция для поиска маркера фразы. На вход номер точки в кольц.буфере(начало предидущего маркера фр.)
//На выходе номер точки в кольц. буфере(начало след. маркера фр.).
//Возвращает колич. точек между маркерами фр.
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

  //счетчик анализ. точек
  iSearch: integer;
  downToUpFl: boolean;
  //флаг успешности поиска маркера фразы
  searchOKfl: boolean;
  numPointFromFpToMf:Integer;
begin
  //изначально поиск не успешен
  {searchOKfl := false;
  frMarkSize := 0;
  sizeFraseInPoint := 0;
  //можно считать точки пред
  startSearch := false;
  //флаги для поиска ситуации перехода меньше больше
  downToUpFl := false;
  fl := false;
  fl2 := false;
  //ищем маркер фразы в (3)2 размерах колич точек между маркерами
  for iSearch := 1 to MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR * 2 do //3 на 2
  begin
    if (not downToUpFl) then
    begin
      //прочитаем текущую точку
      currentACPVal := ReadFromFIFObuf;
      //+1 точка в счетчик точек между маркерами фраз
      inc(sizeFraseInPoint);
      if ((currentACPVal < porog) and (fifoMas[fifoLevelRead] >= porog)) then
      begin
        fl := true;
      end;
      if ((fl) and (currentACPVal >= porog)) then
      begin
        downToUpFl := true;
        startSearch := true;
        //предположительно точка маркера, засчитываем её
        inc(frMarkSize);
      end;
    end;
    if (startSearch) then
    begin
      currentACPVal := ReadFromFIFObuf;
      //+1 точка в счетчик точек между маркерами фраз
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
          //не маркер
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
  //есть маркер
  begin
      //возвращаем количество точек между маркерами фраз
    result := sizeFraseInPoint - (frMarkSize + 1);
  end
  else
  //нет маркера
  begin
    result := -1;
  end;}

  numPointFromFpToMf:=0;
  //состояние найденности первого перехода из 0 в 1
  downToUpFl:=false;
  searchOKfl:=false;
  sizeFraseInPoint := 0;
  // в двух блоках колич. точек между маркерами ищем переход из 0 в 1
  for iSearch := 1 to {MIN_SIZE_BETWEEN_MR_FR_TO_MR_FR}minSizeBetweenMrFrToMrFr * 2 do //3 на 2
  begin
    //прочитаем текущую точку
    currentACPVal := ReadFromFIFObuf;
    //+1 точка в счетчик точек между маркерами фраз
    inc(sizeFraseInPoint);
    //проверяем переход через порог из 0 в 1
    //если первый переход нашли, то дальше не ищем
    if ((SearchP0To1(currentACPVal,fifoMas[fifoLevelRead]))and(not downToUpFl)) then
    begin
      //нашли первый переход
      downToUpFl:=true;
      //TestSMFOutDate(5,fifoLevelRead,5);
    end;

    if (downToUpFl) then
    begin
      Inc(numPointFromFpToMf);
      //ищем любой переход через порог
      if ((SearchP0To1(currentACPVal,fifoMas[fifoLevelRead]))or
         (SearchP1To0(currentACPVal,fifoMas[fifoLevelRead]))) then
      begin
        //dec(numPointFromFpToMf);//!! для более точного счета 
        //проверяем не нашли ли маркер
        if ((Frac(numPointFromFpToMf/markKoef)>=0.25)and
           (Frac(numPointFromFpToMf/markKoef)<=0.75)) then
         begin
          //TestSMFOutDate(10,fifoLevelRead,10);
          //нашли маркер
          searchOKfl:=True;
          //вышли из поиска
          Break;
         end;
      end;
    end;
  end;
  if (searchOKfl) then
  //есть маркер
  begin
    //возвращаем количество точек между маркерами фраз
    result := sizeFraseInPoint {- (frMarkSize + 1)};
  end
  else
  //нет маркера
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
  //перемещаем счетчик чтения вперед
  if ((fifoLevelRead + countPoint) > FIFOSIZE) then
  begin
    //вычисляем на сколько больше максимального значения номера точки в цикл. буфере
    offset := (fifoLevelRead + countPoint) - FIFOSIZE;
    fifoLevelRead := offset
  end
  else
  begin
    fifoLevelRead := fifoLevelRead + countPoint;
  end;
  //убавляем. точки от счетчика обр. точек в соотв. с fifoLevelRead
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

  //проверяем мин. разм. маркера
  if (QtestMarker(fifoLevelRead, {MARKMINSIZE}widthPartOfMF)) then
  begin
    testRes := true;
  end;
  {else
  begin
    //проверяем  макс. разм. маркера
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
  //перемещаем счетчик чтения назад
  if fifoLevelRead <= countPoint then
  begin
    offset := countPoint - fifoLevelRead;
    fifoLevelRead := FIFOSIZE - offset;
  end
  else
  begin
    fifoLevelRead := fifoLevelRead - countPoint;
  end;
  //добавл. точки к счетчику обр. точек в соотв. с fifoLevelRead
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
  //считаем количество слов между маркерами от информативности
  //между маркерами всегда 2 фразы
  numWordInByte := StrToInt(orbInf[3]) * 2;
  //вычисляем количество точек кольц. буфера на 1 символ Орбиты
  stepToTransOrbOne := countPointToPrevM / numWordInByte / SIMBOLINWORD;
  //stepToTransOrbOne := markKoef;
  //возвращаемся к началу предидущего маркера фразы
  countStep := ReadFromFIFObufB(countPointToPrevM);
  //countStep := ReadFromFIFObufB(4);
  //смещаемся в середину бита, нач. смещение +4 точки
  //countStep := ReadFromFIFObufN(round(countStep), {MARKMAXSIZE}4); //!! 1 на 2
  wordCount := 1;
  //заполняем массив группы Орбиты
  while wordCount <= numWordInByte do
  begin
    //нумеруем фразы посленахождения маркера группы
    if (((wordCount = 1) or (wordCount = {9}StrToInt(orbInf[3])+1)) and (flagCountFrase)) then
    begin
      inc(fraseCount);
      if fraseCount = 129 then
      begin
        fraseCount := 1;
        //первое слово, первой группы, первой фразы. Разрешаем заполнять массив цикла
        if ((wordCount = 1) and (groupCount = 1)) then
        begin
          if (tlm.flagWriteTLM) then
          begin
            flSinxC := true;
          end;
        end;
      end;
      //SaveBitToLog(' Фраза№ '+IntToStr(fraseCount));
    end;
    //сбор слова со старшего бита
    simbCount := SIMBOLINWORD - 1;
    while simbCount >= 0 do
    begin
      //перевод зн. с АЦП в Орб. нули и единицы
      if (fifoMas[round(countStep)] >= porog) then
      begin
        //запись 1 в нужный бит
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
    //сбор маркера номера группы
    //7 разрядное значение со старшего к младшему
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
      //если фраза четная в 1 слове смотрим 12 бит для сбора маркера группы и цикла
      //8 разрядов. МГ 01110010. МЦ 10001101
    begin
      Inc(countEvenFraseMGToMG);

      //12 бит
      if ((wordBuf and $800) <> 0) then
      begin
        bufMarkGroup := (bufMarkGroup shl 1) + 1;
      end
      else
      begin
        bufMarkGroup := (bufMarkGroup shl 1) + 0;
      end;

      //между маркерами групп(цикла) по 64 четных фразы
      //проверяем не собрали ли маркер группы 8 бит
      if ((bufMarkGroup and 255) = 114{112}) then
      begin
        //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' МФ'); //TO-DO<><><>
        //+1 МГ
        Inc(countForMG);
        if countEvenFraseMGToMG<>64 then
        begin
          //сбой по МГ есть
          Inc(countErrorMG);
          //form1.Memo1.Lines.Add(IntToStr(countErrorMG));
        end;

        if countForMG={100}31 then
        begin
          //выводим число сбоев по МГ
          OutMG(countErrorMG);
          //form1.Memo1.Lines.Add(IntToStr(countErrorMG));
          countErrorMG:=0;
          countForMG:=0;
        end;

        countEvenFraseMGToMG:=0;


        fraseCount := 128;
        //флаг нумерации фраз
        //flagCountFrase:=true;
        flfl := true;
        //сбросили маркер группы
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

      //проверяем не собрали ли маркер цикла 8 бит
      if ((bufMarkGroup and 255) = 141) then
      begin
        //Form1.Memo1.Lines.Add(IntToStr(countEvenFraseMGToMG)+' МЦ');
        countEvenFraseMGToMG:=0;
        groupCount := 32;
        flagCountGroup := true;
        //сбросили маркер цикла
        bufMarkCircle := 0;
      end;
    end;

    //поиск маркера кадра
    //1 в 1 бите 1 слова 16 фразы 1 группы
    if ((wordCount = 1)and(fraseCount=16)and(groupCount=1))then
    begin
      if ((wordBuf and 1) = 1) then
      begin
        //маркер кадра найден
        bufNumGroup:=0;
      end
      else
      begin
        //маркер кадра не найден
      end;
    end;

    //получаем информацию, отбрасываем 12 и 1 бит
    if (flagCountFrase) then
    begin
      //запись в группу с младшего слова 11 бит
      masGroup[iMasGroup] := wordBuf and 2047;{((wordBuf and 2047) shr 1)} {wordBuf} //!!!
      //запись в группу с младшего слова 12 бит
      masGroupAll[iMasGroup] := wordBuf and 4095;{((wordBuf and 2047) shr 1)} {wordBuf} //!!!
      inc(iMasGroup);
      //если включена синх. с началом цикла Орбиты
      if (flSinxC) then
      begin
        //запись в цикл 12 битных значений(слов Орбиты)
        masCircle[reqArrayOfCircle][imasCircle] := {((} wordBuf { and 2046) shr 1)};
        inc(imasCircle);
        //Заполнили 32767 элементов
        if imasCircle = {length(masCircle[reqArrayOfCircle])}masCircleSize+1 then
        begin
          //form1.Memo1.Lines.Add(intToStr(length(masCircle[reqArrayOfCircle])));
          imasCircle := 1;
          //массив цикла заполнен. пишем в файл ТЛМ
          //если запис в тлм активна то пишем блок(цикл Орбиты в него)
          if (tlm.flagWriteTLM) then
          begin
            if infNum = 0 then
            begin
              //M16
              tlm.WriteTLMBlockM16(tlm.msTime);
            end
            else
            begin
              //другие информативности
              tlm.WriteTLMBlockM08_04_02_01(tlm.msTime);
            end;
            {form1.WriteTLMTimer.Enabled:=true;}
          end;
        end;
      end;

      //заполнили 1023 элемента
      if iMasGroup = {1024}{1025}masGroupSize+1 then //!!!!
      begin
        iMasGroup := 1;
        //включаем таймер вывода на диаграмму
        form1.TimerOutToDia.Enabled := true;
        //проверяем собрали ли 97 значений БУС  0..96
        {if (CollectBusArray(iBusArray)) then
          begin
           //вкл таймер вывода на диаграмму БУС
            form1.TimerOutToDiaBus.Enabled := true;
          end;  }
        //вывод всех значений на диаграмму
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
    //хоть одна точка больше порога. значит это не маркер
    //проверяем не выходим ли за пределы кольц буфера и при необх. перех. в начало
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
//Функция поиска нужного количества единиц маркера фразы
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
  //переместимся к предположительному началу маркера
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
    //Form1.Memo1.Lines.Add('Единицы');
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
//Функция поиска нужного количества нулей маркера фразы
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
    //Form1.Memo1.Lines.Add('Нули');
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
  //предположительно передан номер середины маркера
  i := begNumPoint;

  testFlag := false;

  if TestMFOnes(i,pointCounter) then
  begin
    if TestMFNull(i,pointCounter) then
    begin
      //это маркер
      testFlag:=true;
    end;
  end;
  {

  testFlag := true;
  //проверяем что нужное количество Орбитовских единиц присутствует
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
  //проверяем что после пров. колич единиц находится столько же нулей
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
//Функция для чтения из массива фифо нужного элемента  offset -сдвиг для чтения необходимых элементов
//============================================================================
function TData.ReadFromFIFObufB(offset: integer): integer;
var
  fifoOffset: integer;
begin
  //изменяем смещение для правильной выборки
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
//Функция для чтения из массива фифо нужного элемента  offset -сдвиг для чтения необходимых элементов
//============================================================================

function TData.ReadFromFIFObufN(prevMarkFrBeg: integer; offset: integer): integer;
var
  fifoOffset: integer;
begin
  //изменяем смещение для правильной выборки
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
  //запуск записи в тлм
  begin
    form1.tlmWriteB.Caption := '0 Mb';
    //пока пишем в тлм мы не можем завершить прием
    form1.startReadACP.Enabled:=false;
    //нач иниц. счетчика установки в 1 ГЦ
    tlm.iOneGC := 4;
    tlm.StartWriteTLM;
    tlm.WriteTLMhead;
    //флаг синхронизации для записи в массив цикла
    data.flSinxC := false;
    //разрешаем запись блоков в файл ТЛМ
    tlm.flagWriteTLM := true;
    //устанавливаем флаг первой записи блока в файл
    tlm.flagFirstWrite := true;
    tlm.flagEndWrite := false;
  end
  else
  //остановка записи в тлм
  begin
    //вспомог. флаг для синхр. записи в массив цикла
    data.flBeg := false;
    //флаг синхронизации для записи в массив цикла
    data.flSinxC := false;
    tlm.flagWriteTLM := false;
    //form1.WriteTLMTimer.Enabled:=false;
    tlm.flagEndWrite := true;
    closeFile(tlm.PtlmFile);
    tlm.countWriteByteInFile := 0;
    tlm.precision := 0;
    form1.tlmWriteB.Caption := 'Запись';
    //form1.Memo1.Lines.Add('Количество записанных блоков(циклов) '+
    //intToStr(tlm.blockNumInfile));
    ShowMessage('Файл записан!');
    //файл tlm записали, можем завершить прием
    form1.startReadACP.Enabled:=true;
  end;
  //от запуска с останову и наоборот
  tlm.tlmBFlag := not tlm.tlmBFlag;
end;

procedure TForm1.startReadTlmBClick(Sender: TObject);
begin
  //разрешение масштабирования графиков
  form1.fastGist.AllowZoom:=true;
  form1.fastGist.AllowPanning:=pmBoth;
  form1.gistSlowAnl.AllowZoom:=true;
  form1.gistSlowAnl.AllowPanning:=pmBoth;
  form1.tempGist.AllowZoom:=True;
  form1.tempGist.AllowPanning:=pmBoth;

  testOutFalg:=true;
  //проиниц. счетчики для подсч. колич. каждого типа адресов
  //ам
  acumAnalog := 0;
  //темп.
  acumTemp:=0;
  //ак
  acumContact := 0;
  //б
  acumFast := 0;
  //сброс программы в начальное состояние
  data.ReInitialisation;
  data.Free;
  data := Tdata.CreateData;
  //перезагрузим акт. адреса.
  form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
  //Получение правильного списка адресов
  GetAddrList;
  //Установка списка правильных адресов
  SetOrbAddr;

  //проверка правильности рабочих адресов
  if data.GenTestAdrCorrect then
  begin
    //объект для работы с ТЛМ
    tlm := Ttlm.CreateTLM;
    //положение ползунка скорости
    form1.tlmPSpeed.Position := 3;
    form1.tlmPSpeed.Enabled:=true;
    //заполнение массива параметров
    data.FillAdressParam;
    ShowMessage('Выберите файл .tlm для воспроизведения!');
    form1.startReadACP.Enabled := false;
    //выводим имя открытого файла
    tlm.OutFileName;
  end
  else
  begin
    showMessage('Проверьте правильность адресов!');
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
    //учитываем количество аналоговых и контактных адресов до этого
    data.chanelIndexFast := ValueIndex + acumAnalog + acumContact+acumTemp;
    //перестроим координатную ось в зависимости от типа
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
    //старт отрисовки
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
    //288 экспериментальное смещение для правильного чтения из файла
    tlm.stream.Position := (form1.TrackBar1.Position - 1) * tlm.sizeBlock + MAXHEADSIZE;
    //form1.Memo1.Lines.Add(intToStr(tlm.stream.Position));
    form1.TimerPlayTlm.Enabled := true;
  end
end;

procedure TForm1.stopClick(Sender: TObject);
begin
  form1.propB.Enabled := true;
  //выкл. таймера проигр файла
  form1.TimerPlayTlm.Enabled := false;
  form1.TrackBar1.Enabled := false;
  //выкл кнопок плеера
  form1.PanelPlayer.Enabled := false;
  //выбор режима работы
  form1.startReadACP.Enabled := true;
  form1.startReadTlmB.Enabled := true;
  //сброс настроек к началу
  form1.TrackBar1.Position := 1;
  form1.fileNameLabel.Caption := '';
  form1.orbTimeLabel.Caption := '';
  //завершение проигрывания
  tlm.fFlag := false;
  form1.TimerPlayTlm.Enabled := false;
  //сброс файла
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
  //при смене настроек обнулим список раб. адресов.
  form1.OrbitaAddresMemo.Clear;
  ShowMessage('Выберите файл адресов Орбиты!');
  form1.OpenDialog2.InitialDir:=ExtractFileDir(ParamStr(0))+'\ConfigDir';;
  //запросим у польз. файл настроек.
  if form1.OpenDialog2.Execute then
  begin
    propIniFile:=TIniFile.Create(ExtractFileDir(ParamStr(0))+'\ConfigDir\property.ini');
    //propStrPath:=propIniFile.ReadString('lastPropFile','path','');
    //внесем путь до файла настроек
    propIniFile.WriteString('lastPropFile','path',form1.OpenDialog2.FileName);
    //считаем внесенный путь.
    propStrPath:=propIniFile.ReadString('lastPropFile','path','');
    propIniFile.Free;
    //заполним список актуальными адресами
    form1.OrbitaAddresMemo.Lines.LoadFromFile(propStrPath);
    //Получение правильного списка адресов
    GetAddrList;
    //Установка списка правильных адресов
    SetOrbAddr;

    form1.startReadACP.Enabled := true;
    form1.startReadTlmB.Enabled := true;
    form1.saveAdrB.Enabled:=true;
  end
  else
  //не выбран
  begin
    ShowMessage('Файл адресов Орбиты не выбран!');
  end;
end;

procedure TForm1.saveAdrBClick(Sender: TObject);
var
  strOut:string;
begin
  strOut:=ExtractFileName(propStrPath){RightStr(propStrPath,7)};
  showMessage('Файл адресов '+strOut+' изменен!');
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
      //сигнал найден
      form1.tmrForTestOrbSignal.Enabled:=false;
    end
    else
    begin
      form1.tmrForTestOrbSignal.Enabled:=false;
      ShowMessage('Сигнал Орбиты не найден! Проверьте сигнал!');
      data.graphFlagFastP := false;

      //Application.ProcessMessages;
      sleep(50);
      //Application.ProcessMessages;

      if ((form1.tlmWriteB.Enabled)and
          (not form1.startReadTlmB.Enabled)and
          (not form1.propB.Enabled))  then
      begin
        //остановим работу с АЦП
        pModule.STOP_ADC();
      end;
      //завершим все работающие циклы
      flagEnd:=true;
      wait(20);
      //завершим приложение по человечески.
      Application.Terminate;
    end;
  end;
end;

procedure TForm1.Series7Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //избегаем доступа к мемо. и в случае доступности
  //мемо делаем его недоступным и наоборот
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

