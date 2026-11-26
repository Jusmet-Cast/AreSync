-- Schema: nutrition
-- Recetario (NutriCore), inventario de alacena (Essentials Hub), log de
-- comidas (FoodLog) y el resultado de estimar macros desde una foto.

CREATE SCHEMA nutrition;
GO

CREATE TABLE nutrition.Recipe (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Recipe_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,
    Name            VARCHAR(200)     NOT NULL,
    Category        VARCHAR(20)      NOT NULL
        CONSTRAINT CK_Recipe_Category CHECK (Category IN (
            'breakfast', 'lunch', 'dinner', 'snack', 'dessert'
        )),
    ProteinG        DECIMAL(6,2)     NULL,
    CarbsG          DECIMAL(6,2)     NULL,
    FatG            DECIMAL(6,2)     NULL,
    Calories        INT              NULL,
    PrepTime        VARCHAR(15)      NULL
        CONSTRAINT CK_Recipe_PrepTime CHECK (PrepTime IN (
            'under_15', '15_to_30', '30_to_60', 'over_60'
        )),
    SourceUrl       VARCHAR(500)     NULL,

    CONSTRAINT PK_Recipe PRIMARY KEY (Id),
    CONSTRAINT FK_Recipe_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

CREATE TABLE nutrition.PantryItem (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PantryItem_Id DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    Name                VARCHAR(160)     NOT NULL,
    StockLevel          VARCHAR(10)      NOT NULL CONSTRAINT DF_PantryItem_StockLevel DEFAULT 'empty'
        CONSTRAINT CK_PantryItem_StockLevel CHECK (StockLevel IN ('empty', 'low', 'half', 'full')),
    ConsumptionPriority VARCHAR(10)      NULL
        CONSTRAINT CK_PantryItem_Priority CHECK (ConsumptionPriority IN ('high', 'medium', 'low')),
    Brand               VARCHAR(120)     NULL,
    Store               VARCHAR(120)     NULL,
    Price               DECIMAL(10,2)    NULL,
    UpdatedAt           DATETIME2        NOT NULL CONSTRAINT DF_PantryItem_UpdatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_PantryItem PRIMARY KEY (Id),
    CONSTRAINT FK_PantryItem_User FOREIGN KEY (UserId) REFERENCES core.[User](Id)
);
GO

-- Un item puede pertenecer a varias categorias (era multi_select en Notion).
CREATE TABLE nutrition.PantryItemCategory (
    PantryItemId    UNIQUEIDENTIFIER NOT NULL,
    Category        VARCHAR(20)      NOT NULL
        CONSTRAINT CK_PantryItemCategory_Category CHECK (Category IN (
            'fruits', 'vegetables', 'meats', 'dairy', 'grains', 'protein',
            'supplements', 'snacks', 'legumes', 'liquid_boost'
        )),

    CONSTRAINT PK_PantryItemCategory PRIMARY KEY (PantryItemId, Category),
    CONSTRAINT FK_PantryItemCategory_PantryItem
        FOREIGN KEY (PantryItemId) REFERENCES nutrition.PantryItem(Id) ON DELETE CASCADE
);
GO

CREATE TABLE nutrition.FoodLogEntry (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_FoodLogEntry_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,
    LogDate         DATE             NOT NULL,
    Name            VARCHAR(200)     NOT NULL,
    Category        VARCHAR(20)      NOT NULL
        CONSTRAINT CK_FoodLogEntry_Category CHECK (Category IN (
            'breakfast', 'lunch', 'dinner', 'snack'
        )),

    ProteinG        DECIMAL(6,2)     NOT NULL CONSTRAINT DF_FoodLogEntry_ProteinG DEFAULT 0,
    CarbsG          DECIMAL(6,2)     NOT NULL CONSTRAINT DF_FoodLogEntry_CarbsG DEFAULT 0,
    FatG            DECIMAL(6,2)     NOT NULL CONSTRAINT DF_FoodLogEntry_FatG DEFAULT 0,
    Calories        INT              NOT NULL CONSTRAINT DF_FoodLogEntry_Calories DEFAULT 0,

    -- Cuanto se confia en estos macros. Un plato pesado en balanza y uno
    -- estimado de una foto no valen lo mismo, y el usuario tiene que verlo.
    Confidence      VARCHAR(10)      NOT NULL CONSTRAINT DF_FoodLogEntry_Confidence DEFAULT 'medium'
        CONSTRAINT CK_FoodLogEntry_Confidence CHECK (Confidence IN ('high', 'medium', 'low')),

    WithinPlan      BIT              NOT NULL CONSTRAINT DF_FoodLogEntry_WithinPlan DEFAULT 1,
    RecipeId        UNIQUEIDENTIFIER NULL,
    Notes           VARCHAR(MAX)     NULL,
    CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_FoodLogEntry_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_FoodLogEntry PRIMARY KEY (Id),
    CONSTRAINT FK_FoodLogEntry_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_FoodLogEntry_Recipe FOREIGN KEY (RecipeId) REFERENCES nutrition.Recipe(Id)
);
GO

CREATE INDEX IX_FoodLogEntry_User_Date ON nutrition.FoodLogEntry (UserId, LogDate DESC);
GO

-- Resultado de pasarle una foto al proveedor de vision (Gemini/DeepSeek).
-- Se guarda aparte del FoodLogEntry porque una estimacion puede existir sin
-- haberse confirmado todavia: el usuario revisa el desglose antes de aceptar.
CREATE TABLE nutrition.MealPhotoEstimate (
    Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_MealPhotoEstimate_Id DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,
    FoodLogEntryId  UNIQUEIDENTIFIER NULL,
    ImageUrl        VARCHAR(500)     NULL,
    Confidence      VARCHAR(10)      NOT NULL
        CONSTRAINT CK_MealPhotoEstimate_Confidence CHECK (Confidence IN ('high', 'medium', 'low')),

    -- Proveedor y modelo que produjo la estimacion. Sin esto no se puede
    -- auditar una estimacion vieja cuando el proveedor cambia de modelo.
    VisionProvider  VARCHAR(40)      NULL,
    ModelVersion    VARCHAR(60)      NULL,

    MethodNote      VARCHAR(MAX)     NULL,
    CreatedAt       DATETIME2        NOT NULL CONSTRAINT DF_MealPhotoEstimate_CreatedAt DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_MealPhotoEstimate PRIMARY KEY (Id),
    CONSTRAINT FK_MealPhotoEstimate_User FOREIGN KEY (UserId) REFERENCES core.[User](Id),
    CONSTRAINT FK_MealPhotoEstimate_FoodLogEntry
        FOREIGN KEY (FoodLogEntryId) REFERENCES nutrition.FoodLogEntry(Id)
);
GO

-- Desglose por componente detectado. Mostrar el detalle, y no solo el total,
-- es lo que permite corregir un ingrediente mal leido sin descartar toda la
-- estimacion.
CREATE TABLE nutrition.MealPhotoComponent (
    Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_MealPhotoComponent_Id DEFAULT NEWID(),
    MealPhotoEstimateId UNIQUEIDENTIFIER NOT NULL,
    Name                VARCHAR(200)     NOT NULL,
    ProteinG            DECIMAL(6,2)     NOT NULL CONSTRAINT DF_MealPhotoComponent_ProteinG DEFAULT 0,
    CarbsG              DECIMAL(6,2)     NOT NULL CONSTRAINT DF_MealPhotoComponent_CarbsG DEFAULT 0,
    FatG                DECIMAL(6,2)     NOT NULL CONSTRAINT DF_MealPhotoComponent_FatG DEFAULT 0,
    Calories            INT              NOT NULL CONSTRAINT DF_MealPhotoComponent_Calories DEFAULT 0,
    MatchedPantryItemId UNIQUEIDENTIFIER NULL,

    CONSTRAINT PK_MealPhotoComponent PRIMARY KEY (Id),
    CONSTRAINT FK_MealPhotoComponent_Estimate
        FOREIGN KEY (MealPhotoEstimateId) REFERENCES nutrition.MealPhotoEstimate(Id) ON DELETE CASCADE,
    CONSTRAINT FK_MealPhotoComponent_PantryItem
        FOREIGN KEY (MatchedPantryItemId) REFERENCES nutrition.PantryItem(Id)
);
GO
