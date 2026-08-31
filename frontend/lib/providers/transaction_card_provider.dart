import 'package:flutter/material.dart';

class TransactionCardProvider with ChangeNotifier {
  Map _transactionData = {};

  Map get transactionData => _transactionData;

  void changeCard (Map data) {
    _transactionData = data;
    notifyListeners();
  }
}
