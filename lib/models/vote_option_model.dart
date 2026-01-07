class VoteOption {
  final String name;
  final List<String> votes;

  VoteOption({
    required this.name,
    required this.votes,
  });

  factory VoteOption.fromMap(Map<String, dynamic> map) {
    return VoteOption(
      name: map["name"] ?? "",
      votes: List<String>.from(map["votes"] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "votes": votes,
    };
  }
}
