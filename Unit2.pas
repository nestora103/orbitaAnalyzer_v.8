{Второй поток. Работа с АЦП. Формирование кольцевого буфера с битами Орбиты}

unit Unit2;

interface

uses
  Classes,Dialogs,Lusbapi,Visa_h,Windows,SysUtils,Unit1;








//===========================================================================



implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure twoThred.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ twoThred }




end.
