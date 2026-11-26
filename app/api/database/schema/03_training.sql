-- Schema: training
-- Catalogo de ejercicios (Motion Studio) + bitacora real de sesiones
-- (TrainLog). La separacion importa: el catalogo es el PLAN mutable semana a
-- semana, la sesion es el HECHO inmutable de lo que paso ese dia.

CREATE SCHEMA training;
GO

CREATE TABLE training.Exercise (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Exercise_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,
    Name            VARCHAR(160)     NOT NULL,

    MainMuscle      VARCHAR(20)      NOT NULL
        CONSTRAINT CK_Exercise_MainMuscle CHECK (MainMuscle IN (
            'chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs', 'core', 'cardio'
        )),

    Description     VARCHAR(MAX)     NULL,
    ExampleVideoUrl VARCHAR(500)     NULL,

    -- Equivale al checkbox `Use` de Motion Studio: si esta en el split vigente.
    -- Un ejercicio que sale del split se desactiva, NUNCA se borra — su
    -- historial de PRs tiene que seguir existiendo.
    IsActive        BIT              NOT NULL CONSTRAINT DF_Exercise_IsActive DEFAULT 1,

    CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_Exercise_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Exercise PRIMARY KEY (Id),
    CONSTRAINT FK_Exercise_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

CREATE TABLE training.ExerciseComplementaryMuscle (
    ExerciseId  UNIQUEIDENTIFIER NOT NULL,
    Muscle      VARCHAR(30)      NOT NULL,

    CONSTRAINT PK_ExerciseComplementaryMuscle PRIMARY KEY (ExerciseId, Muscle),
    CONSTRAINT FK_ExerciseComplementaryMuscle_Exercise
        FOREIGN KEY (ExerciseId) REFERENCES training.Exercise(Id) ON DELETE CASCADE
);
GO

-- Dias de la semana asignados al ejercicio. Tabla y no enum de 6 opciones:
-- en Notion el select de `Day` no tenia Friday y ejercicios de viernes
-- quedaban mal etiquetados (bug confirmado en vivo, Spike A).
CREATE TABLE training.ExerciseDaySchedule (
    ExerciseId  UNIQUEIDENTIFIER NOT NULL,
    DayOfWeek   VARCHAR(10)      NOT NULL
        CONSTRAINT CK_ExerciseDaySchedule_DayOfWeek CHECK (DayOfWeek IN (
            'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
        )),

    CONSTRAINT PK_ExerciseDaySchedule PRIMARY KEY (ExerciseId, DayOfWeek),
    CONSTRAINT FK_ExerciseDaySchedule_Exercise
        FOREIGN KEY (ExerciseId) REFERENCES training.Exercise(Id) ON DELETE CASCADE
);
GO

-- Sustitutos validos para un ejercicio (mismo grupo muscular). Direccional:
-- que A acepte a B como sustituto no implica lo inverso.
CREATE TABLE training.ExerciseAlternative (
    ExerciseId              UNIQUEIDENTIFIER NOT NULL,
    AlternativeExerciseId   UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_ExerciseAlternative PRIMARY KEY (ExerciseId, AlternativeExerciseId),
    CONSTRAINT FK_ExerciseAlternative_Exercise
        FOREIGN KEY (ExerciseId) REFERENCES training.Exercise(Id),
    CONSTRAINT FK_ExerciseAlternative_Alternative
        FOREIGN KEY (AlternativeExerciseId) REFERENCES training.Exercise(Id),
    CONSTRAINT CK_ExerciseAlternative_NotSelf CHECK (ExerciseId <> AlternativeExerciseId)
);
GO

-- Prescripcion vigente: series y carga objetivo de esta semana. Mutable a
-- proposito (es bitacora semanal, no plan fijo). El historico real de lo que
-- se hizo vive en ExerciseLog, nunca aca.
CREATE TABLE training.ExercisePrescription (
    ExerciseId      UNIQUEIDENTIFIER NOT NULL,
    SeriesScheme    VARCHAR(40)      NULL,
    TargetWeight    VARCHAR(40)      NULL,
    UpdatedAt       DATETIME2        NOT NULL CONSTRAINT DF_ExercisePrescription_UpdatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_ExercisePrescription PRIMARY KEY (ExerciseId),
    CONSTRAINT FK_ExercisePrescription_Exercise
        FOREIGN KEY (ExerciseId) REFERENCES training.Exercise(Id) ON DELETE CASCADE
);
GO

CREATE TABLE training.TrainingSession (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_TrainingSession_Id DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    ArcId               UNIQUEIDENTIFIER NULL,
    SessionDate         DATE             NOT NULL,

    -- Campo unico para split y deporte: el sistema es agnostico a la
    -- disciplina (pesas, running, MMA, trail entran por la misma puerta).
    SessionType         VARCHAR(20)      NOT NULL
        CONSTRAINT CK_TrainingSession_SessionType CHECK (SessionType IN (
            'push', 'pull', 'legs', 'full_body', 'recovery', 'run', 'speed_work',
            'trail', 'walking', 'hiking', 'cycling', 'swimming', 'boxing',
            'kickboxing', 'muay_thai', 'bjj', 'mma', 'other'
        )),

    -- Identificador legible D{dia}S{semana}{ArcCode} (ej. D3S7WA26), derivado
    -- de la fecha de inicio del arc. Se guarda y no se calcula al vuelo para
    -- que una sesion siga siendo citable aunque el arc cambie de fechas.
    SessionIdentifier   VARCHAR(20)      NULL,

    Notes               VARCHAR(MAX)     NULL,
    CreatedAt           DATETIME2        NOT NULL CONSTRAINT DF_TrainingSession_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_TrainingSession PRIMARY KEY (Id),
    CONSTRAINT FK_TrainingSession_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_TrainingSession_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id)
);
GO

CREATE INDEX IX_TrainingSession_User_Date ON training.TrainingSession (UserId, SessionDate DESC);
GO

-- Telemetria de la sesion (lo que reporta el wearable). 1:1 con la sesion.
-- Sueño NO vive aca: es del DIA, no de la sesion, y se escribe una sola vez
-- en adherence.AdherenceEntry (dos sesiones el mismo dia comparten noche).
CREATE TABLE training.SessionTelemetry (
    TrainingSessionId   UNIQUEIDENTIFIER NOT NULL,
    DurationMin         INT              NULL,
    ActiveKcal          INT              NULL,
    TotalKcal           INT              NULL,
    AvgHr               INT              NULL,
    MaxHr               INT              NULL,
    TrainingLoad        DECIMAL(7,2)     NULL,
    AerobicTe           DECIMAL(4,2)     NULL,
    AnaerobicTe         DECIMAL(4,2)     NULL,
    RecoveryHours       DECIMAL(5,1)     NULL,
    DistanceKm          DECIMAL(7,3)     NULL,
    Steps               INT              NULL,
    PaceMinPerKm        DECIMAL(5,2)     NULL,
    CadenceSpm          INT              NULL,
    StrideCm            INT              NULL,

    -- Minutos en cada zona de frecuencia cardiaca.
    ZoneLightMin        INT              NULL,
    ZoneIntensiveMin    INT              NULL,
    ZoneAerobicMin      INT              NULL,
    ZoneAnaerobicMin    INT              NULL,
    ZoneVo2MaxMin       INT              NULL,

    CONSTRAINT PK_SessionTelemetry PRIMARY KEY (TrainingSessionId),
    CONSTRAINT FK_SessionTelemetry_TrainingSession
        FOREIGN KEY (TrainingSessionId) REFERENCES training.TrainingSession(Id) ON DELETE CASCADE
);
GO

-- Un registro por ejercicio por sesion, con el top set. Un PR no genera fila
-- aparte: marca EntryType = 'pr' sobre la misma fila (regla real del sistema).
CREATE TABLE training.ExerciseLog (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ExerciseLog_Id DEFAULT NEWID(),
    TrainingSessionId   UNIQUEIDENTIFIER NOT NULL,
    ExerciseId          UNIQUEIDENTIFIER NOT NULL,

    WeightKg            DECIMAL(6,2)     NULL,
    Reps                INT              NULL,

    -- 1RM = Carga x (1 + Reps/30). Columna calculada: que el motor la derive
    -- evita que cliente y backend lleguen a numeros distintos para la misma fila.
    EstimatedOneRmKg    AS (CASE WHEN WeightKg IS NULL OR Reps IS NULL THEN NULL
                               ELSE CAST(WeightKg * (1 + Reps / 30.0) AS DECIMAL(7,2)) END) PERSISTED,

    -- Con que unidad se midio la carga. Comparar un PR 'per_side' contra uno
    -- 'total' da un PR falso: por eso entra en la clave de comparacion.
    Unit                VARCHAR(15)      NOT NULL CONSTRAINT DF_ExerciseLog_Unit DEFAULT 'total'
        CONSTRAINT CK_ExerciseLog_Unit CHECK (Unit IN ('total', 'per_side', 'per_dumbbell')),

    EntryType           VARCHAR(10)      NOT NULL CONSTRAINT DF_ExerciseLog_EntryType DEFAULT 'exercise'
        CONSTRAINT CK_ExerciseLog_EntryType CHECK (EntryType IN ('exercise', 'pr')),

    LoadType            VARCHAR(15)      NOT NULL CONSTRAINT DF_ExerciseLog_LoadType DEFAULT 'added_load'
        CONSTRAINT CK_ExerciseLog_LoadType CHECK (LoadType IN (
            'added_load', 'bodyweight', 'volume', 'adjustment'
        )),

    -- Repeticiones en reserva del top set. Sin esto la progresion de la
    -- proxima sesion se calcula sobre aire.
    Rir                 INT              NULL,

    -- Que se hizo realmente si difirio del plan. Un swap documentado cuenta
    -- como sesion cumplida para la adherencia; uno saltado en silencio, no.
    SubstituteUsed      VARCHAR(160)     NULL,

    Notes               VARCHAR(MAX)     NULL,

    CONSTRAINT PK_ExerciseLog PRIMARY KEY (Id),
    CONSTRAINT FK_ExerciseLog_TrainingSession
        FOREIGN KEY (TrainingSessionId) REFERENCES training.TrainingSession(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ExerciseLog_Exercise FOREIGN KEY (ExerciseId) REFERENCES training.Exercise(Id),
    CONSTRAINT UQ_ExerciseLog_OnePerExercisePerSession UNIQUE (TrainingSessionId, ExerciseId),

    -- Un ajuste de equipo o de setup nunca es un PR.
    CONSTRAINT CK_ExerciseLog_AdjustmentIsNotPr
        CHECK (NOT (LoadType = 'adjustment' AND EntryType = 'pr'))
);
GO

-- La deteccion de PR compara contra el maximo historico del MISMO ejercicio y
-- la MISMA unidad. Este indice es el que sostiene esa consulta.
CREATE INDEX IX_ExerciseLog_PrLookup
    ON training.ExerciseLog (ExerciseId, Unit, EstimatedOneRmKg DESC);
GO
