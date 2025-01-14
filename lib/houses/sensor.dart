class Sensor {
  String name;
  String wall;
  double distanceFromWall;

  Sensor({
    required this.name,
    required this.wall,
    required this.distanceFromWall,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wall': wall,
      'distanceFromWall': distanceFromWall,
    };
  }

  static Sensor fromJson(Map<String, dynamic> json) {
    return Sensor(
      name: json['name'],
      wall: json['wall'],
      distanceFromWall: json['distanceFromWall'],
    );
  }
}
