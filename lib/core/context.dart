class Context {
  final String org;

  Context({required this.org});

  factory Context.defaultContext() {
    return Context(org: 'thelearmondcorporation');
  }
}