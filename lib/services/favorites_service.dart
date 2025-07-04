import 'package:flutter/foundation.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final List<Map<String, dynamic>> _favorites = [];

  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(Map<String, dynamic> recipe) {
    return _favorites.any((fav) => fav['id'] == recipe['id']);
  }

  void addToFavorites(Map<String, dynamic> recipe) {
    if (!isFavorite(recipe)) {
      _favorites.add(recipe);
      notifyListeners();
    }
  }

  void removeFromFavorites(Map<String, dynamic> recipe) {
    _favorites.removeWhere((fav) => fav['id'] == recipe['id']);
    notifyListeners();
  }

  void toggleFavorite(Map<String, dynamic> recipe) {
    if (isFavorite(recipe)) {
      removeFromFavorites(recipe);
    } else {
      addToFavorites(recipe);
    }
  }
}
