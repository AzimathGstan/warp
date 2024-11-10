import 'package:flutter/material.dart';

Widget centralNotice(String text){
  return 
    Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      
    );
}
