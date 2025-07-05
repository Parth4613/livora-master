import 'package:cloud_firestore/cloud_firestore.dart';

class HostelData {
  final String title;
  final String address;
  final String availableFromDate;
  final String bookingMode;
  final String contactPerson;
  final String description;
  final String drinkingPolicy;
  final String email;
  final Map<String, bool> facilities;
  final String foodType;
  final String guestsPolicy;
  final bool hasEntryTimings;
  final String hostelFor;
  final String hostelType;
  final String landmark;
  final String minimumStay;
  final String offers;
  final String petsPolicy;
  final String phone;
  final Map<String, bool> roomTypes;
  final String selectedPlan;
  final String smokingPolicy;
  final String specialFeatures;
  final double startingAt;
  final String entryTime;
  final Map<String, String> uploadedPhotos;
  final bool visibility;

  HostelData({
    required this.title,
    required this.address,
    required this.availableFromDate,
    required this.bookingMode,
    required this.contactPerson,
    required this.description,
    required this.drinkingPolicy,
    required this.email,
    required this.facilities,
    required this.foodType,
    required this.guestsPolicy,
    required this.hasEntryTimings,
    required this.hostelFor,
    required this.hostelType,
    required this.landmark,
    required this.minimumStay,
    required this.offers,
    required this.petsPolicy,
    required this.phone,
    required this.roomTypes,
    required this.selectedPlan,
    required this.smokingPolicy,
    required this.specialFeatures,
    required this.startingAt,
    required this.entryTime,
    required this.uploadedPhotos,
    required this.visibility,
  });

  factory HostelData.fromFirestore(Map<String, dynamic> data) {
    return HostelData(
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      availableFromDate: data['availableFromDate'] ?? '',
      bookingMode: data['bookingMode'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      description: data['description'] ?? '',
      drinkingPolicy: data['drinkingPolicy'] ?? '',
      email: data['email'] ?? '',
      facilities: (data['facilities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      foodType: data['foodType'] ?? '',
      guestsPolicy: data['guestsPolicy'] ?? '',
      hasEntryTimings: data['hasEntryTimings'] ?? false,
      hostelFor: data['hostelFor'] ?? '',
      hostelType: data['hostelType'] ?? '',
      landmark: data['landmark'] ?? '',
      minimumStay: data['minimumStay'] ?? '',
      offers: data['offers'] ?? '',
      petsPolicy: data['petsPolicy'] ?? '',
      phone: data['phone'] ?? '',
      roomTypes: (data['roomTypes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      selectedPlan: data['selectedPlan'] ?? '',
      smokingPolicy: data['smokingPolicy'] ?? '',
      specialFeatures: data['specialFeatures'] ?? '',
      startingAt: (data['startingAt'] ?? 0).toDouble(),
      entryTime: data['entryTime'] ?? '',
      uploadedPhotos: (data['uploadedPhotos'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      visibility: data['visibility'] ?? false,
    );
  }

  List<String> getAvailableRoomTypes() {
    return roomTypes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> getAvailableFacilities() {
    return facilities.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}
