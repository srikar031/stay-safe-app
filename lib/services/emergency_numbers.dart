class EmergencyNumbers {
  static const Map<String, String> _countryEmergencyNumbers = {
    'US': '911',        // United States
    'CA': '911',        // Canada
    'GB': '999',        // United Kingdom
    'AU': '000',        // Australia
    'NZ': '111',        // New Zealand
    'IN': '112',        // India
    'JP': '110',        // Japan (Police)
    'DE': '112',        // Germany
    'FR': '112',        // France
    'IT': '112',        // Italy
    'ES': '112',        // Spain
    'BR': '192',        // Brazil (Ambulance)
    'MX': '911',        // Mexico
    'RU': '112',        // Russia
    'CN': '110',        // China (Police)
    'ZA': '10111',      // South Africa
    'KR': '112',        // South Korea
    'AR': '911',        // Argentina
    'SG': '999',        // Singapore
    'MY': '999',        // Malaysia
    'PH': '911',        // Philippines
    'TH': '191',        // Thailand
    'ID': '112',        // Indonesia
    'NL': '112',        // Netherlands
    'BE': '112',        // Belgium
    'CH': '112',        // Switzerland
    'AT': '112',        // Austria
    'SE': '112',        // Sweden
    'NO': '112',        // Norway
    'DK': '112',        // Denmark
    'FI': '112',        // Finland
    'PL': '112',        // Poland
    'CZ': '112',        // Czech Republic
    'SK': '112',        // Slovakia
    'HU': '112',        // Hungary
    'RO': '112',        // Romania
    'BG': '112',        // Bulgaria
    'HR': '112',        // Croatia
    'SI': '112',        // Slovenia
    'EE': '112',        // Estonia
    'LV': '112',        // Latvia
    'LT': '112',        // Lithuania
    'GR': '112',        // Greece
    'PT': '112',        // Portugal
    'IE': '112',        // Ireland
    'IS': '112',        // Iceland
    'LU': '112',        // Luxembourg
    'MT': '112',        // Malta
    'CY': '112',        // Cyprus
    'TR': '112',        // Turkey
    'IL': '100',        // Israel (Police)
    'AE': '999',        // United Arab Emirates
    'SA': '999',        // Saudi Arabia
    'EG': '122',        // Egypt (Police)
    'NG': '112',        // Nigeria
    'KE': '999',        // Kenya
    'UG': '999',        // Uganda
    'TZ': '112',        // Tanzania
    'GH': '112',        // Ghana
    'ZW': '999',        // Zimbabwe
    'ZM': '999',        // Zambia
    'MW': '997',        // Malawi
    'MZ': '119',        // Mozambique
    'AO': '113',        // Angola
    'ET': '911',        // Ethiopia
    'SD': '999',        // Sudan
    'TN': '112',        // Tunisia
    'DZ': '112',        // Algeria
    'MA': '112',        // Morocco
    'LY': '193',        // Libya
    'CL': '133',        // Chile
    'CO': '123',        // Colombia
    'PE': '105',        // Peru
    'VE': '911',        // Venezuela
    'EC': '911',        // Ecuador
    'BO': '110',        // Bolivia
    'PY': '911',        // Paraguay
    'UY': '911',        // Uruguay
    'GY': '911',        // Guyana
    'SR': '112',        // Suriname
    'GF': '112',        // French Guiana
    'FK': '999',        // Falkland Islands
  };

  static String getEmergencyNumber(String countryCode) {
    return _countryEmergencyNumbers[countryCode] ?? '911'; // Default to 911 if not found
  }

  static List<String> getAllCountries() {
    return _countryEmergencyNumbers.keys.toList();
  }
}