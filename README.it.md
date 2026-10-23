# lumen_core

Italiano | [English](README.md)

Il motore dei sensi per [Lumen](https://github.com/lumen-assistive):
l'implementazione dei contratti definiti in
[`lumen_sdk`](https://github.com/lumen-assistive/lumen-sdk).

- **`InMemoryEventBus`**: il `LumenEventBus` di produzione a cui ogni
  plugin si sottoscrive.
- **`LocalModelRegistry`**: il `ModelRegistry` di produzione, basato su
  una cartella locale di modelli scaricati, con comportamento di
  download personalizzabile tramite `ModelDownloader`.
- **`PluginManager`**: gestisce il ciclo di vita dei plugin
  (registrazione, verifica di compatibilità della versione dell'SDK,
  avvio e arresto dei moduli), controllato da un `CapabilityGate` e un
  `ConsentStore` forniti dall'app ospitante.

`lumen-app` e ogni repository `lumen-plugin-*` dipendono da questo
pacchetto, ancorati a una versione pubblicata, mai a `main`.

## Stato attuale

Questa versione include la parte indipendente dalla piattaforma del
motore dei sensi come pacchetto Dart puro: event bus, registro dei
modelli e gestore dei plugin descritti sopra, completamente
implementati e testati. Non include ancora:

- I ponti nativi verso i sensori (fotocamera e microfono) che
  trasformano l'input hardware grezzo in eventi `lumen_sdk`.
- I collegamenti per l'inferenza dei modelli on-device (TFLite,
  whisper.cpp tramite FFI, OCR).

Questi richiedono Kotlin, Swift e toolchain di build native per essere
implementati e verificati correttamente, e sono la prossima fase di
lavoro non appena tale toolchain sarà disponibile nell'ambiente di
sviluppo. La loro implementazione trasformerà questo pacchetto in un
plugin Flutter con codice nativo in `android/` e `ios/`; vedi
`CHANGELOG.md` per sapere quando ciò avverrà.

## Sviluppo

```
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

Installa l'hook condiviso per i messaggi di commit prima di fare commit:

```
git config core.hooksPath .githooks
```

Vedi [CONTRIBUTING.md](CONTRIBUTING.md) per il flusso di lavoro completo
(in inglese, come tutto il codice e la documentazione tecnica del
progetto).

## Licenza

Apache License 2.0, vedi [LICENSE](LICENSE).
