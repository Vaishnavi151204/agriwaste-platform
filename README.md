# AgriWaste Platform

**A Flutter-based marketplace connecting agricultural waste suppliers with potential buyers.**

AgriWaste Platform aims to make agricultural by-products such as straw, husk, and bagasse easier to discover, trade, and collect. The application brings farmers, buyers, and transporters together to support agricultural waste reuse and resource recovery.

## Problem Statement

Agricultural residues can go unused when farmers lack convenient access to buyers. At the same time, industries that can reuse these materials need a better way to discover available supplies and coordinate collection.

## Proposed Solution

AgriWaste provides a digital marketplace for agricultural waste listings, order management, and pickup coordination through a role-based application.

## Key Features

- **Role-based access:** Separate experiences for farmers, buyers, and transporters.
- **Waste listings:** Present agricultural waste information, including type, quantity, and location.
- **Waste discovery:** Browse available listings and view their details.
- **Order management:** Create orders and track order-related information.
- **Pickup coordination:** Support transporter workflows and pickup-job management.
- **Map support:** Explore location-based functionality.
- **Smart ordering:** An AI-assisted ordering workflow is part of the project.

Feature availability may vary as development continues. The payment screen currently uses a mock flow and does not process real payments.

## Technology Stack

- **Mobile application:** Flutter and Dart
- **Backend and database:** Supabase
- **Maps:** Flutter map components and OpenStreetMap
- **Development tools:** Android Studio, Visual Studio Code, Git, and GitHub

## Project Structure

```text
lib/
├── app/
├── core/
└── features/
    ├── auth/
    ├── buyer/
    ├── farmer/
    ├── shared/
    └── transporter/
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK compatible with your Flutter installation
- Git
- Android Studio or Visual Studio Code
- A Supabase project configured for the application

### Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/Vaishnavi151204/agriwaste-platform.git
   cd agriwaste-platform
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create a Supabase project and obtain its project URL and publishable key.

4. Create your local configuration file by copying the example:

   ```powershell
   Copy-Item "lib\core\constants\supabase_constants.example.dart" "lib\core\constants\supabase_constants.dart"
   ```

5. Open `lib/core/constants/supabase_constants.dart` and replace the placeholder values with your own Supabase project URL and publishable key. Do not commit secret or service-role keys.

6. Run the application on a supported device or emulator:

   ```bash
   flutter run
   ```

> **Configuration note:** The local Supabase configuration file is excluded from version control. Clone setup will require a documented way to provide your own configuration.

## Project Status

Under active development. Features, setup instructions, and implementation details may change as the project evolves.

## Security

- Never commit Supabase service-role keys, secret keys, passwords, access tokens, or private credentials.
- Keep local configuration files out of version control.
- Configure appropriate Supabase Row Level Security (RLS) policies before using real user data.
- Do not use real payment details; the current payment flow is a mock implementation.

## Author

**Vaishnavi Dhankutkar**

B.Tech Artificial Intelligence Engineering Student

- GitHub: [@Vaishnavi151204](https://github.com/Vaishnavi151204)
- LinkedIn: [Vaishnavi Dhankutkar](https://linkedin.com/in/vaishnavi-dhankutkar-68a55329)


