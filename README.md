# Loonie Split

A Flutter-based bill splitting app designed specifically for Canadians. This side project handles the complexity of Canadian tax systems (GST, HST, PST, QST) across all provinces and territories, making it easy to split bills accurately.

## Features

### Bill Splitting & Calculation
- Add multiple bill items with individual prices
- Assign items to specific people or mark as shared
- Automatic calculation of each person's exact share including taxes
- Real-time calculation updates

### Canadian Tax System Support
- All 10 provinces + 3 territories with accurate 2025 tax rates
- Handles HST, GST + PST, and GST-only provinces
- Province auto-detection via GPS/geolocation
- Supports tax holidays and exemptions (e.g., GST/HST Holiday 2024-2025)

### Receipt Scanning (OCR)
- Capture receipts via camera or pick from gallery
- Google ML Kit text recognition with intelligent parsing
- Extracts store name, items, quantities, prices, and totals
- Manual review and editing before adding items

### Tip Management
- Flexible tip percentage input
- Toggle between tip-before-tax and tip-after-tax calculations
- Proportional tip distribution among participants

### Additional Taxes
- Province-specific taxes (alcohol, tourism, cannabis, etc.)
- Custom tax rates per item

### Export & Sharing
- Export bill details to PDF
- Export to CSV format
- Share via email, messaging, or other platforms

## Tech Stack

- **Framework**: Flutter 3.8.1+ with Material Design 3
- **State Management**: Provider
- **Local Storage**: Hive, SharedPreferences
- **OCR**: Google ML Kit Text Recognition
- **Location**: Geolocator, Geocoding
- **Export**: PDF, Printing, Share Plus
- **Contacts**: Flutter Contacts

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- iOS/Android development environment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/KLeung1997/LoonieSplit.git
cd LoonieSplit
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Supported Provinces & Territories

| Province/Territory | Tax Type |
|-------------------|----------|
| Alberta | GST (5%) |
| British Columbia | GST + PST |
| Manitoba | GST + PST |
| New Brunswick | HST (15%) |
| Newfoundland & Labrador | HST (15%) |
| Northwest Territories | GST (5%) |
| Nova Scotia | HST (15%) |
| Nunavut | GST (5%) |
| Ontario | HST (13%) |
| Prince Edward Island | HST (15%) |
| Quebec | GST + QST |
| Saskatchewan | GST + PST |
| Yukon | GST (5%) |

## Screenshots

*Coming soon*

## License

This project is open source and available under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## Author

Ken Leung - Side Project

---

Made with Flutter
