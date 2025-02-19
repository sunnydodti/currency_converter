class CurrencyCode {
  final String name;
  final String code;

  CurrencyCode({required this.name, required this.code});

  factory CurrencyCode.fromJson(Map<dynamic, dynamic> json) {
    return CurrencyCode(
      name: json['name'],
      code: json['code'],
    );
  }

  Map<String, String> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}
