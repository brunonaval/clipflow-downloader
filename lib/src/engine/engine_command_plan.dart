enum EngineCommandPlanType { analyze, download }

class EngineCommandPlan {
  final EngineCommandPlanType type;
  final String engineLabel;
  final List<String> arguments;
  final String summaryLabel;
  final bool isExecutable;

  const EngineCommandPlan({
    required this.type,
    required this.engineLabel,
    required this.arguments,
    required this.summaryLabel,
    this.isExecutable = false,
  });

  String get preview => '$engineLabel ${arguments.join(' ')}'.trim();
}
