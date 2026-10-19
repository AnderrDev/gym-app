# Manrope

Fuente de Google Fonts, bajo la licencia SIL Open Font License de `OFL.txt`.

Origen: https://github.com/google/fonts/tree/main/ofl/manrope

Los archivos estáticos de pesos 400, 500, 600, 700 y 800 se generaron desde
`Manrope-Variable.ttf` con `fontTools.varLib.instancer`. Cada instancia conserva
el diseño original y permite que Flutter seleccione el peso correcto sin
descargar fuentes durante el arranque. Solo esas instancias se incluyen en el
bundle mediante `pubspec.yaml`.
