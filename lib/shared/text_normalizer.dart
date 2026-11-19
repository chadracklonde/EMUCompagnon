/// Lowercases and strips French accents and punctuation, so "Bénissons",
/// "benissons" and "BÉNISSONS !" compare equal in a search.
String normalizeForSearch(String input) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buf = StringBuffer();
  for (final ch in input
      .toLowerCase()
      .replaceAll('œ', 'oe')
      .replaceAll('æ', 'ae')
      .split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
