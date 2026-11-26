-- Schema: medical
-- Composicion corporal y registros clinicos. Espejo normalizado de MedLog.
--
-- Decision de diseno (25 Nov 2026): NO se usa un payload JSON pese a que cada
-- metodo llena un subconjunto DISJUNTO de campos (DXA llena ~20, Navy ~8,
-- estimado visual ~2). Estos datos los va a leer un profesional de salud y
-- tienen que ser consultables, validables y auditables columna por columna.
-- La solucion es una tabla hija por metodo, cada una fuertemente tipada.
--
-- Bug real que esto corrige: en Notion, MedLog.Arc es un `select` de texto
-- libre, no una relation — renombrar un arc rompia el vinculo historico en
-- silencio. Aca es una FK de verdad.

CREATE SCHEMA medical;
GO

-- Centro, equipo y profesional que realizo el estudio. En Notion era un solo
-- rich_text que mezclaba las cuatro cosas en un string.
CREATE TABLE medical.Provider (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Provider_Id DEFAULT NEWID(),
    Name            VARCHAR(200)     NOT NULL,
    Location        VARCHAR(200)     NULL,
    PractitionerName VARCHAR(200)    NULL,
    EquipmentModel  VARCHAR(200)     NULL,
    SoftwareVersion VARCHAR(100)     NULL,

    CONSTRAINT PK_Provider PRIMARY KEY (Id)
);
GO

CREATE TABLE medical.MedLogEntry (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_MedLogEntry_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,

    -- FK real al arc, no el nombre del arc como texto.
    ArcId           UNIQUEIDENTIFIER NULL,

    RecordType      VARCHAR(30)      NOT NULL
        CONSTRAINT CK_MedLogEntry_RecordType CHECK (RecordType IN (
            'dxa', 'anthropometry', 'lab', 'medical_checkup', 'wearable'
        )),

    -- Determina cual de las tablas hijas tiene la fila correspondiente.
    Method          VARCHAR(30)      NOT NULL
        CONSTRAINT CK_MedLogEntry_Method CHECK (Method IN (
            'dxa_hologic', 'navy', 'bioimpedance', 'caliper', 'visual_estimate'
        )),

    ProviderId      UNIQUEIDENTIFIER NULL,
    ExamDate        DATE             NOT NULL,

    -- Interpretacion clinica narrativa (hallazgos, contexto). Texto, no JSON:
    -- es prosa genuina, no estructura disfrazada.
    ClinicalNotes   VARCHAR(MAX)     NULL,

    -- Resultado adjunto (PDF del laboratorio). Se guarda la referencia al
    -- blob, nunca el binario en la fila.
    AttachmentUrl   VARCHAR(500)     NULL,

    -- Si un profesional ya reviso esta entrada (ver core.CareRelationship).
    ReviewedByUserId UNIQUEIDENTIFIER NULL,
    ReviewedAt      DATETIME2        NULL,

    CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_MedLogEntry_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_MedLogEntry PRIMARY KEY (Id),
    CONSTRAINT FK_MedLogEntry_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_MedLogEntry_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id),
    CONSTRAINT FK_MedLogEntry_Provider FOREIGN KEY (ProviderId) REFERENCES medical.Provider(Id),
    CONSTRAINT FK_MedLogEntry_Reviewer FOREIGN KEY (ReviewedByUserId) REFERENCES core.[User](Id)
);
GO

CREATE INDEX IX_MedLogEntry_User_ExamDate ON medical.MedLogEntry (UserId, ExamDate DESC);
GO

-- DXA: el metodo mas completo. 1:1 con su MedLogEntry.
CREATE TABLE medical.DxaMeasurement (
    MedLogEntryId       UNIQUEIDENTIFIER NOT NULL,

    WeightKg            DECIMAL(6,2)     NULL,
    Bmi                 DECIMAL(5,2)     NULL,
    BodyFatPercent      DECIMAL(5,2)     NULL,
    FatMassKg           DECIMAL(6,2)     NULL,
    FatFreeMassKg       DECIMAL(6,2)     NULL,
    LeanMassKg          DECIMAL(6,2)     NULL,
    Almi                DECIMAL(5,2)     NULL,
    Ffmi                DECIMAL(5,2)     NULL,
    BoneMineralContentKg DECIMAL(6,3)    NULL,
    BoneMineralDensity  DECIMAL(5,3)     NULL,
    BoneDensityZScore   DECIMAL(4,2)     NULL,
    VatCm2              DECIMAL(6,2)     NULL,
    VatVolumeCm3        DECIMAL(8,2)     NULL,
    AndroidGynoidRatio  DECIMAL(5,3)     NULL,
    TrunkLegRatio       DECIMAL(5,3)     NULL,
    LegAsymmetryPercent DECIMAL(5,2)     NULL,
    ArmFatPercent       DECIMAL(5,2)     NULL,
    LegFatPercent       DECIMAL(5,2)     NULL,
    TrunkFatPercent     DECIMAL(5,2)     NULL,

    -- TMR medida por el equipo. Es la fuente de RMR para el balance energetico
    -- (adherence.AdherenceEntry): nunca se estima con Mifflin si existe esta.
    MeasuredRmrKcal     INT              NULL,
    MuscleStrength      DECIMAL(6,2)     NULL,

    CONSTRAINT PK_DxaMeasurement PRIMARY KEY (MedLogEntryId),
    CONSTRAINT FK_DxaMeasurement_MedLogEntry
        FOREIGN KEY (MedLogEntryId) REFERENCES medical.MedLogEntry(Id) ON DELETE CASCADE
);
GO

-- Navy Method: pocas columnas derivadas, pero con lecturas crudas y metodo.
-- Esas lecturas existian solo como prosa dentro del campo Notas (Spike B/C).
CREATE TABLE medical.NavyMeasurement (
    MedLogEntryId   UNIQUEIDENTIFIER NOT NULL,

    WeightKg        DECIMAL(6,2)     NULL,
    HeightCm        DECIMAL(5,1)     NULL,
    BodyFatPercent  DECIMAL(5,2)     NULL,
    FatMassKg       DECIMAL(6,2)     NULL,
    FatFreeMassKg   DECIMAL(6,2)     NULL,

    -- Promedios usados en la formula.
    NeckCm          DECIMAL(5,2)     NULL,
    WaistCm         DECIMAL(5,2)     NULL,
    HipCm           DECIMAL(5,2)     NULL,

    FormulaVersion  VARCHAR(60)      NULL,

    -- Margen de error declarado contra DXA (±3-4 puntos). Se guarda porque es
    -- lo que impide comparar un Navy contra un DXA y sacar una conclusion
    -- falsa: Navy se compara contra Navy.
    ErrorMarginNote VARCHAR(300)     NULL,

    CONSTRAINT PK_NavyMeasurement PRIMARY KEY (MedLogEntryId),
    CONSTRAINT FK_NavyMeasurement_MedLogEntry
        FOREIGN KEY (MedLogEntryId) REFERENCES medical.MedLogEntry(Id) ON DELETE CASCADE
);
GO

-- Cada lectura individual de circunferencia, con su serie. Sin esto se pierde
-- la trazabilidad de COMO se llego al promedio que alimenta la formula.
CREATE TABLE medical.AnthropometricReading (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_AnthropometricReading_Id DEFAULT NEWID(),
    MedLogEntryId   UNIQUEIDENTIFIER NOT NULL,
    Site            VARCHAR(30)      NOT NULL
        CONSTRAINT CK_AnthropometricReading_Site CHECK (Site IN (
            'neck', 'waist', 'hip', 'chest', 'arm', 'thigh', 'calf'
        )),
    SeriesNumber    INT              NOT NULL CONSTRAINT DF_AnthropometricReading_Series DEFAULT 1,
    ReadingNumber   INT              NOT NULL,
    ValueCm         DECIMAL(5,2)     NOT NULL,

    CONSTRAINT PK_AnthropometricReading PRIMARY KEY (Id),
    CONSTRAINT FK_AnthropometricReading_MedLogEntry
        FOREIGN KEY (MedLogEntryId) REFERENCES medical.MedLogEntry(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_AnthropometricReading UNIQUE (MedLogEntryId, Site, SeriesNumber, ReadingNumber)
);
GO

-- Estimado visual / bioimpedancia de bascula: casi todo vacio a proposito.
-- `PendingNote` es el campo donde el sistema declara que falta medir para
-- poder calcular el resto, en vez de dejar un hueco mudo.
CREATE TABLE medical.EstimateMeasurement (
    MedLogEntryId   UNIQUEIDENTIFIER NOT NULL,
    WeightKg        DECIMAL(6,2)     NULL,
    HeightCm        DECIMAL(5,1)     NULL,
    BodyFatPercent  DECIMAL(5,2)     NULL,
    PendingNote     VARCHAR(500)     NULL,

    CONSTRAINT PK_EstimateMeasurement PRIMARY KEY (MedLogEntryId),
    CONSTRAINT FK_EstimateMeasurement_MedLogEntry
        FOREIGN KEY (MedLogEntryId) REFERENCES medical.MedLogEntry(Id) ON DELETE CASCADE
);
GO
