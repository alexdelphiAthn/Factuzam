{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCatalogoPantallas                                        }
{    Tipo:       Core                                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Catálogo de pantallas: registra en inLibRegistroPantallas cada clase    }
{    de formulario y data module que fza_winforms puede abrir. Los            }
{    identificadores los verifica el compilador, así que un typo aquí no     }
{    compila (antes, un typo en la BBDD reventaba en runtime). Pantalla       }
{    nueva = añadir su unidad y su línea de registro aquí + fila en          }
{    fza_winforms; ComprobarRegistradas avisa en el arranque si faltan.       }
{******************************************************************************}
unit inMtoCatalogoPantallas;

interface

implementation

uses
  inLibRegistroPantallas,
  inMtoAlbaranes,
  inMtoAlbaranesCompra,
  inMtoAlmacenes,
  inMtoArticulos,
  inMtoAtributosBasicos,
  inMtoAtributosConjuntos,
  inMtoCajaArqueosHist,
  inMtoCajaFormasPago,
  inMtoCajaOperacionesHist,
  inMtoCajaPagosHist,
  inMtoCajaValesHist,
  inMtoClientes,
  inMtoComprasPlantillas,
  inMtoComprasSesiones,
  inMtoContadores,
  inMtoDepositosCliente,
  inMtoDevolucionesCompra,
  inMtoDocumentosTrabajo,
  inMtoEfectosCompra,
  inMtoEfectosVenta,
  inMtoEmpleados,
  inMtoEmpresas,
  inMtoFacturasNormal,
  inMtoFacturasCompra,
  inMtoFacturasSimplif,
  inMtoFamilias,
  inMtoFormasdePago,
  inMtoGeneradorProcesos,
  inMtoGrupos,
  inMtoInventarios,
  inMtoIvas,
  inMtoIvasGrupos,
  inMtoCajaMenu,
  inMtoMovimientosAlmacen,
  inMtoPaises,
  inMtoPedidos,
  inMtoPedidosCompra,
  inMtoPermisosArbol,
  inMtoPermisos,
  inMtoPropiedades,
  inMtoPropiedadesValores,
  inMtoProveedores,
  inMtoRemesasCompra,
  inMtoRemesasVenta,
  inMtoTarifas,
  inMtoTarifasCambios,
  inMtoUnidadesMedida,
  inMtoUsuarios,
  inMtoUsuariosPerfiles,
  inMtoVariaciones,
  inMtoVerifactuCola,
  inMtoVerifactuLog,
  UniDataAlbaranes,
  UniDataAlbaranesCompra,
  UniDataAlmacenes,
  UniDataArticulos,
  UniDataAtributosBasicos,
  UniDataAtributosConjuntos,
  UniDataCajaArqueosHist,
  UniDataCajaFormasPago,
  UniDataCajaOperacionesHist,
  UniDataCajaPagosHist,
  UniDataCajaValesHist,
  UniDataClientes,
  UniDataComprasSesiones,
  UniDataContadores,
  UniDataDepositosCliente,
  UniDataDevolucionesCompra,
  UniDataDocumentosTrabajo,
  UniDataEfectosCompra,
  UniDataEfectosVenta,
  UniDataEmpleados,
  UniDataEmpresas,
  UniDataFacturas,
  UniDataFacturasCompra,
  UniDataFamilias,
  UniDataFormasdePago,
  UniDataGeneradorProcesos,
  UniDataGrupos,
  UniDataInventarios,
  UniDataIvas,
  UniDataIvasGrupos,
  UniDataMovimientosAlmacen,
  UniDataPaises,
  UniDataPedidos,
  UniDataPedidosCompra,
  UniDataPermisosGrupo,
  UniDataPropiedades,
  UniDataPropiedadesValores,
  UniDataProveedores,
  UniDataRemesasCompra,
  UniDataRemesasVenta,
  UniDataTarifas,
  UniDataTarifasCambios,
  UniDataUnidadesMedida,
  UniDataUsuarios,
  UniDataUsuariosPerfiles,
  UniDataVariaciones,
  UniDataVerifactuCola,
  UniDataVerifactuLog;

initialization
  // Formularios (UNITF_WINF)
  RegistrarPantalla(TfrmMtoAlbaranes);
  RegistrarPantalla(TfrmMtoAlbaranesCompra);
  RegistrarPantalla(TfrmMtoAlmacenes);
  RegistrarPantalla(TfrmMtoArticulos);
  RegistrarPantalla(TfrmMtoAtributosBasicos);
  RegistrarPantalla(TfrmMtoAtributosConjuntos);
  RegistrarPantalla(TfrmMtoCajaArqueosHist);
  RegistrarPantalla(TfrmMtoCajaFormasPago);
  RegistrarPantalla(TfrmMtoCajaOperacionesHist);
  RegistrarPantalla(TfrmMtoCajaPagosHist);
  RegistrarPantalla(TfrmMtoCajaValesHist);
  RegistrarPantalla(TfrmMtoClientes);
  RegistrarPantalla(TfrmMtoComprasPlantillas);
  RegistrarPantalla(TfrmMtoComprasSesiones);
  RegistrarPantalla(TfrmMtoContadores);
  RegistrarPantalla(TfrmMtoDepositosCliente);
  RegistrarPantalla(TfrmMtoDevolucionesCompra);
  RegistrarPantalla(TfrmMtoDocumentosTrabajo);
  RegistrarPantalla(TfrmMtoEfectosCompra);
  RegistrarPantalla(TfrmMtoEfectosVenta);
  RegistrarPantalla(TfrmMtoEmpleados);
  RegistrarPantalla(TfrmMtoEmpresas);
  RegistrarPantalla(TfrmMtoFacturasNormal);
  RegistrarPantalla(TfrmMtoFacturasCompra);
  RegistrarPantalla(TfrmMtoFacturasSimplif);
  RegistrarPantalla(TfrmMtoFamilias);
  RegistrarPantalla(TfrmMtoFormasdePago);
  RegistrarPantalla(TfrmMtoGeneradorProcesos);
  RegistrarPantalla(TfrmMtoGrupos);
  RegistrarPantalla(TfrmMtoInventarios);
  RegistrarPantalla(TfrmMtoIvas);
  RegistrarPantalla(TfrmMtoIvasGrupos);
  RegistrarPantalla(TfrmMtoMenuCaja);
  RegistrarPantalla(TfrmMtoMovimientosAlmacen);
  RegistrarPantalla(TfrmMtoPaises);
  RegistrarPantalla(TfrmMtoPedidos);
  RegistrarPantalla(TfrmMtoPedidosCompra);
  RegistrarPantalla(TfrmMtoPermisosArbol);
  RegistrarPantalla(TfrmMtoPermisos);
  RegistrarPantalla(TfrmMtoPropiedades);
  RegistrarPantalla(TfrmMtoPropiedadesValores);
  RegistrarPantalla(TfrmMtoProveedores);
  RegistrarPantalla(TfrmMtoRemesasCompra);
  RegistrarPantalla(TfrmMtoRemesasVenta);
  RegistrarPantalla(TfrmMtoTarifas);
  RegistrarPantalla(TfrmMtoTarifasCambios);
  RegistrarPantalla(TfrmMtoUnidadesMedida);
  RegistrarPantalla(TfrmMtoUsuarios);
  RegistrarPantalla(TfrmMtoUsuariosPerfiles);
  RegistrarPantalla(TfrmMtoVariaciones);
  RegistrarPantalla(TfrmMtoVerifactuCola);
  RegistrarPantalla(TfrmMtoVerifactuLog);
  // Data modules (DATAMODULE_WINF)
  RegistrarDataModule(TdmAlbaranes);
  RegistrarDataModule(TdmAlbaranesCompra);
  RegistrarDataModule(TdmAlmacenes);
  RegistrarDataModule(TdmArticulos);
  RegistrarDataModule(TdmAtributosBasicos);
  RegistrarDataModule(TdmAtributosConjuntos);
  RegistrarDataModule(TdmCajaArqueosHist);
  RegistrarDataModule(TdmCajaFormasPago);
  RegistrarDataModule(TdmCajaOperacionesHist);
  RegistrarDataModule(TdmCajaPagosHist);
  RegistrarDataModule(TdmCajaValesHist);
  RegistrarDataModule(TdmClientes);
  RegistrarDataModule(TdmComprasSesiones);
  RegistrarDataModule(TdmContadores);
  RegistrarDataModule(TdmDepositosCliente);
  RegistrarDataModule(TdmDevolucionesCompra);
  RegistrarDataModule(TdmDocumentosTrabajo);
  RegistrarDataModule(TdmEfectosCompra);
  RegistrarDataModule(TdmEfectosVenta);
  RegistrarDataModule(TdmEmpleados);
  RegistrarDataModule(TdmEmpresas);
  RegistrarDataModule(TdmFacturas);
  RegistrarDataModule(TdmFacturasCompra);
  RegistrarDataModule(TdmFamilias);
  RegistrarDataModule(TdmFormasdePago);
  RegistrarDataModule(TdmGeneradorProcesos);
  RegistrarDataModule(TdmGrupos);
  RegistrarDataModule(TdmInventarios);
  RegistrarDataModule(TdmIvas);
  RegistrarDataModule(TdmIvasGrupos);
  RegistrarDataModule(TdmMovimientosAlmacen);
  RegistrarDataModule(TdmPaises);
  RegistrarDataModule(TdmPedidos);
  RegistrarDataModule(TdmPedidosCompra);
  RegistrarDataModule(TdmPermisosGrupo);
  RegistrarDataModule(TdmPropiedades);
  RegistrarDataModule(TdmPropiedadesValores);
  RegistrarDataModule(TdmProveedores);
  RegistrarDataModule(TdmRemesasCompra);
  RegistrarDataModule(TdmRemesasVenta);
  RegistrarDataModule(TdmTarifas);
  RegistrarDataModule(TdmTarifasCambios);
  RegistrarDataModule(TdmUnidadesMedida);
  RegistrarDataModule(TdmUsuarios);
  RegistrarDataModule(TdmUsuariosPerfiles);
  RegistrarDataModule(TdmVariaciones);
  RegistrarDataModule(TdmVerifactuCola);
  RegistrarDataModule(TdmVerifactuLog);

end.
