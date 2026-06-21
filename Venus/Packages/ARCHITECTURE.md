# Zenith package layout

Esta pasta espelha a estrutura que pretendemos extrair para SPM local depois, sem forcar uma migracao completa agora.

## Estrutura alvo

```text
Packages/
  ZenithDomain/
    Sources/
      ZenithDomain/
        Energy/
          Domain/
          Application/
        Sentinel/
          Domain/
          Application/
        SharedKernel/
  ZenithUI/
    Sources/
      ZenithUI/
        Home/
          Presentation/
          Components/
```

## Regra pratica

- `ZenithDomain` concentra entidades, value objects, protocolos e assinaturas de casos de uso.
- `ZenithUI` concentra SwiftUI, ViewModels e estado de apresentacao.
- A logica interna dos casos de uso complexos continua propositalmente aberta para implementacao guiada.

