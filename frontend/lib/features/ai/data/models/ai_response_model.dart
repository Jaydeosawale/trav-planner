class AIResponseModel {
  final bool success;
  final String content;
  final String agent;
  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;
  final String? message;

  const AIResponseModel({
    required this.success,
    required this.content,
    required this.agent,
    required this.data,
    required this.metadata,
    this.message,
  });

  factory AIResponseModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return AIResponseModel(
      success: json['success'] == true,
      content: data['content']?.toString() ?? '',
      agent: data['agent']?.toString() ?? '',
      data: data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : <String, dynamic>{},
      metadata: data['metadata'] is Map<String, dynamic>
          ? data['metadata'] as Map<String, dynamic>
          : <String, dynamic>{},
      message: json['message']?.toString(),
    );
  }
}
