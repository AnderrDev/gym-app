# Manrope

Fuente de Google Fonts, bajo la licencia SIL Open Font License de `OFL.txt`.

Origen: https://github.com/google/fonts/tree/main/ofl/manrope

Los archivos estáticos de pesos 400, 500, 600, 700 y 800 se generaron desde
`Manrope-Variable.ttf` con `fontTools.varLib.instancer`. Cada instancia conserva
el diseño original y permite que Flutter seleccione el peso correcto sin
descargar fuentes durante el arranque. Solo esas instancias se incluyen en el
bundle mediante `pubspec.yaml`.

Después se recortaron al juego latino (español, Latin-1 + Latin Extended-A,
puntuación, flechas y símbolos matemáticos) para reducir ~47 % el peso que
web descarga al arrancar:

```bash
pyftsubset Manrope-<Peso>.ttf --layout-features='*' \
  --unicodes="U+0000-017F,U+0192,U+0218-021B,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0300-0308,U+0327,U+2000-206F,U+20AC,U+2122,U+2190-21FF,U+2200-22FF,U+25A0-25FF,U+2713,U+FEFF,U+FFFD" \
  --output-file=Manrope-<Peso>.ttf
```

Si la UI empieza a usar caracteres fuera de ese rango, regenera las
instancias desde `Manrope-Variable.ttf` y vuelve a recortarlas incluyéndolos.
Los glifos que falten los pinta la fuente de respaldo del sistema/Noto.
