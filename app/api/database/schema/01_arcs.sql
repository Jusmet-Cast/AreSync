-- Schema: arcs
-- El Arc es la unidad de planificacion: todo lo demas (entreno, nutricion,
-- adherencia) cuelga de el. Espejo normalizado de "Routes of Arcs" en Notion
-- MAS todo lo que hoy vive suelto en el body de la pagina del arc activo
-- (fases, suplementacion, split, reglas, restricciones) — ver Spike B.

CREATE SCHEMA arcs;
GO

CREATE TABLE arcs.Arc (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Arc_Id DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    Name                VARCHAR(120)     NOT NULL,

    ArcType             VARCHAR(20)      NOT NULL
        CONSTRAINT CK_Arc_Type CHECK (ArcType IN (
            'recomp', 'bulk', 'cut', 'hybrid', 'endurance', 'mental'
        )),

    Status              VARCHAR(20)      NOT NULL CONSTRAINT DF_Arc_Status DEFAULT 'planned'
        CONSTRAINT CK_Arc_Status CHECK (Status IN ('planned', 'active', 'completed')),

    StartDate           DATE             NOT NULL,
    EndDate             DATE             NOT NULL,
    ShortDescription    VARCHAR(MAX)     NULL,

    InitialWeightKg     DECIMAL(6,2)     NULL,
    FinalWeightKg       DECIMAL(6,2)     NULL,

    -- Deficit (negativo) o superavit (positivo) de la FASE vigente, no del arc
    -- entero: cambia al cerrar cada fase. AdherenceEntry lo lee para Target Fit.
    PhaseDeficitKcal    INT              NULL,

    ProgressPercent     DECIMAL(5,2)     NULL,

    CreatedAt           DATETIME2        NOT NULL CONSTRAINT DF_Arc_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2        NOT NULL CONSTRAINT DF_Arc_UpdatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Arc PRIMARY KEY (Id),
    CONSTRAINT FK_Arc_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT CK_Arc_Dates CHECK (EndDate > StartDate)
);
GO

-- Un solo arc activo por usuario a la vez: el resto del sistema asume eso
-- (la app resuelve "el arc activo", en singular, en cada pantalla).
CREATE UNIQUE INDEX UX_Arc_OneActivePerUser
    ON arcs.Arc (UserId)
    WHERE Status = 'active';
GO

-- Metas del arc, una fila por meta en vez de ~12 columnas nullable.
-- Notion solo tenia "Meta X"; Baseline y Stretch existian unicamente en una
-- tabla dentro del body de la pagina (Spike B) — aca quedan tipados.
CREATE TABLE arcs.ArcGoal (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ArcGoal_Id DEFAULT NEWID(),
    ArcId           UNIQUEIDENTIFIER NOT NULL,
    GoalType        VARCHAR(30)      NOT NULL
        CONSTRAINT CK_ArcGoal_Type CHECK (GoalType IN (
            'weight_kg', 'body_fat_percent', 'lean_mass_kg', 'almi', 'vat_cm2',
            'protein_min_g', 'protein_max_g', 'steps', 'sleep_score',
            'sleep_onset', 'vo2_max', 'vitality_score'
        )),
    BaselineValue   DECIMAL(10,2)    NULL,
    TargetValue     DECIMAL(10,2)    NULL,
    StretchValue    DECIMAL(10,2)    NULL,

    -- Solo para metas que no son numericas puras (ej. sleep_onset = "00:00
    -- regular"): es un habito objetivo, no un instante.
    TargetText      VARCHAR(60)      NULL,

    CONSTRAINT PK_ArcGoal PRIMARY KEY (Id),
    CONSTRAINT FK_ArcGoal_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_ArcGoal UNIQUE (ArcId, GoalType)
);
GO

CREATE TABLE arcs.ArcPhase (
    Id                      UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ArcPhase_Id DEFAULT NEWID(),
    ArcId                   UNIQUEIDENTIFIER NOT NULL,
    PhaseNumber             INT              NOT NULL,
    Name                    VARCHAR(120)     NOT NULL,
    WeekStart               INT              NOT NULL,
    WeekEnd                 INT              NOT NULL,
    StartDate               DATE             NULL,
    EndDate                 DATE             NULL,
    DeficitKcal             INT              NULL,
    StepsGoal               INT              NULL,
    SleepGoalText           VARCHAR(60)      NULL,
    CardioSessionsPerWeek   INT              NULL,
    Status                  VARCHAR(20)      NOT NULL CONSTRAINT DF_ArcPhase_Status DEFAULT 'planned'
        CONSTRAINT CK_ArcPhase_Status CHECK (Status IN ('planned', 'active', 'closed')),

    CONSTRAINT PK_ArcPhase PRIMARY KEY (Id),
    CONSTRAINT FK_ArcPhase_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_ArcPhase UNIQUE (ArcId, PhaseNumber),
    CONSTRAINT CK_ArcPhase_Weeks CHECK (WeekEnd >= WeekStart)
);
GO

CREATE TABLE arcs.Supplement (
    Id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Supplement_Id DEFAULT NEWID(),
    ArcId       UNIQUEIDENTIFIER NOT NULL,
    Name        VARCHAR(120)     NOT NULL,
    Dose        VARCHAR(60)      NOT NULL,
    Reason      VARCHAR(500)     NULL,

    CONSTRAINT PK_Supplement PRIMARY KEY (Id),
    CONSTRAINT FK_Supplement_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE
);
GO

-- Asignacion dia -> tipo de sesion. Motion Studio modela el EJERCICIO por dia,
-- no el dia como unidad con un tipo de sesion propio; esa capa solo existia en
-- una tabla dentro del body del arc (Spike B).
CREATE TABLE arcs.SplitDay (
    Id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_SplitDay_Id DEFAULT NEWID(),
    ArcId       UNIQUEIDENTIFIER NOT NULL,
    DayOfWeek   VARCHAR(10)      NOT NULL
        CONSTRAINT CK_SplitDay_DayOfWeek CHECK (DayOfWeek IN (
            'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
        )),
    SessionType VARCHAR(30)      NOT NULL,
    Note        VARCHAR(300)     NULL,

    CONSTRAINT PK_SplitDay PRIMARY KEY (Id),
    CONSTRAINT FK_SplitDay_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_SplitDay UNIQUE (ArcId, DayOfWeek)
);
GO

-- Reglas no negociables del arc. `Priority` existe porque el orden importaba
-- explicitamente en el original ("regla #1, no la #7") y se perdia en una
-- migracion que las tratara como lista sin orden.
CREATE TABLE arcs.ArcRule (
    Id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ArcRule_Id DEFAULT NEWID(),
    ArcId       UNIQUEIDENTIFIER NOT NULL,
    Priority    INT              NOT NULL,
    RuleText    VARCHAR(500)     NOT NULL,

    CONSTRAINT PK_ArcRule PRIMARY KEY (Id),
    CONSTRAINT FK_ArcRule_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_ArcRule_Priority UNIQUE (ArcId, Priority)
);
GO

-- Lecciones del arc al cerrarlo. El flujo documentado en Notion las exige
-- ("Al cerrar el ARC, completa Lecciones") pero no existia ningun campo:
-- vivian como texto libre en el body (Spike C).
CREATE TABLE arcs.ArcLesson (
    Id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ArcLesson_Id DEFAULT NEWID(),
    ArcId       UNIQUEIDENTIFIER NOT NULL,
    LessonText  VARCHAR(MAX)     NOT NULL,
    CreatedAt   DATETIME2        NOT NULL CONSTRAINT DF_ArcLesson_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_ArcLesson PRIMARY KEY (Id),
    CONSTRAINT FK_ArcLesson_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id) ON DELETE CASCADE
);
GO

-- Historial de lesiones y restricciones biomecanicas. Cuelga del USUARIO, no
-- del arc: una luxacion de cadera de 2014 sigue siendo cierta en el arc #7.
-- Hoy era 100% prosa dentro de un callout del arc activo (Spike B).
CREATE TABLE arcs.BiomechanicalRestriction (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_BiomechanicalRestriction_Id DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    InjuryType          VARCHAR(120)     NOT NULL,
    Joint               VARCHAR(60)      NULL,
    OccurredOn          DATE             NULL,
    RestrictionText     VARCHAR(MAX)     NOT NULL,

    -- Si esta restriccion debe bloquear prescripciones automaticas del coach
    -- hasta que un profesional la revise (ver core.CareRelationship).
    RequiresSupervision BIT              NOT NULL CONSTRAINT DF_BiomechanicalRestriction_Supervision DEFAULT 0,

    CreatedAt           DATETIME2        NOT NULL CONSTRAINT DF_BiomechanicalRestriction_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_BiomechanicalRestriction PRIMARY KEY (Id),
    CONSTRAINT FK_BiomechanicalRestriction_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO
