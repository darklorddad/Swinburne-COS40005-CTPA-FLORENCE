import 'package:flutter/material.dart';

// A simple, reusable loading dialog
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // User cannot dismiss it by tapping outside
    builder: (BuildContext context) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processing..."),
            ],
          ),
        ),
      );
    },
  );
}

// Function to hide the loading dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}