class BrandModelService {
  static final Map<String, List<String>> brandModels = {
    'Toyota': [
      'Camry',
      'Corolla',
      'Sienna',
      'RAV4',
      'Highlander',
      'Land Cruiser',
      'Prado',
      'Hilux',
      'Avalon',
      'Avanza',
    ],
    'BMW': [
      '3 Series',
      '5 Series',
      '7 Series',
      'X1',
      'X3',
      'X5',
      'X6',
      'X7',
      'M3',
      'M5',
    ],
    'Mercedes-Benz': [
      'C-Class',
      'E-Class',
      'S-Class',
      'GLE',
      'GLS',
      'GLC',
      'G-Class',
      'CLA',
      'A-Class',
    ],
    'Lexus': ['ES', 'GS', 'IS', 'RX', 'LX', 'GX', 'NX', 'LS'],
    'Hyundai': [
      'Elantra',
      'Sonata',
      'Santa Fe',
      'Tucson',
      'Accent',
      'Palisade',
      'Solaris',
      'Creta',
    ],
    'Kia': ['Rio', 'Sportage', 'Sorento', 'Optima', 'K5', 'Cerato', 'Carnival'],
    'Nissan': [
      'Altima',
      'Sentra',
      'Maxima',
      'Patrol',
      'X-Trail',
      'Qashqai',
      'Juke',
    ],
    'Honda': ['Civic', 'Accord', 'CR-V', 'Pilot', 'HR-V', 'City'],
    'Mazda': ['Mazda3', 'Mazda6', 'CX-5', 'CX-9', 'CX-30'],
    'Volkswagen': ['Golf', 'Passat', 'Tiguan', 'Touareg', 'Polo', 'Jetta'],
    'Audi': ['A3', 'A4', 'A6', 'A8', 'Q5', 'Q7', 'Q8'],
    'Ford': ['Focus', 'Fusion', 'Explorer', 'Escape', 'Mustang', 'F-150'],
    'Opel': ['Astra', 'Insignia', 'Corsa', 'Zafira', 'Mokka'],
    'Tesla': ['Model 3', 'Model S', 'Model X', 'Model Y'],
    'Other': ['Other Model'],
  };

  static List<String> getBrands() {
    return brandModels.keys.toList()..sort();
  }

  static List<String> getModels(String brand) {
    return brandModels[brand] ?? ['Other Model'];
  }
}
