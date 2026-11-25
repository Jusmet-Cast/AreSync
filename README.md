# AreSync

Ecosistema de acompañamiento fitness: un sistema de agentes (orquestación hoy
vía chat con un LLM) y una app cliente que lo vuelve portátil.

```
AreSync/
├── System/           El "cerebro": prompts de los 11 agentes (AEGIS, FORGE,
│                     NUTRISYNC, MOMENTUM, ...), el registro de bases Notion
│                     y el protocolo de orquestación. Esto es lo que hoy
│                     corre vía chat — ver System/ARESYNC_SYSTEM_PROMPT_V2.md.
└── app/
    ├── front/        Cliente Flutter (FitCodex). Multiplataforma, Clean
    │                 Architecture por feature. Ver app/front/README.md.
    └── api/          Backend .NET (planeado). Ver app/api/README.md — todavía
                      no tiene código, solo el plan de capas.
```

## Por qué todo en un repo

`System/` es la lógica de los agentes; `app/` es el producto que la vuelve
usable sin depender de abrir un chat y recordar los comandos `/weekly`,
`/close`, etc. Son dos superficies del mismo sistema, no dos proyectos
separados — un cambio de schema en `System/NOTION_DATA_REGISTRY.md` es
exactamente lo que `app/api` tiene que reflejar el día que exista.

## Estado

- `System/`: en producción, uso diario vía chat.
- `app/front`: esqueleto funcional, dominio generalizado (ver
  `app/front/README.md` § Pendientes).
- `app/api`: sin código todavía — solo el plan de capas en su README.
