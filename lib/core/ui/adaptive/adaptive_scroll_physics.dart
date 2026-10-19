import 'package:flutter/material.dart';

import 'package:gym_flutter/core/platform/capabilities.dart';

/// Scroll physics que se adapta a la plataforma.
///
/// - iOS / macOS: `BouncingScrollPhysics` (overscroll elástico, momento
///   de inercia largo).
/// - Web / Android: `ClampingScrollPhysics` con `AlwaysScrollable...`
///   para que coincida con el feel nativo del browser/Android.
///
/// El widget chequea `Capabilities.prefersBouncePhysics`; los call sites
/// solo usan `AdaptiveScrollPhysics.preferred` en vez de hardcodear.
class AdaptiveScrollPhysics {
  AdaptiveScrollPhysics._();

  /// Physics a usar en `ListView` / `SingleChildScrollView` / etc. para
  /// que el scroll sienta nativo en cada plataforma.
  static ScrollPhysics get preferred {
    if (Capabilities.prefersBouncePhysics) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
