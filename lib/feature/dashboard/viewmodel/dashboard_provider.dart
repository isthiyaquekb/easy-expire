import 'package:flutter/cupertino.dart';

class DashboardProvider extends ChangeNotifier{
  int _currentIndex=0;

  int get currentIndex=>_currentIndex;


  void changeBottomNavIndex(int index){
    _currentIndex=index;
    notifyListeners();
  }
}