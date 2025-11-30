import 'package:flutter/material.dart'; // ✅ ADICIONAR ESTE IMPORT

class CommunityWeather {
  final String userName;
  final String username;
  final String userType;
  final String weatherStatus;
  final String apiWeatherStatus;
  final String location;
  final String timeAgo;
  final bool isCurrentUser;
  final IconData userIcon; // ✅ AGORA IconData ESTÁ DISPONÍVEL
  final DateTime dateTime;
  final bool hasPhoto;

  CommunityWeather({
    required this.userName,
    required this.username,
    required this.userType,
    required this.weatherStatus,
    required this.apiWeatherStatus,
    required this.location,
    required this.timeAgo,
    required this.isCurrentUser,
    required this.userIcon,
    required this.dateTime,
    this.hasPhoto = false,
  });
}
