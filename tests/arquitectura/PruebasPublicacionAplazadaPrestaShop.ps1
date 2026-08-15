param(
    [string]$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

function Exigir {
    param(
        [bool]$Condicion,
        [string]$Mensaje
    )
    if (-not $Condicion) {
        throw $Mensaje
    }
}

function Extraer-Bloque {
    param(
        [string]$Texto,
        [string]$Inicio,
        [string]$Fin
    )
    $posicionInicio = $Texto.LastIndexOf($Inicio)
    Exigir ($posicionInicio -ge 0) "No se encontro el inicio: $Inicio"
    $posicionFin = $Texto.IndexOf($Fin, $posicionInicio + $Inicio.Length)
    Exigir ($posicionFin -gt $posicionInicio) "No se encontro el fin: $Fin"
    return $Texto.Substring($posicionInicio, $posicionFin - $posicionInicio)
}

$rutaEncolado = Join-Path $Raiz 'src\DataModules\UniDataPrestaShopEncolado.pas'
$rutaArticulos = Join-Path $Raiz 'src\DataModules\UniDataArticulos.pas'
$rutaFormulario = Join-Path $Raiz 'src\Forms\inMtoArticulos.pas'
$encolado = Get-Content -LiteralPath $rutaEncolado -Raw
$articulos = Get-Content -LiteralPath $rutaArticulos -Raw
$formulario = Get-Content -LiteralPath $rutaFormulario -Raw

Exigir ($encolado.Contains(
    "CMarcaGuardadoArticuloPrestaShop = '[GUARDADO_ARTICULO] ';")) `
    'La marca persistente debe conservar el literal exacto de 20 caracteres'

$registro = Extraer-Bloque $encolado `
    'procedure RegistrarPublicacionAplazadaPrestaShop(' `
    'function ReanudarPublicacionAplazadaPrestaShop('
$posicionCall = $registro.IndexOf('EjecutarEncoladoVisibilidadPrestaShop(')
$posicionUpdate = $registro.IndexOf("'UPDATE fza_prestashop_cola SET '")
Exigir ($registro.Contains('bTransaccionPropia := not AConexion.InTransaction')) `
    'El registro debe respetar una transaccion ajena'
Exigir ($registro.Contains('AConexion.StartTransaction')) `
    'El registro debe abrir una transaccion propia cuando sea necesario'
Exigir ($registro.Contains('if not AAccionExplicita then')) `
    'Un reintento fallido debe distinguir si trae una nueva accion explicita'
Exigir ($registro.Contains("if sAccionAnterior = 'A' then")) `
    'Un segundo fallo debe conservar una activacion aplazada anterior'
Exigir ($registro.Contains(':MARCA FOR UPDATE')) `
    'La accion anterior debe leerse bloqueada en la misma transaccion'
Exigir (($posicionCall -ge 0) -and ($posicionCall -lt $posicionUpdate)) `
    'El CALL y el bloqueo ERROR deben ejecutarse en ese orden'
Exigir ($registro.Contains('oConsulta.RowsAffected <> 1')) `
    'El UPDATE exacto debe afectar una sola fila'
Exigir ($registro.Contains('CLAVE_INSTALACION_PSCOLA = :INSTALACION')) `
    'El UPDATE debe identificar la instalacion efectiva'
Exigir ($registro.Contains('ID_TIENDA_PSCOLA = :TIENDA')) `
    'El UPDATE debe identificar la tienda efectiva'
Exigir ($registro.Contains('CODIGO_ART_PSCOLA = :ARTICULO')) `
    'El UPDATE debe identificar el articulo'
Exigir (-not $registro.Contains('SolicitarProcesadoPrestaShop')) `
    'Registrar la incidencia no debe despertar al consumidor'

$reanudacion = Extraer-Bloque $encolado `
    'function ReanudarPublicacionAplazadaPrestaShop(' `
    'function LeerCodigoTarifaPrestaShop('
Exigir ($reanudacion.Contains(':MARCA FOR UPDATE')) `
    'La reanudacion debe bloquear la incidencia antes de leer su accion'
Exigir ($reanudacion.Contains("(sAccion <> 'A') and (sAccion <> 'N')")) `
    'Solo se pueden reanudar acciones A o N'
Exigir ($reanudacion.Contains('EjecutarEncoladoVisibilidadPrestaShop(')) `
    'La reanudacion debe pasar por el procedimiento de visibilidad'
Exigir ($reanudacion.Contains('if Result and bTransaccionPropia then')) `
    'La senal solo debe emitirse tras confirmar la transaccion propia'

$finalizacion = Extraer-Bloque $articulos `
    'procedure TdmArticulos.FinalizarVisibilidadPrestaShopAplazada(' `
    'procedure TdmArticulos.IniciarAplazamientoVisibilidadPrestaShop;'
$posicionReanudar = $finalizacion.IndexOf(
    'ReanudarPublicacionAplazadaPrestaShop(')
$posicionEncolarNormal = $finalizacion.IndexOf('EncolarArticuloPrestaShop(')
Exigir (($posicionReanudar -ge 0) -and
        ($posicionReanudar -lt $posicionEncolarNormal)) `
    'Un guardado completo debe reanudar antes de crear trabajo ordinario'
Exigir ($finalizacion.Contains('RegistrarPublicacionAplazadaPrestaShop(')) `
    'Un fallo con el articulo en web debe persistir la incidencia'
Exigir ($finalizacion.Contains('DescartarVisibilidadPrestaShopAplazada')) `
    'La finalizacion siempre debe limpiar el estado temporal'
Exigir ($articulos.Contains('else if FAplazarVisibilidadPrestaShop then')) `
    'AfterPost debe aplazar tambien el encolado ordinario de cabecera'
Exigir ($formulario.Contains(
    'dmmArticulos.FinalizarVisibilidadPrestaShopAplazada(')) `
    'El formulario debe finalizar el aplazamiento con el resultado completo'
Exigir ($formulario.Contains('Resultado.Error = egaNinguno')) `
    'El formulario debe comunicar el exito real de todas las fases'
Exigir ($formulario.Contains('Resultado.Mensaje);')) `
    'El formulario debe conservar el mensaje de la fase fallida'

Write-Output 'PUBLICACION_APLAZADA_PRESTASHOP=OK'
