program Project1;

uses
  Forms,
  OrbitaAll in 'OrbitaAll.pas' {Form1},
  ExitForm in 'ExitForm.pas' {Form2};



{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

