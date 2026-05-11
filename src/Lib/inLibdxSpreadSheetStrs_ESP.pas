{******************************************************************************}
{                                                                              }
{  Módulo:       inLibdxSpreadSheetStrs_ESP                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traducción al castellano de los recursos de dxSpreadSheet.                }
{    Sobrescribe los textos de menús, diálogos y mensajes del componente.      }
{******************************************************************************}
unit inLibdxSpreadSheetStrs_ESP;

interface
  procedure ApplySpanishTranslation;
implementation

uses
  dxCore, cxClasses, dxSpreadSheetStrs;

procedure ApplySpanishTranslation;
begin
  // --- Menú Contextual (Popup Menu) ---
  cxSetResourceString(@sdxBuiltInPopupMenuBringToFront, 'Traer al &frente');
  cxSetResourceString(@sdxBuiltInPopupMenuClearContents, 'Borrar co&ntenido');
  cxSetResourceString(@sdxBuiltInPopupMenuCopy, '&Copiar');
  cxSetResourceString(@sdxBuiltInPopupMenuCustomizeObject, 'Perso&nalizar objeto...');
  cxSetResourceString(@sdxBuiltInPopupMenuCut, 'Cor&tar');
  cxSetResourceString(@sdxBuiltInPopupMenuDelete, '&Eliminar');
  cxSetResourceString(@sdxBuiltInPopupMenuDeleteDialog, '&Eliminar...');
  cxSetResourceString(@sdxBuiltInPopupMenuFormatCells, '&Formato de celdas...');
  cxSetResourceString(@sdxBuiltInPopupMenuHide, '&Ocultar');
  cxSetResourceString(@sdxBuiltInPopupMenuInsert, '&Insertar');
  cxSetResourceString(@sdxBuiltInPopupMenuInsertDialog, '&Insertar...');
  cxSetResourceString(@sdxBuiltInPopupMenuMergeCells, '&Combinar celdas');
  cxSetResourceString(@sdxBuiltInPopupMenuPaste, '&Pegar');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecial, 'Pegado especial');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialAll, '&Pegar todo');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialFormulas, '&Fórmulas');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialFormulasAndColumnWidths, 'Mantener anchos de columna de origen');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialFormulasAndFormatting, 'Fór&mulas y formato de números');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialFormulasAndStyles, '&Mantener formato de origen');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialShowDialog, 'Pegado especial...');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialValues, '&Valores');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialValuesAndFormatting, 'V&alores y formato de números');
  cxSetResourceString(@sdxBuiltInPopupMenuPasteSpecialValuesAndStyles, 'Valor&es y formato de origen');

  cxSetResourceString(@sdxBuiltInPopupMenuRename, '&Cambiar nombre...');
  cxSetResourceString(@sdxBuiltInPopupMenuSendToBack, 'Enviar al &fondo');
  cxSetResourceString(@sdxBuiltInPopupMenuSplitCells, 'Se&parar celdas');
  cxSetResourceString(@sdxBuiltInPopupMenuUnhide, '&Mostrar');
  cxSetResourceString(@sdxBuiltInPopupMenuUnhideDialog, '&Mostrar...');
  cxSetResourceString(@sdxBuiltInPopupMenuCreateHyperlink, '&Hipervínculo...');
  cxSetResourceString(@sdxBuiltInPopupMenuEditHyperlink, 'Editar &hipervínculo...');
  cxSetResourceString(@sdxBuiltInPopupMenuOpenHyperlink, '&Abrir hipervínculo');
  cxSetResourceString(@sdxBuiltInPopupMenuRemoveHyperlink, '&Quitar hipervínculo');
  cxSetResourceString(@sdxBuiltInPopupMenuDeleteComment, 'Eliminar co&mentario');
  cxSetResourceString(@sdxBuiltInPopupMenuEditComment, '&Editar comentario...');
  cxSetResourceString(@sdxBuiltInPopupMenuHideComment, '&Ocultar comentario');
  cxSetResourceString(@sdxBuiltInPopupMenuInsertComment, 'Insertar co&mentario...');
  cxSetResourceString(@sdxBuiltInPopupMenuShowComment, 'M&ostrar comentario');
  cxSetResourceString(@sdxBuiltInPopupMenuProtectSheet, '&Proteger hoja...');
  cxSetResourceString(@sdxBuiltInPopupMenuUnprotectSheet, 'Des&proteger hoja...');

  // --- Diálogo Renombrar Hoja ---
  cxSetResourceString(@sdxRenameDialogCaption, 'Cambiar nombre de la hoja');
  cxSetResourceString(@sdxRenameDialogSheetName, 'Nombre de la hoja:');

  // --- Diálogo de Archivos ---
  cxSetResourceString(@sdxFileDialogAllSupported, 'Todos los soportados');

  // --- Acciones (Actions) ---
  cxSetResourceString(@sdxActionAddGroup, 'Agrupar');
  cxSetResourceString(@sdxActionAutoFill, 'Autorrelleno');
  cxSetResourceString(@sdxActionCellEditing, 'Edición de celdas');
  cxSetResourceString(@sdxActionCellsMerge, 'Combinar celdas');
  cxSetResourceString(@sdxActionChangeConditionalFormatting, 'Cambiar formato condicional');
  cxSetResourceString(@sdxActionChangePrintingOptions, 'Cambiar opciones de impresión');
  cxSetResourceString(@sdxActionCreateDefinedName, 'Crear nombre definido');
  cxSetResourceString(@sdxActionChangeDefinedName, 'Cambiar nombre definido');
  cxSetResourceString(@sdxActionChangeContainer, 'Cambiar contenedor');
  cxSetResourceString(@sdxActionChangeGroup, 'Cambiar grupo');
  cxSetResourceString(@sdxActionChangeHyperlink, 'Cambiar hipervínculo');
  cxSetResourceString(@sdxActionChangeRowColumn, 'Cambiar Fila/Columna');
  cxSetResourceString(@sdxActionClearCells, 'Borrar celda(s)');
  cxSetResourceString(@sdxActionCutCells, 'Cortar celdas');
  cxSetResourceString(@sdxActionDeleteDefinedName, 'Eliminar nombre(s) definido(s)');
  cxSetResourceString(@sdxActionDeleteCells, 'Eliminar celdas');
  cxSetResourceString(@sdxActionDeleteComment, 'Eliminar comentario');
  cxSetResourceString(@sdxActionDeleteGroup, 'Desagrupar');
  cxSetResourceString(@sdxActionDragAndDrop, 'Arrastrar y soltar');
  cxSetResourceString(@sdxActionEditComment, 'Editar comentario');
  cxSetResourceString(@sdxActionExpandCollapseGroup, 'Mostrar/Ocultar detalles');
  cxSetResourceString(@sdxActionFillCells, 'Rellenar celdas');
  cxSetResourceString(@sdxActionFormatCells, 'Formato de celdas');
  cxSetResourceString(@sdxActionInsertCells, 'Insertar celdas');
  cxSetResourceString(@sdxActionMoveCells, 'Mover celdas');
  cxSetResourceString(@sdxActionPasteCells, 'Pegar celdas');
  cxSetResourceString(@sdxActionReplace, 'Reemplazar');
  cxSetResourceString(@sdxActionSortCells, 'Ordenar celdas');

  // --- Hipervínculos ---
  cxSetResourceString(@sdxDefaultHyperlinkScreenTip, '%s - Clic una vez para seguir.'#13#10'Clic y mantener para seleccionar esta celda.');
  cxSetResourceString(@sdxDefaultHyperlinkShortScreenTip, '%s - Clic una vez para seguir.');
  cxSetResourceString(@scxSelectionInDocument, '<< Selección en Documento >>');
  cxSetResourceString(@sdxHyperlinkExecuteError, '"%s" no se puede abrir.');

  // --- Portapapeles ---
  cxSetResourceString(@sdxClipboardFormatHTML, 'Formato HTML');
  cxSetResourceString(@sdxClipboardFormatImage, 'Imagen');
  cxSetResourceString(@sdxClipboardFormatText, 'Texto');

  // --- Impresión ---
  cxSetResourceString(@sdxSetSingleCellAsPrintAreaConfirmation,
    'Ha seleccionado una sola celda para el área de impresión.' + #13#10#13#10 +
    'Si esto es correcto, haga clic en Aceptar.' + #13#10 +
    'Si seleccionó una celda por error, haga clic en Cancelar, seleccione las celdas deseadas y vuelva a hacer clic en "Establecer área de impresión"');
  cxSetResourceString(@sdxCell, 'Celda: ');
  cxSetResourceString(@sdxComment, 'Comentario: ');

  // --- Barra de Fórmulas ---
  cxSetResourceString(@sdxFormulaBarCancelHint, 'Cancelar');
  cxSetResourceString(@sdxFormulaBarEnterHint, 'Introducir');
  cxSetResourceString(@sdxFormulaBarFormulaBarHint, 'Barra de fórmulas');
  cxSetResourceString(@sdxFormulaBarInsertFunctionHint, 'Insertar función');
  cxSetResourceString(@sdxFormulaBarNameBoxHint, 'Cuadro de nombres');
  cxSetResourceString(@sdxFormulaBarSelectionInfo, '%dF x %dC'); // Fila x Columna
end;

initialization
//  ApplySpanishTranslation;

end.
