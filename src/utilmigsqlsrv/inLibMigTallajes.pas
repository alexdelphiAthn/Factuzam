{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigTallajes                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.1.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los "tallajes" del legacy → conjuntos de tallas en destino.        }
{                                                                              }
{    Origen:                                                                   }
{      - `dbo.ocgrptal`     → cabecera del tallaje:                            }
{          NroTallaje, Descripcion, Abreviatura                                }
{          Ej: 1=GENERAL/GEN, 6=LETRAS/LET, 10=UNIFORMES/UNFOR, 99=UNICA/UNI   }
{      - `dbo.ocgrptalnor`  → detalle normalizado (preferido):                 }
{          NroTallaje, Talla, Columna                                          }
{          Una fila por (tallaje, talla) con su orden. v1.0 leia ocgrptal     }
{          con 30 columnas sparse ColTalla01..ColTalla30; ocgrptalnor es      }
{          la version 3FN y ordena mejor (sin asumir ancho fijo).             }
{                                                                              }
{    Destino:                                                                  }
{      - fza_atributos_conjuntos: una fila por tallaje                         }
{          NOMBRE_AC      = "T<NroTallaje> - <Descripcion>"                    }
{          NOMBRE_CORTO_AC= Abreviatura                                        }
{          ID_VAR_AC      = 'TC'                                               }
{          ID_VA_AC       = 'TAL'                                              }
{      - fza_atributos_conjuntos_det: una fila por talla en el tallaje         }
{          ID_AC_ACD = ID_AC del conjunto                                      }
{          ID_AV_ACD = ID_AV del valor de talla (lookup por AV=UPPER)         }
{          ORDEN_ACD = Columna * 10                                            }
{          ID_ATB_ACD = ID_ATB del atributo basico (si existe)                 }
{                                                                              }
{    Idempotente: si el conjunto ya existe (mismo NOMBRE_AC) se salta el      }
{    conjunto entero. El usuario puede borrar el conjunto y re-ejecutar.      }
{******************************************************************************}
unit inLibMigTallajes;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarTallajes(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// Lee el ID_AC de fza_atributos_conjuntos para (NOMBRE_AC,
// ID_VAR_AC='TC', ID_VA_AC='TAL'). Devuelve 0 si no existe.
function BuscarIdAC(Eng: IContextoMigracion; const sNombre: string): Integer;
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    q.SQL.Text   :=
      'SELECT ID_AC FROM fza_atributos_conjuntos ' +
      'WHERE NOMBRE_AC = :n AND ID_VAR_AC = ''TC'' ' +
      '  AND ID_VA_AC = ''TAL'' LIMIT 1';
    q.ParamByName('n').AsString := sNombre;
    q.Open;
    if q.IsEmpty then
      Result := 0
    else
      Result := q.FieldByName('ID_AC').AsInteger;
  finally
    q.Free;
  end;
end;

procedure InsertarCabecera(Eng: IContextoMigracion; const sNombre,
                            sCorto: string);
var qIns: TUniQuery;
begin
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   :=
      'INSERT INTO fza_atributos_conjuntos (' +
        'NOMBRE_AC, NOMBRE_CORTO_AC, ID_VAR_AC, ID_VA_AC, ' +
        'ESACTIVO_AC, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:n, :s, ''TC'', ''TAL'', ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('n').AsString := sNombre;
    qIns.ParamByName('s').AsString := sCorto;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
  finally
    qIns.Free;
  end;
end;

procedure InsertarDetalle(Eng: IContextoMigracion; iIdAc, iIdAv, iIdAtb,
                           iOrden: Integer);
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_atributos_conjuntos_det ' +
      'WHERE ID_AC_ACD = :c AND ID_AV_ACD = :v';
    qChk.ParamByName('c').AsInteger := iIdAc;
    qChk.ParamByName('v').AsInteger := iIdAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit;
    qChk.Close;

    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   :=
      'INSERT INTO fza_atributos_conjuntos_det (' +
        'ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, ID_ATB_ACD, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:c, :v, :o, :b, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('c').AsInteger := iIdAc;
    qIns.ParamByName('v').AsInteger := iIdAv;
    qIns.ParamByName('o').AsInteger := iOrden;
    if iIdAtb > 0 then
      qIns.ParamByName('b').AsInteger := iIdAtb
    else
      qIns.ParamByName('b').Clear;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

procedure MigrarTallajes(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  // Un JOIN entre ocgrptal (cabecera) y ocgrptalnor (detalle
  // normalizado). Ordenamos por NroTallaje y Columna para procesar
  // por bloques: cada cambio de NroTallaje arranca un conjunto nuevo,
  // y dentro del conjunto cada fila es una talla en orden.
  cSelectSrc =
    'SELECT t.NroTallaje, t.Descripcion, t.Abreviatura, ' +
    '       n.Talla, ISNULL(n.Columna, 0) AS Columna ' +
    'FROM dbo.ocgrptal t ' +
    'LEFT JOIN dbo.ocgrptalnor n ON n.NroTallaje = t.NroTallaje ' +
    'ORDER BY t.NroTallaje, n.Columna, n.Talla';
var
  qSrc:                       TUniQuery;
  iNroTallaje, iNroTallajeAnt: Integer;
  iIdAc:                       Integer;
  iIdAv, iIdAtb:               Integer;
  iCol:                        Integer;
  sNombre, sCorto, sNombreFmt: string;
  sTalla, sCodAtb:             string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocgrptal t ' +
      'LEFT JOIN dbo.ocgrptalnor n ON n.NroTallaje = t.NroTallaje'));
    qSrc.Open;
    iNroTallajeAnt := -1;
    iIdAc          := 0;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      iNroTallaje := qSrc.FieldByName('NroTallaje').AsInteger;

      // Cambio de tallaje → procesar cabecera nueva
      if iNroTallaje <> iNroTallajeAnt then
      begin
        iNroTallajeAnt := iNroTallaje;
        sNombre        := Trim(qSrc.FieldByName('Descripcion').AsString);
        sCorto         := Trim(qSrc.FieldByName('Abreviatura').AsString);
        if sNombre = '' then
          sNombre := Format('Tallaje %d', [iNroTallaje]);
        sNombreFmt := Format('T%d - %s', [iNroTallaje, sNombre]);
        iIdAc      := BuscarIdAC(Eng, sNombreFmt);
        if iIdAc = 0 then
        begin
          try
            InsertarCabecera(Eng, sNombreFmt, sCorto);
            Inc(Stats.Insertadas);
            iIdAc := BuscarIdAC(Eng, sNombreFmt);
          except
            on E: Exception do
            begin
              Inc(Stats.Errores);
              Eng.Registro.LogError('tallaje', IntToStr(iNroTallaje),
                           E.Message, sNombreFmt, '');
              iIdAc := 0;
            end;
          end;
        end
        else
        begin
          Inc(Stats.Saltadas);
          Eng.Registro.LogSalto('tallaje', IntToStr(iNroTallaje),
            'conjunto ya existe, anado solo los detalles que falten',
            sNombreFmt, '');
        end;
      end;

      // Detalle (fila de ocgrptalnor)
      if iIdAc > 0 then
      begin
        sTalla := Trim(qSrc.FieldByName('Talla').AsString);
        iCol   := qSrc.FieldByName('Columna').AsInteger;
        if sTalla <> '' then
        begin
          iIdAv := BuscarIdAV(Eng, 'TAL', UpperCase(sTalla));
          if iIdAv = 0 then
          begin
            Inc(Stats.Errores);
            Eng.Registro.LogError('tallaje_det', sTalla,
              'no esta en fza_atributos_valores',
              Format('NroTallaje=%d col=%d', [iNroTallaje, iCol]),
              'corre antes el catalogo de tallas');
          end
          else
          begin
            sCodAtb := NormalizarCodigoAtb(sTalla);
            iIdAtb  := BuscarIdATB(Eng, 'TAL', sCodAtb);
            try
              InsertarDetalle(Eng, iIdAc, iIdAv, iIdAtb, iCol * 10);
            except
              on E: Exception do
              begin
                Inc(Stats.Errores);
                Eng.Registro.LogError('tallaje_det', sTalla, E.Message,
                  Format('NroTallaje=%d ID_AC=%d', [iNroTallaje, iIdAc]),
                  '');
              end;
            end;
          end;
        end;
      end;

      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'tallajes',
    'Sistemas de tallas (tallajes)',
    'dbo.ocgrptal + ocgrptalnor → conjuntos de atributos',
    ['tallas_maestras'],
    MigrarTallajes);

end.
