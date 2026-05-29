/// Stub para plataformas no-web. En móvil/desktop no hay URL bar que
/// configurar, así que esto es un no-op. La variante web vive en
/// `url_strategy_web.dart` y se selecciona vía conditional import.
void configureWebUrlStrategy() {}
