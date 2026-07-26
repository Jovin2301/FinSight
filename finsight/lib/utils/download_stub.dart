// Stub used on non-web platforms (iOS, Android, desktop).
// This branch is never actually called there — see transactions_screen.dart.
void downloadCsvWeb(String csvData, String fileName) {
  throw UnsupportedError('Web download is not supported on this platform.');
}