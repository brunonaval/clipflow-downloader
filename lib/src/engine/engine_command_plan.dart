enum EngineCommandPlanType { analyze, download }

class EngineCommandPlan {
  final EngineCommandPlanType type;
  final String executableLabel;
  final List<String> arguments;
  final String summaryLabel;
  final bool isExecutable;

  const EngineCommandPlan({
    required this.type,
    required this.executableLabel,
    required this.arguments,
    required this.summaryLabel,
    this.isExecutable = false,
  });

  String get preview => '$executableLabel ${arguments.join(' ')}'.trim();
}
