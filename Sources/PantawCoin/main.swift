import Cocoa
import Foundation

// App version and copyright information
let APP_VERSION = "1.0.3"
let APP_COPYRIGHT = "© 2025 PantawCoin"

// Helper function to load app icon
func loadAppIcon() -> NSImage? {
    // Try to load from bundle resources - first try the AppIcon from Assets.xcassets
    if let bundleURL = Bundle.module.url(
        forResource: "AppIcons/Assets.xcassets/AppIcon.appiconset/256", withExtension: "png")
    {
        return NSImage(contentsOf: bundleURL)
    }

    // Try alternative sizes if the 256px version isn't available
    let iconSizes = ["512", "1024", "128", "64", "32", "16"]
    for size in iconSizes {
        if let bundleURL = Bundle.module.url(
            forResource: "AppIcons/Assets.xcassets/AppIcon.appiconset/\(size)", withExtension: "png"
        ) {
            return NSImage(contentsOf: bundleURL)
        }
    }

    // Try the appstore.png as a fallback
    if let bundleURL = Bundle.module.url(forResource: "AppIcons/appstore", withExtension: "png") {
        return NSImage(contentsOf: bundleURL)
    }

    // For development, try to find the files in the current directory structure
    let devPaths = [
        "Sources/PantawCoin/Resources/AppIcons/Assets.xcassets/AppIcon.appiconset/256.png",
        "Sources/PantawCoin/Resources/AppIcons/appstore.png",
        "../Sources/PantawCoin/Resources/AppIcons/Assets.xcassets/AppIcon.appiconset/256.png",
        "../Sources/PantawCoin/Resources/AppIcons/appstore.png",
    ]

    for path in devPaths {
        if FileManager.default.fileExists(atPath: path) {
            return NSImage(contentsOfFile: path)
        }
    }

    // Fallback to system icon
    return NSImage(systemSymbolName: "bitcoinsign.circle", accessibilityDescription: "PantawCoin")
}

class CryptoMenuBarApp {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cryptoCoins: [CryptoCoin] = []
    private var timer: Timer?
    private var isRefreshing = false
    private let appIcon: NSImage?

    // Store a reference to the about window to prevent it from being deallocated
    private var aboutWindow: NSWindow?
    private var aboutWindowController: NSWindowController?

    init() {
        // Load the app icon
        appIcon = loadAppIcon()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Set default image while loading
            button.image =
                appIcon
                ?? NSImage(
                    systemSymbolName: "bitcoinsign.circle", accessibilityDescription: "Crypto")
            button.title = "Loading..."

            // Set initial title based on primary coin if available
            if let primaryCoin = CryptoDataManager.shared.getPrimaryCoinDetails() {
                let priceText = primaryCoin.formattedPrice

                // Download and set the coin image
                primaryCoin.downloadImage { [weak self] image in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        if let image = image {
                            // Resize the image to fit in the menu bar (16x16 pixels)
                            let resizedImage = self.resizeImage(
                                image: image, to: NSSize(width: 16, height: 16))
                            button.image = resizedImage
                        }

                        // Set the price text
                        button.title = priceText
                    }
                }
            }
        }

        setupMenu()
        fetchCryptoPrices()

        // Update prices every 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchCryptoPrices()
        }
    }

    private func setupMenu() {
        menu.removeAllItems()

        // Add refresh option
        let refreshItem = NSMenuItem(
            title: "Refresh Prices", action: #selector(refreshPrices), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Add about menu item
        let aboutItem = NSMenuItem(
            title: "About PantawCoin", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Add quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateMenu() {
        menu.removeAllItems()

        // Add crypto prices to menu
        for coin in cryptoCoins {
            if CryptoDataManager.shared.favoriteCoins.contains(coin.symbol) {
                let priceChangeText =
                    coin.formattedPriceChange.isEmpty ? "" : " (\(coin.formattedPriceChange))"
                let menuTitle =
                    "\(coin.name) (\(coin.symbol)): \(coin.formattedPrice)\(priceChangeText)"

                let item = NSMenuItem(title: menuTitle, action: nil, keyEquivalent: "")

                // Add color to price change
                if let change = coin.priceChangePercentage24h {
                    let attributedTitle = NSMutableAttributedString(string: menuTitle)

                    // Find the range of the price change text
                    if let range = menuTitle.range(of: priceChangeText) {
                        let nsRange = NSRange(range, in: menuTitle)
                        let color: NSColor = change >= 0 ? .green : .red
                        attributedTitle.addAttribute(.foregroundColor, value: color, range: nsRange)
                    }

                    item.attributedTitle = attributedTitle
                }

                // Add submenu for each coin with options
                let coinSubmenu = NSMenu()

                // Set as primary option
                let isPrimary = CryptoDataManager.shared.primaryCoin == coin.symbol
                let setPrimaryItem = NSMenuItem(
                    title: "Set as Primary Display",
                    action: #selector(setPrimaryCoin(_:)),
                    keyEquivalent: ""
                )
                setPrimaryItem.state = isPrimary ? .on : .off
                setPrimaryItem.representedObject = coin.symbol
                setPrimaryItem.target = self
                setPrimaryItem.isEnabled = true
                coinSubmenu.addItem(setPrimaryItem)

                // Remove from favorites option
                let removeItem = NSMenuItem(
                    title: "Remove from Favorites",
                    action: #selector(toggleFavorite(_:)),
                    keyEquivalent: ""
                )
                removeItem.representedObject = coin.symbol
                removeItem.target = self
                removeItem.isEnabled = true
                coinSubmenu.addItem(removeItem)

                item.submenu = coinSubmenu

                // Add a visual indicator for the primary coin in the main menu
                if isPrimary {
                    let primaryIndicator = NSAttributedString(
                        string: " ★",
                        attributes: [NSAttributedString.Key.foregroundColor: NSColor.systemYellow]
                    )
                    if let existingTitle = item.attributedTitle {
                        let newTitle = NSMutableAttributedString(attributedString: existingTitle)
                        newTitle.append(primaryIndicator)
                        item.attributedTitle = newTitle
                    } else {
                        let newTitle = NSMutableAttributedString(string: item.title)
                        newTitle.append(primaryIndicator)
                        item.attributedTitle = newTitle
                    }
                }

                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Add "Set Primary Coin" submenu at the top level
        let primaryCoinMenu = NSMenu()
        let primaryCoinItem = NSMenuItem(title: "Set Primary Coin", action: nil, keyEquivalent: "p")
        primaryCoinItem.target = self

        for (index, coin) in cryptoCoins.enumerated() {
            if CryptoDataManager.shared.favoriteCoins.contains(coin.symbol) {
                let isPrimary = CryptoDataManager.shared.primaryCoin == coin.symbol

                // Assign keyboard shortcuts 1-9 for the first 9 coins
                let keyEquivalent = index < 9 ? "\(index + 1)" : ""

                let item = NSMenuItem(
                    title: "\(coin.name) (\(coin.symbol))",
                    action: #selector(setPrimaryCoin(_:)),
                    keyEquivalent: keyEquivalent
                )
                item.state = isPrimary ? .on : .off
                item.representedObject = coin.symbol
                item.target = self
                item.isEnabled = true
                primaryCoinMenu.addItem(item)
            }
        }

        primaryCoinItem.submenu = primaryCoinMenu
        menu.addItem(primaryCoinItem)

        // Add manage favorites submenu
        let favoritesMenu = NSMenu()
        let favoritesItem = NSMenuItem(title: "Manage Favorites", action: nil, keyEquivalent: "")
        favoritesItem.target = self

        // Add reset to default favorites option
        let resetItem = NSMenuItem(
            title: "Reset to Default Favorites (BTC, ETH, SOL)",
            action: #selector(resetToDefaultFavorites),
            keyEquivalent: ""
        )
        resetItem.target = self
        favoritesMenu.addItem(resetItem)

        favoritesMenu.addItem(NSMenuItem.separator())

        for coin in cryptoCoins {
            let isFavorite = CryptoDataManager.shared.favoriteCoins.contains(coin.symbol)
            let item = NSMenuItem(
                title: "\(coin.name) (\(coin.symbol))",
                action: #selector(toggleFavorite(_:)),
                keyEquivalent: ""
            )
            item.state = isFavorite ? .on : .off
            item.representedObject = coin.symbol
            item.target = self
            item.isEnabled = true
            favoritesMenu.addItem(item)
        }

        favoritesItem.submenu = favoritesMenu
        menu.addItem(favoritesItem)

        // Remove custom coin submenu if there are any custom coins
        let customCoins = cryptoCoins.filter { coin in
            let dataManager = CryptoDataManager.shared
            return !dataManager.defaultCoins.values.contains(coin.symbol)
                && dataManager.favoriteCoins.contains(coin.symbol)
        }

        if !customCoins.isEmpty {
            let removeMenu = NSMenu()
            let removeItem = NSMenuItem(title: "Remove Custom Coin", action: nil, keyEquivalent: "")
            removeItem.target = self

            for coin in customCoins {
                let item = NSMenuItem(
                    title: "\(coin.name) (\(coin.symbol))",
                    action: #selector(removeCustomCoin(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = coin.symbol
                item.target = self
                item.isEnabled = true
                removeMenu.addItem(item)
            }

            removeItem.submenu = removeMenu
            menu.addItem(removeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Add refresh option with status indicator
        let refreshTitle = isRefreshing ? "Refreshing..." : "Refresh Prices"
        let refreshItem = NSMenuItem(
            title: refreshTitle, action: #selector(refreshPrices), keyEquivalent: "r")
        refreshItem.target = self
        if isRefreshing {
            refreshItem.isEnabled = false
        }
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Add about menu item
        let aboutItem = NSMenuItem(
            title: "About PantawCoin", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Add quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Update status bar item
        updateStatusBarDisplay()
    }

    private func updateStatusBarDisplay() {
        guard let button = statusItem.button else { return }

        // Find the primary coin
        let primarySymbol = CryptoDataManager.shared.primaryCoin

        if let primaryCoin = cryptoCoins.first(where: { $0.symbol == primarySymbol }),
            CryptoDataManager.shared.favoriteCoins.contains(primarySymbol)
        {
            let priceText = primaryCoin.formattedPrice

            // Download and set the coin image
            primaryCoin.downloadImage { image in
                DispatchQueue.main.async {
                    if let image = image {
                        // Resize the image to fit in the menu bar (16x16 pixels)
                        let resizedImage = self.resizeImage(
                            image: image, to: NSSize(width: 16, height: 16))
                        button.image = resizedImage
                    } else {
                        // Fallback to default icon if image download fails
                        button.image = NSImage(
                            systemSymbolName: "bitcoinsign.circle",
                            accessibilityDescription: "Crypto")
                    }

                    // Create attributed string for the status bar
                    let statusText = NSMutableAttributedString()

                    // Add price part
                    statusText.append(
                        NSAttributedString(
                            string: priceText,
                            attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor]
                        ))

                    // Add price change if available
                    if let change = primaryCoin.priceChangePercentage24h,
                        !primaryCoin.formattedPriceChange.isEmpty
                    {
                        let changeColor: NSColor = change >= 0 ? .green : .red
                        let changeText = " \(primaryCoin.formattedPriceChange)"

                        statusText.append(
                            NSAttributedString(
                                string: changeText,
                                attributes: [NSAttributedString.Key.foregroundColor: changeColor]
                            ))
                    }

                    button.attributedTitle = statusText
                }
            }
        } else if let btcCoin = cryptoCoins.first(where: { $0.symbol == "BTC" }),
            CryptoDataManager.shared.favoriteCoins.contains("BTC")
        {
            // Fallback to BTC if primary not found
            let priceText = btcCoin.formattedPrice

            // Download and set the BTC image
            btcCoin.downloadImage { image in
                DispatchQueue.main.async {
                    if let image = image {
                        // Resize the image to fit in the menu bar (16x16 pixels)
                        let resizedImage = self.resizeImage(
                            image: image, to: NSSize(width: 16, height: 16))
                        button.image = resizedImage
                    } else {
                        // Fallback to default icon if image download fails
                        button.image = NSImage(
                            systemSymbolName: "bitcoinsign.circle",
                            accessibilityDescription: "Crypto")
                    }

                    let statusText = NSMutableAttributedString(
                        string: priceText,
                        attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor]
                    )

                    // Add price change if available
                    if let change = btcCoin.priceChangePercentage24h,
                        !btcCoin.formattedPriceChange.isEmpty
                    {
                        let changeColor: NSColor = change >= 0 ? .green : .red
                        let changeText = " \(btcCoin.formattedPriceChange)"

                        statusText.append(
                            NSAttributedString(
                                string: changeText,
                                attributes: [NSAttributedString.Key.foregroundColor: changeColor]
                            ))
                    }

                    button.attributedTitle = statusText
                }
            }
        } else if let firstFavoriteCoin = cryptoCoins.first(where: {
            CryptoDataManager.shared.favoriteCoins.contains($0.symbol)
        }) {
            // Fallback to first favorite
            // Download and set the first favorite coin image
            firstFavoriteCoin.downloadImage { image in
                DispatchQueue.main.async {
                    if let image = image {
                        // Resize the image to fit in the menu bar (16x16 pixels)
                        let resizedImage = self.resizeImage(
                            image: image, to: NSSize(width: 16, height: 16))
                        button.image = resizedImage
                    } else {
                        // Fallback to default icon if image download fails
                        button.image = NSImage(
                            systemSymbolName: "bitcoinsign.circle",
                            accessibilityDescription: "Crypto")
                    }

                    let statusText = NSMutableAttributedString(
                        string: "\(firstFavoriteCoin.formattedPrice)",
                        attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor]
                    )

                    // Add price change if available
                    if let change = firstFavoriteCoin.priceChangePercentage24h,
                        !firstFavoriteCoin.formattedPriceChange.isEmpty
                    {
                        let changeColor: NSColor = change >= 0 ? .green : .red
                        let changeText = " \(firstFavoriteCoin.formattedPriceChange)"

                        statusText.append(
                            NSAttributedString(
                                string: changeText,
                                attributes: [NSAttributedString.Key.foregroundColor: changeColor]
                            ))
                    }

                    button.attributedTitle = statusText
                }
            }
        } else {
            button.image = NSImage(
                systemSymbolName: "bitcoinsign.circle", accessibilityDescription: "Crypto")
            button.title = "No favorites"
        }
    }

    // Helper method to resize images
    private func resizeImage(image: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0)

        resizedImage.unlockFocus()
        return resizedImage
    }

    private func fetchCryptoPrices() {
        isRefreshing = true
        updateMenu()

        CryptoDataManager.shared.fetchPrices { [weak self] coins in
            guard let self = self else { return }
            self.cryptoCoins = coins
            self.isRefreshing = false
            self.updateMenu()
        }
    }

    @objc private func setPrimaryCoin(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else {
            print("Error: No symbol found in menu item")
            return
        }

        print("Setting primary coin: \(symbol)")
        CryptoDataManager.shared.setPrimaryCoin(symbol: symbol)

        // Find the coin name for the notification
        let coinName = cryptoCoins.first(where: { $0.symbol == symbol })?.name ?? symbol
        print("Primary coin set to \(coinName) (\(symbol))")

        // Update the status bar display immediately
        updateStatusBarDisplay()

        // Update the menu to reflect the new primary coin
        updateMenu()

        // Notifications are disabled to prevent crashes in command-line builds
    }

    @objc private func removeCustomCoin(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }

        print("Removing custom coin: \(symbol)")
        CryptoDataManager.shared.removeCustomCoin(symbol: symbol)
        fetchCryptoPrices()
    }

    @objc private func toggleFavorite(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }

        print("Toggling favorite: \(symbol)")
        var favorites = CryptoDataManager.shared.favoriteCoins

        if favorites.contains(symbol) {
            favorites.removeAll { $0 == symbol }

            // If removing the primary coin, set a new primary
            if CryptoDataManager.shared.primaryCoin == symbol {
                if favorites.contains("BTC") {
                    CryptoDataManager.shared.primaryCoin = "BTC"
                } else if !favorites.isEmpty {
                    CryptoDataManager.shared.primaryCoin = favorites[0]
                }
            }
        } else {
            favorites.append(symbol)

            // If this is the first favorite, make it primary
            if favorites.count == 1 {
                CryptoDataManager.shared.primaryCoin = symbol
            }
        }

        CryptoDataManager.shared.favoriteCoins = favorites
        updateMenu()
    }

    @objc private func refreshPrices() {
        if !isRefreshing {
            // Show a notification that we're refreshing
            let refreshItem =
                menu.item(withTitle: "Refresh Prices") ?? menu.item(withTitle: "Refreshing...")
            refreshItem?.title = "Refreshing..."
            refreshItem?.isEnabled = false

            // Add a delay before refreshing to avoid hitting rate limits
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.fetchCryptoPrices()
            }
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func resetToDefaultFavorites() {
        print("Resetting to default favorites")
        CryptoDataManager.shared.resetToDefaultFavorites()
        fetchCryptoPrices()
    }

    @objc private func showAbout() {
        print("Showing About dialog")

        // If the window controller already exists, just bring it to front
        if let existingController = aboutWindowController {
            existingController.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create a new window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)

        window.title = "About PantawCoin"
        window.center()
        window.isReleasedWhenClosed = false

        // Create a view controller for the window
        let viewController = NSViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        viewController.view = view

        // Add app icon (larger size)
        let iconView = NSImageView(frame: NSRect(x: 150, y: 180, width: 100, height: 100))
        if let appIcon = self.appIcon {
            // Create a larger version of the icon
            let resizedIcon = resizeImage(image: appIcon, to: NSSize(width: 100, height: 100))
            iconView.image = resizedIcon
        } else {
            let fallbackIcon = NSImage(
                systemSymbolName: "bitcoinsign.circle", accessibilityDescription: "PantawCoin")
            iconView.image = fallbackIcon
        }
        view.addSubview(iconView)

        // Add app name
        let nameLabel = NSTextField(frame: NSRect(x: 0, y: 150, width: 400, height: 24))
        nameLabel.stringValue = "PantawCoin"
        nameLabel.alignment = .center
        nameLabel.isBezeled = false
        nameLabel.isEditable = false
        nameLabel.drawsBackground = false
        nameLabel.font = NSFont.boldSystemFont(ofSize: 18)
        view.addSubview(nameLabel)

        // Add version
        let versionLabel = NSTextField(frame: NSRect(x: 0, y: 120, width: 400, height: 20))
        versionLabel.stringValue = "Version \(APP_VERSION)"
        versionLabel.alignment = .center
        versionLabel.isBezeled = false
        versionLabel.isEditable = false
        versionLabel.drawsBackground = false
        view.addSubview(versionLabel)

        // Add copyright
        let copyrightLabel = NSTextField(frame: NSRect(x: 0, y: 90, width: 400, height: 20))
        copyrightLabel.stringValue = APP_COPYRIGHT
        copyrightLabel.alignment = .center
        copyrightLabel.isBezeled = false
        copyrightLabel.isEditable = false
        copyrightLabel.drawsBackground = false
        view.addSubview(copyrightLabel)

        // Add description
        let descLabel = NSTextField(frame: NSRect(x: 20, y: 50, width: 360, height: 40))
        descLabel.stringValue = "A simple cryptocurrency price tracker for your menu bar."
        descLabel.alignment = .center
        descLabel.isBezeled = false
        descLabel.isEditable = false
        descLabel.drawsBackground = false
        descLabel.isSelectable = false
        descLabel.lineBreakMode = .byWordWrapping
        view.addSubview(descLabel)

        // Add OK button
        let okButton = NSButton(frame: NSRect(x: 150, y: 15, width: 100, height: 32))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.target = self
        okButton.action = #selector(closeAboutWindow)
        view.addSubview(okButton)

        // Set the content view controller
        window.contentViewController = viewController

        // Create a window controller to manage the window
        let windowController = NSWindowController(window: window)

        // Store references
        aboutWindow = window
        aboutWindowController = windowController

        // Set up window close notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(aboutWindowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )

        // Show the window
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func closeAboutWindow() {
        aboutWindowController?.close()
    }

    @objc private func aboutWindowWillClose(_ notification: Notification) {
        // Don't release the window and controller yet
        // Just hide the window
        aboutWindow?.orderOut(nil)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// Create app delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var cryptoApp: CryptoMenuBarApp?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for reset argument
        if CommandLine.arguments.contains("--reset") {
            print("Resetting all settings...")
            UserDefaults.standard.removeObject(forKey: "favoriteCoins")
            UserDefaults.standard.removeObject(forKey: "primaryCoin")
            UserDefaults.standard.removeObject(forKey: "customCoins")
            UserDefaults.standard.synchronize()
        }

        cryptoApp = CryptoMenuBarApp()
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
