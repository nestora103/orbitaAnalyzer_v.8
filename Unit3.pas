{Третий поток. Обработка битов Орбиты. И вывод в файл полученных слов Орбиты}
unit Unit3;

interface

uses
  Classes,Dialogs;

type
  TreeThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TreeThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TreeThread }

procedure TreeThread.Execute;
begin
  { Place thread code here }
   ShowMessage('Сообщение из потока 3');
end;

end.
