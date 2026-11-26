-- Schema: telemetry
-- Landing de lo que escriben los wearables, antes de agregarse a una sesion
-- (training.SessionTelemetry) o a un cierre diario (adherence.AdherenceEntry).
--
-- Existe como tabla propia porque el dato crudo y el dato agregado tienen
-- vidas distintas: el telefono y la banda pueden reportar pasos el mismo dia,
-- y hay que poder decidir cual gana SIN haber perdido al que perdio.

CREATE SCHEMA telemetry;
GO

CREATE TABLE telemetry.MetricReading (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_MetricReading_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,

    -- Espejo de MetricType (Dart). Tipo cerrado: una metrica nueva se agrega
    -- aca y en el enum del cliente, nunca en uno solo de los dos.
    MetricType      VARCHAR(30)      NOT NULL
        CONSTRAINT CK_MetricReading_Type CHECK (MetricType IN (
            'sleep_duration', 'resting_heart_rate', 'heart_rate_variability',
            'steps', 'body_weight', 'body_fat_percentage', 'lean_mass'
        )),

    Value           DECIMAL(12,4)    NOT NULL,
    Unit            VARCHAR(20)      NOT NULL,
    RecordedAt      DATETIME2        NOT NULL,

    -- De donde salio. Sin esto no se puede resolver un duplicado ni
    -- explicarle al usuario de donde vino el numero.
    Source          VARCHAR(20)      NOT NULL
        CONSTRAINT CK_MetricReading_Source CHECK (Source IN (
            'apple_health', 'health_connect', 'manual', 'computed'
        )),

    -- 0..1. Confianza en ESTA lectura puntual, distinta de la precision
    -- general de la fuente (ej. una bioimpedancia mal hidratada).
    Confidence      DECIMAL(3,2)     NOT NULL CONSTRAINT DF_MetricReading_Confidence DEFAULT 1.0
        CONSTRAINT CK_MetricReading_Confidence CHECK (Confidence BETWEEN 0 AND 1),

    -- Id de la lectura en la plataforma origen, para no reimportar lo mismo
    -- en cada sincronizacion.
    ExternalId      VARCHAR(200)     NULL,

    IngestedAt      DATETIME2        NOT NULL CONSTRAINT DF_MetricReading_IngestedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_MetricReading PRIMARY KEY (Id),
    CONSTRAINT FK_MetricReading_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

CREATE INDEX IX_MetricReading_User_Type_RecordedAt
    ON telemetry.MetricReading (UserId, MetricType, RecordedAt DESC);
GO

-- Evita reimportar la misma lectura cuando la sincronizacion se corre dos veces.
CREATE UNIQUE INDEX UX_MetricReading_ExternalId
    ON telemetry.MetricReading (UserId, Source, ExternalId)
    WHERE ExternalId IS NOT NULL;
GO

-- Que fuentes conecto cada usuario y hasta cuando se sincronizo cada una.
CREATE TABLE telemetry.ConnectedSource (
    UserId          UNIQUEIDENTIFIER NOT NULL,
    Source          VARCHAR(20)      NOT NULL
        CONSTRAINT CK_ConnectedSource_Source CHECK (Source IN (
            'apple_health', 'health_connect', 'manual', 'computed'
        )),
    IsEnabled       BIT              NOT NULL CONSTRAINT DF_ConnectedSource_IsEnabled DEFAULT 1,
    LastSyncedAt    DATETIME2        NULL,

    CONSTRAINT PK_ConnectedSource PRIMARY KEY (UserId, Source),
    CONSTRAINT FK_ConnectedSource_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

-- Que metricas publica REALMENTE esa fuente en el dispositivo del usuario.
-- No es lo que el SDK soporta en teoria: es lo que el wearable escribe. De
-- aca sale el hueco que la pantalla de telemetria muestra sin disimular
-- (ej. la Xiaomi global no publica HRV).
CREATE TABLE telemetry.SourceAvailableMetric (
    UserId      UNIQUEIDENTIFIER NOT NULL,
    Source      VARCHAR(20)      NOT NULL,
    MetricType  VARCHAR(30)      NOT NULL
        CONSTRAINT CK_SourceAvailableMetric_Type CHECK (MetricType IN (
            'sleep_duration', 'resting_heart_rate', 'heart_rate_variability',
            'steps', 'body_weight', 'body_fat_percentage', 'lean_mass'
        )),

    CONSTRAINT PK_SourceAvailableMetric PRIMARY KEY (UserId, Source, MetricType),
    CONSTRAINT FK_SourceAvailableMetric_ConnectedSource
        FOREIGN KEY (UserId, Source) REFERENCES telemetry.ConnectedSource(UserId, Source) ON DELETE CASCADE
);
GO
