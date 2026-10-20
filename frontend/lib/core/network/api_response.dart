class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}
