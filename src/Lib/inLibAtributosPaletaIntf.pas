unit inLibAtributosPaletaIntf;

interface

uses
  System.Generics.Collections, Vcl.Graphics, Uni;

type
  TInfoBasico = record
    HexColor: string;
    Color: TColor;
    Nombre: string;
    EsValido: Boolean;
  end;
  TEntradaCacheBasico = record
    IdVariacion: string;
    Codigo: string;
    Nombre: string;
    Valor: string;
    Descripcion: string;
    Info: TInfoBasico;
  end;
  TValorPaletaArticulo = record
    Valor: string;
    Info: TInfoBasico;
  end;
  ILecturasAtributosPaleta = interface
    ['{B3D88735-FB3D-4C05-8BCA-214853E24B62}']
    function ListarEntradasCache(
      AConexion: TUniConnection): TArray<TEntradaCacheBasico>;
    function ObtenerBasicosArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<string>;
    procedure CargarMapaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo: string;
      ADestino: TDictionary<string, string>);
    procedure CargarMapaGlobal(AConexion: TUniConnection;
      ADestino: TDictionary<string, string>);
    function ListarPaletaArticulo(AConexion: TUniConnection;
      const ACodigoArticulo,
      AIdVariacion: string): TArray<TValorPaletaArticulo>;
    function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
      const ACodigoArticulo, AIdVariacion, AValor: string;
      out AInfo: TInfoBasico): Boolean;
  end;

implementation

end.
