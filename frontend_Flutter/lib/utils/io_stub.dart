class File {
  final String path;
  File(this.path);

  Future<void> writeAsString(String contents) async {
    throw UnsupportedError('File is not supported on web platform');
  }

  Future<String> readAsString() async {
    throw UnsupportedError('File is not supported on web platform');
  }

  Future<bool> exists() async => false;
}
