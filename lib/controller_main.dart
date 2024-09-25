import 'package:flutter/material.dart';
import 'package:ussd_launcher/ussd_launcher.dart';
// ignore: depend_on_referenced_packages
import 'package:permission_handler/permission_handler.dart';

class MainController extends ChangeNotifier {
  String _ussdResponse = '';
  String get ussdResponse => _ussdResponse;

  List<Map<String, dynamic>> _simCards = [];
  List<Map<String, dynamic>> get simCards => _simCards;

  int? _selectedSimId;
  int? get selectedSimId => _selectedSimId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _dialogText = '';
  String get dialogText => _dialogText;

  Future<void> loadSimCards() async {
    var status = await Permission.phone.request();
    if (status.isGranted) {
      try {
        final simCards = await UssdLauncher.getSimCards();
        _simCards = simCards;
        if (simCards.isNotEmpty) {
          _selectedSimId = simCards[0]['subscriptionId'] as int?;
        }
        notifyListeners();
      } catch (e) {
        print("Error loading SIM cards: $e");
      }
    } else {
      print("Phone permission is not granted");
    }
  }

  void setSelectedSimId(int? simId) {
    _selectedSimId = simId;
    notifyListeners();
  }

  Future<void> sendUssdRequest(String code) async {
    try {
      final response = await UssdLauncher.launchUssd(code, _selectedSimId);
      _ussdResponse = response;
      notifyListeners();
    } catch (e) {
      _ussdResponse = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> launchMultiSessionUssd(String initialCode, List<String> options) async {
    _isLoading = true;
    _dialogText = '';
    notifyListeners();

    try {
      String? res1 = await UssdLauncher.multisessionUssd(
        code: initialCode,
        subscriptionId: (_selectedSimId ?? -1),
      );
      _updateDialogText('Initial Response: \n $res1');

      await Future.delayed(const Duration(seconds: 2));

      print("----------------- Sending initialCode: $initialCode");
      print("----------------- Sending _selectedSimId: $_selectedSimId");
      print("----------------- Sending options: $options");

      for (var option in options) {
        String? res = await UssdLauncher.sendMessage(option);
        _updateDialogText('\nResponse after sending "$option": \n $res');
        await Future.delayed(const Duration(seconds: 1));
      }

      await UssdLauncher.cancelSession();
      _updateDialogText('\nSession cancelled');
    } catch (e) {
      _updateDialogText('\nError: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateDialogText(String newText) {
    _dialogText += newText;
    notifyListeners();
  }
}