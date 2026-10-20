/// Pure Dart Formation Validator (Spec §5.2).
/// Zero Flutter or I/O imports.
class FormationValidator {
  static const int minDef = 3;
  static const int maxDef = 5;
  static const int minMid = 2;
  static const int maxMid = 5;
  static const int minFwd = 1;
  static const int maxFwd = 3;

  static const Set<String> validFormations = {
    '1-3-5-2',
    '1-3-4-3',
    '1-4-4-2',
    '1-4-3-3',
    '1-4-5-1',
    '1-5-3-2',
    '1-5-2-3',
    '1-5-4-1',
  };

  /// Returns true if the formation [gk, def, mid, fwd] is a legal FPL formation.
  static bool isValidCounts(int gk, int def, int mid, int fwd) {
    if (gk + def + mid + fwd != 11) return false;
    if (gk != 1) return false;
    if (def < minDef || def > maxDef) return false;
    if (mid < minMid || mid > maxMid) return false;
    if (fwd < minFwd || fwd > maxFwd) return false;
    final formationStr = '1-$def-$mid-$fwd';
    return validFormations.contains(formationStr);
  }

  /// Formation string in standard format e.g. "1-4-4-2" or "4-4-2"
  static String formatFormation(int def, int mid, int fwd, {bool includeGk = false}) {
    if (includeGk) {
      return '1-$def-$mid-$fwd';
    }
    return '$def-$mid-$fwd';
  }
}
