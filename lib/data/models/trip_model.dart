class TripModel {
  final String id;
  final String driverId;
  final String source;
  final String destination;
  final DateTime departureTime;
  final double pricePerSeat;
  final int availableSeats;
  final String status;

  TripModel({
    required this.id,
    required this.driverId,
    required this.source,
    required this.destination,
    required this.departureTime,
    required this.pricePerSeat,
    required this.availableSeats,
    required this.status,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      driverId: json['driver_id'],
      source: json['source'],
      destination: json['destination'],
      departureTime: DateTime.parse(json['departure_time']),
      pricePerSeat: (json['price_per_seat'] as num).toDouble(),
      availableSeats: json['available_seats'] as int,
      status: json['status'],
    );
  }
}