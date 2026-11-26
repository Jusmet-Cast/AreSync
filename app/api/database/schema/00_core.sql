-- Schema: core
-- Usuarios y el futuro modelo de supervision profesional (telesalud).
-- Ver decision documentada en DevCodex: pagina "FitCodex — App", seccion
-- "Intencion futura: supervision profesional / telesalud" (25 Nov 2026).

CREATE SCHEMA core;
GO

CREATE TABLE core.[User] (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_User_Id DEFAULT NEWID(),
    Email           VARCHAR(256)     NOT NULL,
    DisplayName     VARCHAR(120)     NOT NULL,

    -- 'patient' es el usuario comun (lo que hoy es el unico caso real).
    -- 'professional' habilita CareRelationship del lado profesional.
    Role            VARCHAR(20)      NOT NULL
        CONSTRAINT CK_User_Role CHECK (Role IN ('patient', 'professional')),

    -- Solo tiene sentido si Role = 'professional'. NULL en pacientes.
    ProfessionalSpecialty VARCHAR(30) NULL
        CONSTRAINT CK_User_Specialty CHECK (ProfessionalSpecialty IN (
            'physiotherapy', 'orthopedics', 'nutrition', 'medicine', 'coaching'
        )),

    -- Espejo de ExperienceLevel (Dart): base/constante/serio. Solo pacientes.
    ExperienceLevel VARCHAR(20)      NULL
        CONSTRAINT CK_User_ExperienceLevel CHECK (ExperienceLevel IN (
            'base', 'constante', 'serio'
        )),

    WeightUnit      VARCHAR(5)       NOT NULL CONSTRAINT DF_User_WeightUnit DEFAULT 'kg'
        CONSTRAINT CK_User_WeightUnit CHECK (WeightUnit IN ('kg', 'lb')),

    BirthDate       DATE             NULL,
    HeightCm        DECIMAL(5,1)     NULL,

    CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_User_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        NOT NULL CONSTRAINT DF_User_UpdatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_User PRIMARY KEY (Id),
    CONSTRAINT UQ_User_Email UNIQUE (Email)
);
GO

-- Un profesional supervisa a un paciente. N:N real: un paciente puede tener
-- varios profesionales (nutriologo + fisio), un profesional varios pacientes.
CREATE TABLE core.CareRelationship (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_CareRelationship_Id DEFAULT NEWID(),
    ProfessionalUserId  UNIQUEIDENTIFIER NOT NULL,
    PatientUserId       UNIQUEIDENTIFIER NOT NULL,
    Status              VARCHAR(10)      NOT NULL CONSTRAINT DF_CareRelationship_Status DEFAULT 'active'
        CONSTRAINT CK_CareRelationship_Status CHECK (Status IN ('active', 'paused')),
    CreatedAt           DATETIME2        NOT NULL CONSTRAINT DF_CareRelationship_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_CareRelationship PRIMARY KEY (Id),
    CONSTRAINT FK_CareRelationship_Professional FOREIGN KEY (ProfessionalUserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_CareRelationship_Patient FOREIGN KEY (PatientUserId) REFERENCES core.[User](Id),
    CONSTRAINT UQ_CareRelationship UNIQUE (ProfessionalUserId, PatientUserId)
);
GO

-- Que dominios supervisa este profesional para este paciente especifico.
-- N:N aparte porque un mismo vinculo puede cubrir varios dominios a la vez
-- (ej. un medico que supervisa 'medical' y 'training' tras una lesion).
CREATE TABLE core.CareRelationshipScope (
    CareRelationshipId  UNIQUEIDENTIFIER NOT NULL,
    Domain              VARCHAR(20)      NOT NULL
        CONSTRAINT CK_CareRelationshipScope_Domain CHECK (Domain IN (
            'training', 'nutrition', 'medical'
        )),

    CONSTRAINT PK_CareRelationshipScope PRIMARY KEY (CareRelationshipId, Domain),
    CONSTRAINT FK_CareRelationshipScope_CareRelationship
        FOREIGN KEY (CareRelationshipId) REFERENCES core.CareRelationship(Id) ON DELETE CASCADE
);
GO
