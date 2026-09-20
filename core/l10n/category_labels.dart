import '../../l10n/app_localizations.dart';

/// [AppConstants.defaultItemCategories] and [AppConstants.unitOptions] are
/// stored (and compared against, e.g. `_selectedCategory == 'دیگر'`) as
/// fixed Urdu strings — that canonical value never changes with locale.
/// These two helpers only pick the *displayed* label for a given locale,
/// leaving the stored/compared value untouched.
String categoryLabel(AppLocalizations t, String value) {
  switch (value) {
    case 'گروسری':
      return t.categoryGrocery;
    case 'مشروبات':
      return t.categoryBeverages;
    case 'ادویات':
      return t.categoryMedicines;
    case 'کاسمیٹکس':
      return t.categoryCosmetics;
    case 'الیکٹرانکس':
      return t.categoryElectronics;
    case 'کھانے پینے کی اشیاء':
      return t.categoryFoodItems;
    case 'کپڑے':
      return t.categoryClothes;
    case 'پرزہ جات (اسپیئر پارٹس)':
      return t.categorySpareParts;
    case 'دیگر':
      return t.businessTypeOther;
    default:
      return value;
  }
}

String unitLabel(AppLocalizations t, String value) {
  switch (value) {
    case 'عدد':
      return t.unitPiece;
    case 'کلوگرام':
      return t.unitKilogram;
    case 'گرام':
      return t.unitGram;
    case 'لیٹر':
      return t.unitLitre;
    case 'ملی لیٹر':
      return t.unitMillilitre;
    case 'درجن':
      return t.unitDozen;
    case 'ڈبہ':
      return t.unitBox;
    case 'کارٹن':
      return t.unitCarton;
    case 'دیگر':
      return t.businessTypeOther;
    default:
      return value;
  }
}
