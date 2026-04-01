library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- สีธีมหลัก (#CC0099) ---
const Color mainColor = Color(0xFFCC0099);

// ตัวแปรเก็บภาษา (true = ไทย, false = อังกฤษ)
bool isThai = false;

// โหลดภาษาจากเครื่อง
Future<void> loadLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  isThai = prefs.getBool('isThai') ?? false; 
}

// บันทึกภาษาลงเครื่อง
Future<void> saveLanguage(bool value) async {
  isThai = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isThai', value);
}