-- Schema: adherence
-- El ledger de cierre: una fila por dia y una por semana, con totales y
-- veredictos. El detalle por comida vive en nutrition.FoodLogEntry y el
-- detalle por ejercicio en training.ExerciseLog — aca nunca se repiten.

CREATE SCHEMA adherence;
GO

CREATE TABLE adherence.AdherenceEntry (
    Id                      UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_AdherenceEntry_Id DEFAULT NEWID(),
    UserId                  UNIQUEIDENTIFIER NOT NULL,
    ArcId                   UNIQUEIDENTIFIER NOT NULL,

    EntryType               VARCHAR(10)      NOT NULL
        CONSTRAINT CK_AdherenceEntry_EntryType CHECK (EntryType IN ('daily', 'weekly')),

    -- D{dia}S{semana}{ArcCode} para daily, S{semana}{ArcCode} para weekly.
    PeriodId                VARCHAR(20)      NULL,
    EntryDate               DATE             NOT NULL,

    -- Una fila daily apunta a la weekly de su semana. Autorreferencia dentro
    -- de la misma tabla: Weekly 1 : N Daily.
    WeekEntryId             UNIQUEIDENTIFIER NULL,

    DayType                 VARCHAR(20)      NULL
        CONSTRAINT CK_AdherenceEntry_DayType CHECK (DayType IN (
            'training', 'rest', 'active_recovery', 'event'
        )),

    -- Que tan completos llegaron los inputs. 'estimated' marca que NEAT y/o
    -- sueño se rellenaron con estimados: el veredicto sigue siendo util pero
    -- no se puede tratar como medicion.
    DataQuality             VARCHAR(10)      NOT NULL CONSTRAINT DF_AdherenceEntry_DataQuality DEFAULT 'complete'
        CONSTRAINT CK_AdherenceEntry_DataQuality CHECK (DataQuality IN (
            'complete', 'partial', 'estimated'
        )),

    -- Ingesta: totales del dia. En una fila weekly, promedio diario.
    IntakeKcal              INT              NULL,
    ProteinG                DECIMAL(6,2)     NULL,
    CarbsG                  DECIMAL(6,2)     NULL,
    FatG                    DECIMAL(6,2)     NULL,
    DaysOverFatCeiling      INT              NULL,
    DaysUnderProteinFloor   INT              NULL,

    -- Entreno: totales del periodo.
    Sessions                INT              NULL,
    Prs                     INT              NULL,
    TrainingLoad            DECIMAL(8,2)     NULL,
    ActiveKcal              INT              NULL,

    -- Gasto. RmrKcal sale de la TMR medida mas reciente (medical.DxaMeasurement),
    -- no de una formula generica.
    RmrKcal                 INT              NULL,
    NeatKcal                INT              NULL,

    -- 7 en una fila weekly, 1 en una daily: normaliza los totales del periodo
    -- a valores por dia.
    DayCount                AS (CASE WHEN EntryType = 'weekly' THEN 7 ELSE 1 END) PERSISTED,

    -- El 7.0 (y no 7) es deliberado: con enteros, 500 kcal activas de una
    -- semana se truncaban a 71 por dia en vez de 71.43, y ese resto se
    -- arrastraba al veredicto de balance.
    TdeeKcal                AS (CASE
                                    WHEN RmrKcal IS NULL THEN NULL
                                    ELSE CAST(RmrKcal + ISNULL(NeatKcal, 0)
                                         + ISNULL(ActiveKcal, 0) / (CASE WHEN EntryType = 'weekly' THEN 7.0 ELSE 1.0 END)
                                         AS DECIMAL(9,2))
                                END) PERSISTED,

    -- Recuperacion y cuerpo: solo en filas daily. El sueño es canonico aca y
    -- no en la telemetria de sesion (dos sesiones el mismo dia comparten noche).
    SleepHours              DECIMAL(4,2)     NULL,
    SleepScore              INT              NULL,
    SleepOnsetTime          TIME(0)          NULL,
    SleepEfficiencyPercent  DECIMAL(5,2)     NULL,
    DeepSleepPercent        DECIMAL(5,2)     NULL,
    NightAwakenings         INT              NULL,
    Steps                   INT              NULL,
    WeightKg                DECIMAL(6,2)     NULL,

    -- IAA: solo en filas weekly. 0-100 cada pilar, total = promedio 1:1:1:1.
    ScoreTraining           DECIMAL(5,2)     NULL,
    ScoreNutrition          DECIMAL(5,2)     NULL,
    ScoreTelemetry          DECIMAL(5,2)     NULL,
    ScorePr                 DECIMAL(5,2)     NULL,
    ScoreTotal              DECIMAL(5,2)     NULL,
    Flag                    VARCHAR(10)      NULL
        CONSTRAINT CK_AdherenceEntry_Flag CHECK (Flag IN ('green', 'yellow', 'orange', 'red')),

    FocusAreas              VARCHAR(MAX)     NULL,
    Notes                   VARCHAR(MAX)     NULL,
    CreatedAt               DATETIME2        NOT NULL CONSTRAINT DF_AdherenceEntry_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_AdherenceEntry PRIMARY KEY (Id),
    CONSTRAINT FK_AdherenceEntry_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_AdherenceEntry_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id),
    CONSTRAINT FK_AdherenceEntry_WeekEntry FOREIGN KEY (WeekEntryId) REFERENCES adherence.AdherenceEntry(Id),

    -- Un solo cierre por usuario, tipo y fecha: cerrar dos veces el mismo dia
    -- duplicaria los totales de la semana.
    CONSTRAINT UQ_AdherenceEntry_Period UNIQUE (UserId, EntryType, EntryDate),

    CONSTRAINT CK_AdherenceEntry_WeeklyHasNoWeekParent
        CHECK (NOT (EntryType = 'weekly' AND WeekEntryId IS NOT NULL))
);
GO

CREATE INDEX IX_AdherenceEntry_User_Date ON adherence.AdherenceEntry (UserId, EntryDate DESC);
GO

-- Que sesiones de entreno entraron en el cierre de ese dia/semana.
CREATE TABLE adherence.AdherenceSession (
    AdherenceEntryId    UNIQUEIDENTIFIER NOT NULL,
    TrainingSessionId   UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_AdherenceSession PRIMARY KEY (AdherenceEntryId, TrainingSessionId),
    CONSTRAINT FK_AdherenceSession_AdherenceEntry
        FOREIGN KEY (AdherenceEntryId) REFERENCES adherence.AdherenceEntry(Id) ON DELETE CASCADE,
    CONSTRAINT FK_AdherenceSession_TrainingSession
        FOREIGN KEY (TrainingSessionId) REFERENCES training.TrainingSession(Id)
);
GO

-- Balance energetico y veredicto. Es una vista y no columnas calculadas
-- porque `TargetFit` necesita el deficit de la fase vigente del arc — el
-- unico cruce multi-tabla real de todo el modelo.
CREATE VIEW adherence.AdherenceEntryBalance
AS
SELECT
    ae.Id,
    ae.UserId,
    ae.ArcId,
    ae.EntryType,
    ae.EntryDate,
    ae.TdeeKcal,
    ae.IntakeKcal - ae.TdeeKcal                          AS EnergyBalanceKcal,
    (ae.IntakeKcal - ae.TdeeKcal) * ae.DayCount          AS PeriodBalanceKcal,
    a.PhaseDeficitKcal                                   AS PhaseTargetKcal,

    CASE
        WHEN ae.IntakeKcal IS NULL OR ae.TdeeKcal IS NULL THEN NULL
        WHEN ae.IntakeKcal - ae.TdeeKcal < -750 THEN 'aggressive_deficit'
        WHEN ae.IntakeKcal - ae.TdeeKcal < -250 THEN 'deficit'
        WHEN ae.IntakeKcal - ae.TdeeKcal < -100 THEN 'mild_deficit'
        WHEN ae.IntakeKcal - ae.TdeeKcal <= 100 THEN 'maintenance'
        WHEN ae.IntakeKcal - ae.TdeeKcal <= 300 THEN 'lean_surplus'
        WHEN ae.IntakeKcal - ae.TdeeKcal <= 600 THEN 'surplus'
        ELSE 'aggressive_surplus'
    END                                                  AS BalanceVerdict,

    CASE
        WHEN ae.IntakeKcal IS NULL OR ae.TdeeKcal IS NULL OR a.PhaseDeficitKcal IS NULL THEN NULL
        WHEN ABS((ae.IntakeKcal - ae.TdeeKcal) - a.PhaseDeficitKcal) <= 150 THEN 'on_target'
        WHEN (ae.IntakeKcal - ae.TdeeKcal) - a.PhaseDeficitKcal < 0 THEN 'under_target'
        ELSE 'over_target'
    END                                                  AS TargetFit
FROM adherence.AdherenceEntry ae
INNER JOIN arcs.Arc a ON a.Id = ae.ArcId;
GO
