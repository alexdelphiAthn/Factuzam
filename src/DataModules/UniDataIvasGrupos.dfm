inherited dmIvasGrupos: TdmIvasGrupos
  OldCreateOrder = True
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas_grupos'
      
        '  (GRUPO_ZONA_IVA, DESCRIPCION_ZONA_IVA, ESIRPF_IMP_INCL_ZONA_IV' +
        'A, ESIVAAGRICOLA_ZONA_IVA, ESAPLICA_RE_ZONA_IVA, ESDEFAULT_ZONA_' +
        'IVA, PALABRA_REPORTS_ZONA_IVA, INSTANTEMODIF, INSTANTEALTA, USUA' +
        'RIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:GRUPO_ZONA_IVA, :DESCRIPCION_ZONA_IVA, :ESIRPF_IMP_INCL_ZONA' +
        '_IVA, :ESIVAAGRICOLA_ZONA_IVA, :ESAPLICA_RE_ZONA_IVA, :ESDEFAULT' +
        '_ZONA_IVA, :PALABRA_REPORTS_ZONA_IVA, :INSTANTEMODIF, :INSTANTEA' +
        'LTA, :USUARIOALTA, :USUARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_ivas_grupos'
      'WHERE'
      '  GRUPO_ZONA_IVA = :Old_GRUPO_ZONA_IVA')
    SQLUpdate.Strings = (
      'UPDATE fza_ivas_grupos'
      'SET'
      
        '  GRUPO_ZONA_IVA = :GRUPO_ZONA_IVA, DESCRIPCION_ZONA_IVA = :DESC' +
        'RIPCION_ZONA_IVA, ESIRPF_IMP_INCL_ZONA_IVA = :ESIRPF_IMP_INCL_ZO' +
        'NA_IVA, ESIVAAGRICOLA_ZONA_IVA = :ESIVAAGRICOLA_ZONA_IVA, ESAPLI' +
        'CA_RE_ZONA_IVA = :ESAPLICA_RE_ZONA_IVA, ESDEFAULT_ZONA_IVA = :ES' +
        'DEFAULT_ZONA_IVA, PALABRA_REPORTS_ZONA_IVA = :PALABRA_REPORTS_ZO' +
        'NA_IVA, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEALTA = :INSTANTE' +
        'ALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :USUARIOMODIF'
      'WHERE'
      '  GRUPO_ZONA_IVA = :Old_GRUPO_ZONA_IVA')
    SQLLock.Strings = (
      'SELECT * FROM fza_ivas_grupos'
      'WHERE'
      '  GRUPO_ZONA_IVA = :Old_GRUPO_ZONA_IVA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT GRUPO_ZONA_IVA, DESCRIPCION_ZONA_IVA, ESIRPF_IMP_INCL_ZON' +
        'A_IVA, ESIVAAGRICOLA_ZONA_IVA, ESAPLICA_RE_ZONA_IVA, ESDEFAULT_Z' +
        'ONA_IVA, PALABRA_REPORTS_ZONA_IVA, INSTANTEMODIF, INSTANTEALTA, ' +
        'USUARIOALTA, USUARIOMODIF FROM fza_ivas_grupos'
      'WHERE'
      '  GRUPO_ZONA_IVA = :GRUPO_ZONA_IVA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas_grupos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_ivas_grupos')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, :pUSUARIO_MODIF, @pcont); SELE' +
        'CT @pcont AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 8
    Top = 84
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO_MODIF'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pcont'
        ParamType = ptOutput
        Size = 20
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT'
  end
end
