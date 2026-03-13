unit Backup.Types;

interface


uses
  System.Classes, System.Generics.Collections;

type
  TBackupOptions = record
    WithData: Boolean;              // Incluir datos o solo estructura
    WithTriggers: Boolean;          // Incluir triggers
    WithProcedures: Boolean;        // Incluir procedimientos
    WithFunctions: Boolean;         // Incluir funciones
    WithViews: Boolean;             // Incluir vistas
    DropTablesFirst: Boolean;       // Incluir DROP TABLE antes de CREATE
    UseTransactions: Boolean;       // Envolver en BEGIN/COMMIT
    ExtendedInsert: Boolean;      // << NUEVO: un INSERT con todos los VALUES
    ExtendedInsertRows: Integer;
  end;

  TColumnInfo = record  // O class, seg�n tu implementaci�n actual
    ColumnName: string;
    DataType: string;
    IsNullable: string;
    ColumnKey: string;
    Extra: string;
    ColumnDefault: string;
    CharMaxLength: string;
    ColumnComment: string;
  end;

  TTableInfo = class
    TableName: string;
    Columns: TList<TColumnInfo>;
    constructor Create;
    destructor Destroy; override;
  end;

  // Informaci�n de una columna dentro de un �ndice
  TIndexColumn = record
    ColumnName: string;
    SeqInIndex: Integer;
  end;

  // Informaci�n de un �ndice completo (contiene un array de TIndexColumn)
  TIndexInfo = record
    IndexName: string;
    IsPrimary: Boolean;
    IsUnique: Boolean;
    Columns: TArray<TIndexColumn>;
  end;

  // Informaci�n de un trigger
  TTriggerInfo = record
    TriggerName: string;
    EventManipulation: string; // ej. INSERT, UPDATE, DELETE
    ActionTiming: string;      // ej. BEFORE, AFTER
    ActionStatement: string;   // El cuerpo del trigger
    EventObjectTable: string;  // La tabla a la que pertenece
  end;

implementation

{ TTableInfo }

constructor TTableInfo.Create;
begin
  inherited Create;
  Columns := TList<TColumnInfo>.Create;
end;

destructor TTableInfo.Destroy;
begin
  Columns.Free;
  inherited Destroy;
end;

end.

implementation

end.
