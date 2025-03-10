# PantawCoin

A macOS menu bar app that displays the latest cryptocurrency prices for your favorite coins.

## Features

- Shows cryptocurrency prices in the macOS menu bar
- Displays price changes with color indicators (green for positive, red for negative)
- Allows you to select your favorite cryptocurrencies
- **Add custom cryptocurrency tickers** that aren't in the default list
- **Choose which cryptocurrency appears in the menu bar**
- Automatically refreshes prices every 5 minutes
- Manual refresh option

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later

## Installation

### Option 1: Build from Source

1. Clone this repository:

   ```
   git clone https://github.com/yourusername/PantawCoin.git
   cd PantawCoin
   ```

2. Build the project:

   ```
   swift build -c release
   ```

3. Run the app:

   ```
   ./.build/release/PantawCoin
   ```

4. (Optional) Copy the app to your Applications folder:
   ```
   cp -f ./.build/release/PantawCoin /Applications/
   ```

### Option 2: Add to Login Items

To have PantawCoin start automatically when you log in:

1. Open System Preferences
2. Go to Users & Groups
3. Select your user account
4. Click on "Login Items"
5. Click the "+" button
6. Navigate to and select the PantawCoin executable
7. Click "Add"

## Quick Start

After building the app, you can run it directly with:

```
./.build/debug/PantawCoin
```

Or for the release version:

```
./.build/release/PantawCoin
```

The app will appear in your menu bar with the Bitcoin symbol (₿) followed by the current Bitcoin price.

## Usage

Once running, PantawCoin will appear in your menu bar with your primary cryptocurrency price.

Click on the menu bar icon to:

- View prices of your favorite cryptocurrencies
- Manage your favorite cryptocurrencies
- Add custom cryptocurrency tickers
- Remove custom cryptocurrencies
- Manually refresh prices
- Quit the application

### Managing Favorite Cryptocurrencies

To add or remove cryptocurrencies from your favorites:
1. Click on the PantawCoin icon in the menu bar
2. Select "Manage Favorites"
3. Click on any cryptocurrency to toggle it on/off in your favorites list

You can also remove a cryptocurrency from your favorites by:
1. Click on the cryptocurrency in the main menu
2. Select "Remove from Favorites" from the submenu

### Setting a Primary Cryptocurrency

To choose which cryptocurrency appears in the menu bar:
1. Click on the PantawCoin icon in the menu bar
2. Click on any cryptocurrency in your favorites list
3. Select "Set as Primary Display" from the submenu

The selected cryptocurrency will now be displayed in the menu bar.

### Adding Custom Cryptocurrencies

To add a custom cryptocurrency:
1. Click on the PantawCoin icon in the menu bar
2. Select "Add Custom Coin"
3. Enter the ticker symbol for the cryptocurrency (e.g., "ADA" for Cardano)
4. Click "OK"

The app will automatically search for the cryptocurrency and add it to your favorites if found.

### Removing Custom Cryptocurrencies

To remove a custom cryptocurrency:
1. Click on the PantawCoin icon in the menu bar
2. Select "Remove Custom Coin"
3. Select the cryptocurrency you want to remove from the submenu

### Refreshing Prices

Prices automatically refresh every 5 minutes, but you can manually refresh at any time:
1. Click on the PantawCoin icon in the menu bar
2. Select "Refresh Prices"

## Data Source

PantawCoin uses the [CoinGecko API](https://www.coingecko.com/en/api) to fetch cryptocurrency prices.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [CoinGecko](https://www.coingecko.com/) for providing the cryptocurrency data API
- [Swift Package Manager](https://swift.org/package-manager/) for dependency management
