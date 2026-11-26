-- Schema: coach
-- Lo que el coach le dijo al usuario y quien lo superviso.
--
-- Por que se persiste algo que es derivable: en un sistema donde un
-- profesional de salud supervisa, "que recomendo la IA el 12 de marzo y quien
-- lo valido" es el registro, no un detalle. Recalcular el IRA de hoy no
-- reconstruye lo que el paciente leyo hace tres meses.
--
-- NO incluye mensajeria profesional-paciente: esa feature tiene implicancias
-- de privacidad y alcance regulatorio sin evaluar, y modelarla ahora seria
-- adivinar. Queda declarada como pendiente en app/api/README.md.

CREATE SCHEMA coach;
GO

CREATE TABLE coach.AgentInsight (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_AgentInsight_Id DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    ArcId               UNIQUEIDENTIFIER NULL,

    -- Que agente lo produjo. VARCHAR y no CHECK cerrado: el roster de agentes
    -- vive en System/Agentes/*.md y cambia sin que la base tenga que migrar.
    AgentName           VARCHAR(40)      NOT NULL,

    InsightType         VARCHAR(20)      NOT NULL
        CONSTRAINT CK_AgentInsight_Type CHECK (InsightType IN (
            'recovery', 'training', 'nutrition', 'adherence'
        )),

    -- El texto tal como se le mostro al usuario. Es el registro de lo dicho:
    -- no se regenera ni se corrige despues, se emite uno nuevo.
    Recommendation      VARCHAR(MAX)     NOT NULL,

    -- Score principal del insight cuando lo tiene (IRA para recovery, IAA
    -- total para adherence). NULL para los que no puntuan.
    PrimaryScore        DECIMAL(5,2)     NULL,

    Severity            VARCHAR(10)      NOT NULL CONSTRAINT DF_AgentInsight_Severity DEFAULT 'info'
        CONSTRAINT CK_AgentInsight_Severity CHECK (Severity IN (
            'info', 'yellow', 'orange', 'red', 'critical'
        )),

    GeneratedAt         DATETIME2        NOT NULL CONSTRAINT DF_AgentInsight_GeneratedAt DEFAULT SYSUTCDATETIME(),

    -- Supervision profesional. Si RequiresReview = 1, la app no presenta el
    -- insight como indicacion hasta que un profesional lo revise: es la linea
    -- entre "companero 24/7" y "consejo medico sin supervision".
    RequiresReview      BIT              NOT NULL CONSTRAINT DF_AgentInsight_RequiresReview DEFAULT 0,
    ReviewedByUserId    UNIQUEIDENTIFIER NULL,
    ReviewedAt          DATETIME2        NULL,
    ReviewDecision      VARCHAR(15)      NULL
        CONSTRAINT CK_AgentInsight_ReviewDecision CHECK (ReviewDecision IN (
            'approved', 'modified', 'rejected'
        )),
    ReviewNote          VARCHAR(MAX)     NULL,

    CONSTRAINT PK_AgentInsight PRIMARY KEY (Id),
    CONSTRAINT FK_AgentInsight_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_AgentInsight_Arc FOREIGN KEY (ArcId) REFERENCES arcs.Arc(Id),
    CONSTRAINT FK_AgentInsight_Reviewer FOREIGN KEY (ReviewedByUserId) REFERENCES core.[User](Id),

    -- Una revision sin revisor, o un revisor sin fecha, es un registro de
    -- auditoria incompleto: no se acepta a medias.
    CONSTRAINT CK_AgentInsight_ReviewConsistency CHECK (
        (ReviewedByUserId IS NULL AND ReviewedAt IS NULL AND ReviewDecision IS NULL)
        OR (ReviewedByUserId IS NOT NULL AND ReviewedAt IS NOT NULL AND ReviewDecision IS NOT NULL)
    )
);
GO

CREATE INDEX IX_AgentInsight_User_GeneratedAt
    ON coach.AgentInsight (UserId, GeneratedAt DESC);
GO

-- Insights que esperan revision profesional. Es la cola de trabajo del
-- profesional, y conviene que sea barata de consultar.
CREATE INDEX IX_AgentInsight_PendingReview
    ON coach.AgentInsight (UserId, GeneratedAt DESC)
    WHERE RequiresReview = 1 AND ReviewedAt IS NULL;
GO

-- Alertas puntuales que acompañan a un insight (espejo de AgentFlag en Dart).
CREATE TABLE coach.AgentInsightFlag (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_AgentInsightFlag_Id DEFAULT NEWID(),
    AgentInsightId  UNIQUEIDENTIFIER NOT NULL,
    Severity        VARCHAR(10)      NOT NULL
        CONSTRAINT CK_AgentInsightFlag_Severity CHECK (Severity IN (
            'info', 'yellow', 'orange', 'red', 'critical'
        )),
    Description     VARCHAR(MAX)     NOT NULL,

    CONSTRAINT PK_AgentInsightFlag PRIMARY KEY (Id),
    CONSTRAINT FK_AgentInsightFlag_AgentInsight
        FOREIGN KEY (AgentInsightId) REFERENCES coach.AgentInsight(Id) ON DELETE CASCADE
);
GO
