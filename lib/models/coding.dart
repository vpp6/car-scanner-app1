enum CodingState { idle, connecting, downloading, writing, verifying, done, failed }

class CodingModule {
  final String name;
  final String description;
  final String version;
  final String size;
  final bool offline;

  const CodingModule({
    required this.name,
    required this.description,
    required this.version,
    required this.size,
    required this.offline,
  });
}
