class Project {
  final int id;
  final String name;
  final String reference;
  final Status status;

  const Project({
    required this.id,
    required this.name,
    required this.reference,
    required this.status,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json["id"],
        name: json["name"],
        reference: json["reference"],
        status: statusValues.map[json["status"]]!,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "reference": reference,
        "status": statusValues.reverse[status],
      };
}

enum Status { created, downloaded, ongoing, open, underVerification }

final statusValues = EnumValues({
  "Created": Status.created,
  "Downloaded": Status.downloaded,
  "Ongoing": Status.ongoing,
  "Open": Status.open,
  "Under Verification": Status.underVerification
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}


//? Enum Status {"open", "Ongoing"}; Thats looks the right way
