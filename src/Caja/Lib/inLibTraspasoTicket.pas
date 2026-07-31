{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasoTicket                                           }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Imprime (o previsualiza si la impresora es 'DEBUG') el ticket de una      }
{    solicitud de traspaso, listando por cada SKU la cantidad pedida y el      }
{    stock en el almacen origen y en el almacen destino. Patron clonado de     }
{    inLibArqueoTicket (TTicketTermico + preview TFormVisualizador).           }
{    Texto en ASCII a proposito para no depender del encoding del .pas.        }
{******************************************************************************}
unit inLibTraspasoTicket;

interface

uses
  System.SysUtils, System.Classes, Data.DB,
  inLibFTicket, inLibPreviewTicket, inLibDir,
  inLibTraspasoTicketIntf;

type
  TTraspasoTicket = class
  private
    // Imprime el bloque de una linea: SKU (en negrita), descripcion del
    // articulo y las tres magnitudes (unidades + stock origen/destino) con
    // etiquetas claras. El ticket no lleva precios a proposito.
    class procedure ImprimirLineaSku(ATicket: TTicketTermico;
                                     const ASku, ADescripcion,
                                     AEtiqUds: string; AUds: Double;
                                     const AEtiqOrigen: string; AOrigen: Double;
                                     const AEtiqDestino: string;
                                     ADestino: Double);
  public
    // Imprime/previsualiza el ticket de una solicitud de traspaso ya grabada.
    class procedure ImprimirSolicitud(
                                      const APreview: IPreviewTicket;
                                      const ARepositorio:
                                      IRepositorioTraspasoTicket;
                                      const ANumero, ASerie: string;
                                      const ANombreImpresora: string = 'DEBUG');
    // Imprime/previsualiza el ticket de un traspaso ya ejecutado (F12 con
    // ticket). Recorre las lineas en memoria (ALineas: campos CODIGO_UNIDAD y
    // CANTIDAD) y por cada SKU calcula el stock en origen y en destino.
    class procedure ImprimirTraspaso(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const ADocRef, AOrigen, ADestino,
                                     AEmpleado: string; ALineas: TDataSet;
                                     const ANombreImpresora: string = 'DEBUG');
    // Reimprime el ticket de un traspaso ya grabado leyendo la cabecera de la
    // operacion de caja y sus lineas (movimientos de salida) de la BBDD. Lo usa
    // el boton Reimprimir de la consulta de operaciones (TR/TA).
    class procedure ImprimirTraspasoDesdeBD(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const AEmpresa, AAlmacen, ACaja,
                                     ANumOperacion: string;
                                     const ANombreImpresora: string = 'DEBUG';
                                     ARutasPDF: TStrings = nil;
                                     ASoloPDF: Boolean = False);
  end;

implementation

uses
  inLibFormatoDocumento, inLibMsgTickets;

class procedure TTraspasoTicket.ImprimirLineaSku(ATicket: TTicketTermico;
                                   const ASku, ADescripcion,
                                   AEtiqUds: string; AUds: Double;
                                   const AEtiqOrigen: string; AOrigen: Double;
                                   const AEtiqDestino: string;
                                   ADestino: Double);
var
  sDesc: string;
begin
  // SKU destacado para identificar la unidad.
  ATicket.Negrita(True);
  ATicket.EscribirLinea(ASku);
  ATicket.Negrita(False);
  // Descripcion del articulo, recortada al ancho del ticket para no desbordar.
  sDesc := Trim(ADescripcion);
  if Length(sDesc) > N_CHAR_LIN then
    sDesc := Copy(sDesc, 1, N_CHAR_LIN);
  if sDesc <> '' then
    ATicket.EscribirLinea(sDesc);
  // Unidades movidas/pedidas y stock resultante en origen y destino. Sin
  // precios: el coste no aparece en el ticket.
  ATicket.TextoColumnas(AEtiqUds, FormatFloat('0.###', AUds));
  ATicket.TextoColumnas(AEtiqOrigen, FormatFloat('0.###', AOrigen));
  ATicket.TextoColumnas(AEtiqDestino, FormatFloat('0.###', ADestino));
end;

class procedure TTraspasoTicket.ImprimirSolicitud(
                                     const APreview: IPreviewTicket;
                                     const ARepositorio:
                                     IRepositorioTraspasoTicket;
                                     const ANumero, ASerie: string;
                                     const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  Cabecera: TSolicitudTraspasoTicket;
  Lineas: TArray<TLineaSolicitudTraspasoTicket>;
  ComandosESC, RutaPDF, sImpresora: string;
  iLinea: Integer;
begin
  if Assigned(ARepositorio) then
  begin
    // Impresora parametrizada
    // (vgerDefPrinter -> ParametrosCaja.ImpresoraCaja); si viene
    // vacia, preview.
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Cabecera := ARepositorio.ObtenerSolicitud(
      ANumero,
      ASerie);
    if Cabecera.Existe then
    begin
      Ticket := TTicketTermico.Create(sImpresora);
      try
        Ticket.Inicializar;
        Ticket.ConfigurarEspanol;
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea(STicketSolicitudTraspaso);
        Ticket.EscribirLinea(ASerie + '/' + ANumero);
        Ticket.Negrita(False);
        Ticket.SaltarLineas(1);
        Ticket.Alinear(alIzquierda);
        Ticket.TextoColumnas(STicketOrigen, Cabecera.Origen);
        Ticket.TextoColumnas(STicketDestino, Cabecera.Destino);
        Ticket.TextoColumnas(STicketEmpleado, Cabecera.Empleado);
        Ticket.TextoColumnas(STicketEstado, Cabecera.Estado);
        Ticket.TextoColumnas(
          STicketFecha,
          FormatDateTime('dd/mm/yyyy', Cabecera.Fecha));
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea(STicketArticulos);
        Ticket.LineaSeparadora('-');
        // Lineas: por SKU, descripcion del articulo (denormalizada en la
        // propia linea, igual que en los movimientos), cantidad pedida y stock
        // disponible en origen y destino.
        Lineas := ARepositorio.ListarLineasSolicitud(
          ANumero,
          ASerie,
          Cabecera.Origen,
          Cabecera.Destino);
        iLinea := 0;
        while iLinea < Length(Lineas) do
        begin
          // Solicitud: nada se ha movido aun, el stock es la disponibilidad
          // actual en cada almacen (no lleva "tras traspaso").
          ImprimirLineaSku(Ticket,
            Lineas[iLinea].Sku,
            Lineas[iLinea].Descripcion,
            STicketUnidadesPedidas,
            Lineas[iLinea].CantidadPedida,
            STicketStockOrigen,
            Lineas[iLinea].StockOrigen,
            STicketStockDestino,
            Lineas[iLinea].StockDestino);
          Inc(iLinea);
        end;
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
        Ticket.SaltarLineas(2);
        Ticket.CortarPapel;
        // Vista previa (DEBUG) o impresion real
        ComandosESC := Ticket.ObtenerComandos;
        RutaPDF := GetUserFolderTickets + 'SolTraspaso_' + ASerie + '_' +
                   ANumero + '.pdf';
        ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                     sImpresora);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspaso(
                                   const APreview: IPreviewTicket;
                                   const ARepositorio:
                                   IRepositorioTraspasoTicket;
                                   const ADocRef, AOrigen, ADestino,
                                   AEmpleado: string; ALineas: TDataSet;
                                   const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  ComandosESC, RutaPDF, sImpresora, sRefArch, sSku: string;
  dPed, dOrg, dDes: Double;
  bm: TBookmark;
begin
  if Assigned(ARepositorio) and Assigned(ALineas) then
  begin
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Ticket := TTicketTermico.Create(sImpresora);
    try
      Ticket.Inicializar;
      Ticket.ConfigurarEspanol;
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketTraspaso);
      Ticket.EscribirLinea(ADocRef);
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas(STicketOrigen, AOrigen);
      Ticket.TextoColumnas(STicketDestino, ADestino);
      Ticket.TextoColumnas(STicketEmpleado, AEmpleado);
      Ticket.TextoColumnas(
        STicketFecha,
        FormatDateTime('dd/mm/yyyy', Now));
      Ticket.LineaSeparadora('-');
      Ticket.EscribirLinea(STicketArticulos);
      Ticket.LineaSeparadora('-');
      // Recorre las lineas en memoria sin perder el registro actual. El ticket
      // se imprime DESPUES de grabar, asi que el stock leido ya es el estado
      // resultante del traspaso (por eso "tras traspaso").
      bm := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          sSku := ALineas.FieldByName('CODIGO_UNIDAD').AsString;
          if Trim(sSku) <> '' then
          begin
            dPed := ALineas.FieldByName('CANTIDAD').AsFloat;
            dOrg := ARepositorio.ObtenerStock(
              AOrigen,
              sSku);
            dDes := ARepositorio.ObtenerStock(
              ADestino,
              sSku);
            ImprimirLineaSku(Ticket, sSku,
              ALineas.FieldByName('DESCRIPCION').AsString,
              STicketUnidades, dPed,
              STicketStockOrigenTrasTraspaso, dOrg,
              STicketStockDestinoTrasTraspaso, dDes);
          end;
          ALineas.Next;
        end;
      finally
        ALineas.GotoBookmark(bm);
        ALineas.FreeBookmark(bm);
        ALineas.EnableControls;
      end;
      Ticket.LineaSeparadora('-');
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
      Ticket.SaltarLineas(2);
      Ticket.CortarPapel;
      // Vista previa (DEBUG) o impresion real. El nombre de archivo no puede
      // llevar separadores: se sustituyen por '_'.
      ComandosESC := Ticket.ObtenerComandos;
      sRefArch := StringReplace(ADocRef, '/', '_', [rfReplaceAll]);
      sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
      RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
      ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                   sImpresora);
    finally
      FreeAndNil(Ticket);
    end;
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspasoDesdeBD(
                                   const APreview: IPreviewTicket;
                                   const ARepositorio:
                                   IRepositorioTraspasoTicket;
                                   const AEmpresa, AAlmacen, ACaja,
                                   ANumOperacion: string;
                                   const ANombreImpresora: string;
                                   ARutasPDF: TStrings;
                                   ASoloPDF: Boolean);
var
  Ticket: TTicketTermico;
  Cabecera: TTraspasoTicketHistorico;
  Lineas: TArray<TLineaTraspasoTicket>;
  ComandosESC, RutaPDF, sImpresora, sRefArch: string;
  sDocRef: string;
  dPed, dOrg, dDes: Double;
  iLinea: Integer;
begin
  if Assigned(ARepositorio) then
  begin
    sImpresora := ANombreImpresora;
    if Trim(sImpresora) = '' then
      sImpresora := 'DEBUG';
    Cabecera := ARepositorio.ObtenerTraspasoHistorico(
      AEmpresa,
      AAlmacen,
      ACaja,
      ANumOperacion);
    if Cabecera.Existe then
    begin
      if Trim(Cabecera.Serie + Cabecera.NumeroDocumento) <> '' then
        sDocRef := FormatearDocumento(
          Cabecera.FormatoDocumento,
          Cabecera.Serie,
          Cabecera.NumeroDocumento)
      else
        sDocRef := ANumOperacion;
      Ticket := TTicketTermico.Create(sImpresora);
      try
        Ticket.Inicializar;
        Ticket.ConfigurarEspanol;
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea(STicketTraspaso);
        Ticket.EscribirLinea(sDocRef);
        Ticket.Negrita(False);
        Ticket.SaltarLineas(1);
        Ticket.Alinear(alIzquierda);
        Ticket.TextoColumnas(STicketOrigen, Cabecera.Origen);
        Ticket.TextoColumnas(STicketDestino, Cabecera.Destino);
        Ticket.TextoColumnas(STicketEmpleado, Cabecera.Empleado);
        Ticket.TextoColumnas(STicketOperacion, ANumOperacion);
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea(STicketArticulos);
        Ticket.LineaSeparadora('-');
        // Lineas: movimientos de salida (la salida del origen). La descripcion
        // viene denormalizada en el propio movimiento (DESCRIPCION_ARTICULO_MOV).
        Lineas := ARepositorio.ListarLineasTraspaso(
          AEmpresa,
          AAlmacen,
          ACaja,
          ANumOperacion);
        iLinea := 0;
        while iLinea < Length(Lineas) do
        begin
          dPed := Lineas[iLinea].Cantidad;
          dOrg := ARepositorio.ObtenerStock(
            Cabecera.Origen,
            Lineas[iLinea].Sku);
          dDes := ARepositorio.ObtenerStock(
            Cabecera.Destino,
            Lineas[iLinea].Sku);
          // Reimpresion: el stock es el actual de cada almacen (puede haber
          // variado por movimientos posteriores), por eso "actual".
          ImprimirLineaSku(Ticket,
            Lineas[iLinea].Sku,
            Lineas[iLinea].Descripcion,
            STicketUnidades, dPed,
            STicketStockOrigenActual, dOrg,
            STicketStockDestinoActual, dDes);
          Inc(iLinea);
        end;
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
        Ticket.SaltarLineas(2);
        Ticket.CortarPapel;
        ComandosESC := Ticket.ObtenerComandos;
        sRefArch := StringReplace(sDocRef, '/', '_', [rfReplaceAll]);
        sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
        RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
        ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                     sImpresora, ASoloPDF);
        if Assigned(ARutasPDF) and FileExists(RutaPDF) then
          ARutasPDF.Add(RutaPDF);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  end;
end;

end.
