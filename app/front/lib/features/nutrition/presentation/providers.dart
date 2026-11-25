import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_meal_vision_source.dart';
import '../domain/ports/meal_vision_source.dart';

final Provider<MealVisionSource> mealVisionSourceProvider =
    Provider<MealVisionSource>((Ref ref) => const MockMealVisionSource());
