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

### Option 1: Download the Release

1. Go to the [Releases](https://github.com/yourusername/PantawCoin/releases) page
2. Download the latest `PantawCoin-x.x.x.dmg` file
3. Open the DMG file and drag PantawCoin to your Applications folder
4. Open PantawCoin from your Applications folder

### Option 2: Build from Source

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

4. (Optional) Create a proper macOS app bundle:
   ```
   ./scripts/build_app.sh
   open PantawCoin.app
   ```

5. (Optional) Copy the app to your Applications folder:
   ```
   cp -r PantawCoin.app /Applications/
   ```

### Option 3: Add to Login Items

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

To create and run a proper macOS app bundle:

```
./scripts/build_app.sh
open PantawCoin.app
```

The app will appear in your menu bar with the Bitcoin symbol (₿) followed by the current Bitcoin price.

## Landing Page

PantawCoin has a landing page built with GitHub Pages. You can view it at:

```
https://yourusername.github.io/PantawCoin/
```

### Updating the Landing Page

The landing page is located in the `docs/` directory. To make changes:

1. Edit the files in the `docs/` directory
2. Commit and push your changes to GitHub
3. GitHub will automatically rebuild the page

The landing page uses plain HTML, CSS, and JavaScript without any frameworks for simplicity.

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

## For Developers

### Release Process

PantawCoin uses GitHub Actions to automate the release process. Here's how to create a new release:

1. Make sure all your changes are committed and pushed to the main branch
2. Run the release script with the new version number:
   ```
   ./scripts/release.sh 1.0.1
   ```
3. Push the changes and the new tag:
   ```
   git push origin main
   git push origin v1.0.1
   ```
4. GitHub Actions will automatically:
   - Build the application
   - Create a macOS app bundle
   - Package it into a DMG file
   - Create a GitHub release with the DMG attached

The release will be available on the [Releases](https://github.com/yourusername/PantawCoin/releases) page.

### Rate Limiting

The CoinGecko API has rate limits for free tier users. PantawCoin implements several strategies to handle this:

1. **Caching**: Data is cached for 5 minutes to reduce API calls
2. **Exponential Backoff**: When rate limited, the app will retry with increasing delays
3. **Fallback Mechanisms**: When API calls fail, the app will use cached data

If you're experiencing frequent rate limiting, consider:
- Getting a CoinGecko API key and adding it to the `apiKey` variable in `CryptoDataManager.swift`
- Increasing the refresh interval in `main.swift` (currently 5 minutes)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [CoinGecko](https://www.coingecko.com/) for providing the cryptocurrency data API
- [Swift Package Manager](https://swift.org/package-manager/) for dependency management
