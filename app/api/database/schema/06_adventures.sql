-- Schema: adventures
-- Retos outdoor propios y eventos de comunidad. La parte social no existia en
-- Notion (Adventures era de un solo usuario): es la extension de la app.

CREATE SCHEMA adventures;
GO

CREATE TABLE adventures.Adventure (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Adventure_Id DEFAULT NEWID(),
    OwnerUserId         UNIQUEIDENTIFIER NOT NULL,

    -- 'personal' es un reto propio; 'community' es un evento al que otros
    -- usuarios pueden sumarse. Nunca las dos cosas: si suma gente, es community.
    Kind                VARCHAR(10)      NOT NULL
        CONSTRAINT CK_Adventure_Kind CHECK (Kind IN ('personal', 'community')),

    Destination         VARCHAR(200)     NOT NULL,
    State               VARCHAR(20)      NOT NULL CONSTRAINT DF_Adventure_State DEFAULT 'in_planning'
        CONSTRAINT CK_Adventure_State CHECK (State IN (
            'in_planning', 'upcoming_challenge', 'completed'
        )),
    Difficulty          VARCHAR(10)      NOT NULL
        CONSTRAINT CK_Adventure_Difficulty CHECK (Difficulty IN (
            'easy', 'moderate', 'hard', 'extreme'
        )),
    DurationHours       DECIMAL(5,2)     NULL,
    VisitDate           DATE             NULL,

    -- Geodata real. En Notion `Pin` era un tipo nativo con lat/lon/place_id;
    -- aplanarlo a un string perdia la posibilidad de mapa y de distancia.
    LocationLabel       VARCHAR(200)     NULL,
    OriginLabel         VARCHAR(120)     NULL,
    CountryCode         CHAR(2)          NULL,
    Latitude            DECIMAL(9,6)     NULL,
    Longitude           DECIMAL(9,6)     NULL,
    PlaceId             VARCHAR(120)     NULL,

    -- Numerico, no texto: en Notion `msnm` guardaba el string "msnm 2884",
    -- con la etiqueta adentro del dato, y no se podia ordenar ni comparar.
    AltitudeMeters      DECIMAL(7,2)     NULL,

    -- Solo para eventos de comunidad. NULL = sin limite declarado.
    Capacity            INT              NULL,

    CreatedAt           DATETIME2        NOT NULL CONSTRAINT DF_Adventure_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Adventure PRIMARY KEY (Id),
    CONSTRAINT FK_Adventure_Owner FOREIGN KEY (OwnerUserId) REFERENCES core.[User](Id),
    CONSTRAINT CK_Adventure_CapacityOnlyCommunity
        CHECK (Capacity IS NULL OR Kind = 'community')
);
GO

-- Una aventura puede ser de varios tipos a la vez (hiking + trekking).
-- 'running' estaba en uso real y no figuraba en el registro documentado.
CREATE TABLE adventures.AdventureActivityType (
    AdventureId     UNIQUEIDENTIFIER NOT NULL,
    ActivityType    VARCHAR(20)      NOT NULL
        CONSTRAINT CK_AdventureActivityType_Type CHECK (ActivityType IN (
            'hiking', 'biking', 'alpinism', 'camping', 'canopy', 'speleology',
            'trekking', 'running'
        )),

    CONSTRAINT PK_AdventureActivityType PRIMARY KEY (AdventureId, ActivityType),
    CONSTRAINT FK_AdventureActivityType_Adventure
        FOREIGN KEY (AdventureId) REFERENCES adventures.Adventure(Id) ON DELETE CASCADE
);
GO

CREATE TABLE adventures.AdventureParticipant (
    AdventureId     UNIQUEIDENTIFIER NOT NULL,
    UserId          UNIQUEIDENTIFIER NOT NULL,
    RoleInEvent     VARCHAR(15)      NOT NULL CONSTRAINT DF_AdventureParticipant_Role DEFAULT 'confirmed'
        CONSTRAINT CK_AdventureParticipant_Role CHECK (RoleInEvent IN ('organizer', 'confirmed')),
    ConfirmedAt     DATETIME2        NOT NULL CONSTRAINT DF_AdventureParticipant_ConfirmedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_AdventureParticipant PRIMARY KEY (AdventureId, UserId),
    CONSTRAINT FK_AdventureParticipant_Adventure
        FOREIGN KEY (AdventureId) REFERENCES adventures.Adventure(Id) ON DELETE CASCADE,
    CONSTRAINT FK_AdventureParticipant_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

-- Una aventura completada puede haberse ejecutado como una sesion de entreno
-- (un trail, un 21K). Enlazarlas evita cargar el mismo esfuerzo dos veces.
CREATE TABLE adventures.AdventureSession (
    AdventureId         UNIQUEIDENTIFIER NOT NULL,
    TrainingSessionId   UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_AdventureSession PRIMARY KEY (AdventureId, TrainingSessionId),
    CONSTRAINT FK_AdventureSession_Adventure
        FOREIGN KEY (AdventureId) REFERENCES adventures.Adventure(Id) ON DELETE CASCADE,
    CONSTRAINT FK_AdventureSession_TrainingSession
        FOREIGN KEY (TrainingSessionId) REFERENCES training.TrainingSession(Id)
);
GO
