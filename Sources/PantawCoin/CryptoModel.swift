import Cocoa
import Foundation

struct CryptoCoin: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    var price: Double
    var priceChangePercentage24h: Double?
    var imageUrl: String?  // Add image URL field

    init(
        id: String, symbol: String, name: String, price: Double,
        priceChangePercentage24h: Double? = nil, imageUrl: String? = nil
    ) {
        self.id = id
        self.symbol = symbol.uppercased()
        self.name = name
        self.price = price
        self.priceChangePercentage24h = priceChangePercentage24h
        self.imageUrl = imageUrl
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        if price < 1.0 {
            formatter.minimumFractionDigits = 4
        } else if price < 10.0 {
            formatter.minimumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    var formattedPriceChange: String {
        guard let change = priceChangePercentage24h else {
            return ""
        }

        let prefix = change >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", change))%"
    }

    var isPositiveChange: Bool {
        return priceChangePercentage24h ?? 0 >= 0
    }

    // Method to download the coin image
    func downloadImage(completion: @escaping (NSImage?) -> Void) {
        guard let imageUrlString = imageUrl, let url = URL(string: imageUrlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            let image = NSImage(data: data)
            completion(image)
        }.resume()
    }
}

class CryptoDataManager {
    static let shared = CryptoDataManager()

    private let baseURL = "https://api.coingecko.com/api/v3"
    // Add API key parameter - you'll need to get a free API key from CoinGecko
    private let apiKey = ""  // Add your API key here if you have one

    // Cache settings
    private var cachedCoins: [CryptoCoin] = []
    private var lastFetchTime: Date?
    private let minimumCacheInterval: TimeInterval = 60 * 5  // 5 minutes

    // Rate limiting settings
    private var retryCount = 0
    private let maxRetries = 3
    private var isRetrying = false

    let defaultCoins = [
        "bitcoin": "BTC",
        "ethereum": "ETH",
        "solana": "SOL",
        "cardano": "ADA",
        "binancecoin": "BNB",
        "dogecoin": "DOGE",
        "ripple": "XRP",
        "pi-network-iou": "PI",
        "sui": "SUI",
        "avalanche-2": "AVAX",
        "matic-network": "MATIC",
        "litecoin": "LTC",
        "chainlink": "LINK",
        "the-open-network": "TON",
        "aave": "AAVE",
        "stellar": "XLM",
        "cosmos": "ATOM",
        "polkadot": "DOT",
        "uniswap": "UNI",
    ]

    // Dictionary to store custom coins added by the user
    private var customCoins: [String: String] = [:]

    var favoriteCoins: [String] {
        get {
            if let coins = UserDefaults.standard.stringArray(forKey: "favoriteCoins") {
                return coins
            }
            // Set only BTC, ETH, and SOL as default favorites
            return ["BTC", "ETH", "SOL"]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "favoriteCoins")
        }
    }

    var primaryCoin: String {
        get {
            return UserDefaults.standard.string(forKey: "primaryCoin") ?? "BTC"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "primaryCoin")
        }
    }

    var allCoins: [String: String] {
        var coins = defaultCoins
        for (id, symbol) in customCoins {
            coins[id] = symbol
        }
        return coins
    }

    init() {
        loadCustomCoins()

        // Ensure primary coin is valid
        validatePrimaryCoin()
    }

    private func validatePrimaryCoin() {
        let current = primaryCoin

        // If the primary coin is not in favorites, set it to a default
        if !favoriteCoins.contains(current) {
            if favoriteCoins.contains("BTC") {
                primaryCoin = "BTC"
            } else if !favoriteCoins.isEmpty {
                primaryCoin = favoriteCoins[0]
            }
        }
    }

    private func loadCustomCoins() {
        if let savedCoins = UserDefaults.standard.dictionary(forKey: "customCoins")
            as? [String: String]
        {
            customCoins = savedCoins
        }
    }

    private func saveCustomCoins() {
        UserDefaults.standard.set(customCoins, forKey: "customCoins")
    }

    func addCustomCoin(symbol: String, completion: @escaping (Bool, String?) -> Void) {
        // Check if the coin already exists
        if defaultCoins.values.contains(symbol) || customCoins.values.contains(symbol) {
            completion(false, "This coin is already in your list.")
            return
        }

        // Search for the coin ID using CoinGecko API
        searchCoinId(for: symbol) { [weak self] coinId, error in
            guard let self = self else { return }

            if let coinId = coinId {
                self.customCoins[coinId] = symbol
                self.saveCustomCoins()

                // Add to favorites if not already there
                var favorites = self.favoriteCoins
                if !favorites.contains(symbol) {
                    favorites.append(symbol)
                    self.favoriteCoins = favorites
                }

                completion(true, nil)
            } else {
                completion(
                    false,
                    error
                        ?? "Could not find this cryptocurrency. Please check the symbol and try again."
                )
            }
        }
    }

    func removeCustomCoin(symbol: String) {
        if let coinId = customCoins.first(where: { $0.value == symbol })?.key {
            customCoins.removeValue(forKey: coinId)
            saveCustomCoins()

            // Also remove from favorites if present
            var favorites = favoriteCoins
            favorites.removeAll { $0 == symbol }
            favoriteCoins = favorites

            // If this was the primary coin, reset to BTC or first available
            if primaryCoin == symbol {
                if favorites.contains("BTC") {
                    primaryCoin = "BTC"
                } else if !favorites.isEmpty {
                    primaryCoin = favorites[0]
                } else {
                    primaryCoin = "BTC"
                }
            }
        }
    }

    func setPrimaryCoin(symbol: String) {
        // Make sure the coin is in favorites
        if !favoriteCoins.contains(symbol) {
            var favorites = favoriteCoins
            favorites.append(symbol)
            favoriteCoins = favorites
        }

        // Set as primary and ensure it's saved immediately
        primaryCoin = symbol
        UserDefaults.standard.synchronize()

        print("Primary coin set to \(symbol) and saved to UserDefaults")
    }

    // Reset favorites to only BTC, ETH, and SOL
    func resetToDefaultFavorites() {
        favoriteCoins = ["BTC", "ETH", "SOL"]

        // If the primary coin is not in the default favorites, set it to BTC
        if !favoriteCoins.contains(primaryCoin) {
            primaryCoin = "BTC"
        }

        UserDefaults.standard.synchronize()
        print("Favorites reset to BTC, ETH, and SOL")
    }

    // Get details about the current primary coin
    func getPrimaryCoinDetails() -> CryptoCoin? {
        let primarySymbol = primaryCoin

        // First check if we have this coin in the cache
        if let cachedCoin = cachedCoins.first(where: {
            $0.symbol.uppercased() == primarySymbol.uppercased()
        }) {
            return cachedCoin
        }

        // Try to find the coin ID for the primary symbol
        if let coinId = symbolToId(primarySymbol) {
            // Fetch the latest data for this coin
            var urlString =
                "\(baseURL)/coins/markets?vs_currency=usd&ids=\(coinId)&order=market_cap_desc&per_page=1&page=1&sparkline=false&price_change_percentage=24h"

            // Add API key if available
            if !apiKey.isEmpty {
                urlString += "&x_cg_pro_api_key=\(apiKey)"
            }

            guard let url = URL(string: urlString) else {
                return nil
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 15  // Increase timeout
            request.addValue("PantawCoin/1.0", forHTTPHeaderField: "User-Agent")

            let semaphore = DispatchSemaphore(value: 0)
            var result: CryptoCoin?

            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                defer { semaphore.signal() }

                // Check for rate limiting
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                    print("Rate limit exceeded when fetching primary coin")
                    // Try to find a default value to return
                    if let defaultCoin = self?.createDefaultCoin(for: primarySymbol) {
                        result = defaultCoin
                    }
                    return
                }

                guard let data = data, error == nil else {
                    // Try to create a default coin on error
                    if let defaultCoin = self?.createDefaultCoin(for: primarySymbol) {
                        result = defaultCoin
                    }
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    struct CoinResponse: Codable {
                        let id: String
                        let symbol: String
                        let name: String
                        let currentPrice: Double
                        let priceChangePercentage24h: Double?
                        let image: String?  // Add image field
                    }

                    let coins = try decoder.decode([CoinResponse].self, from: data)
                    if let coin = coins.first {
                        result = CryptoCoin(
                            id: coin.id,
                            symbol: coin.symbol,
                            name: coin.name,
                            price: coin.currentPrice,
                            priceChangePercentage24h: coin.priceChangePercentage24h,
                            imageUrl: coin.image  // Include the image URL
                        )
                    } else if let defaultCoin = self?.createDefaultCoin(for: primarySymbol) {
                        result = defaultCoin
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                    // Try to create a default coin on error
                    if let defaultCoin = self?.createDefaultCoin(for: primarySymbol) {
                        result = defaultCoin
                    }
                }
            }.resume()

            _ = semaphore.wait(timeout: .now() + 5.0)
            return result
        }

        return createDefaultCoin(for: primarySymbol)
    }

    // Helper method to create a default coin when API fails
    private func createDefaultCoin(for symbol: String) -> CryptoCoin? {
        // Try to find the coin ID
        guard let coinId = symbolToId(symbol) else {
            return nil
        }

        // Create a default name based on the symbol
        let name = coinId.split(separator: "-").map {
            $0.prefix(1).uppercased() + $0.dropFirst().lowercased()
        }.joined(separator: " ")

        return CryptoCoin(
            id: coinId,
            symbol: symbol,
            name: name,
            price: 0.0,
            priceChangePercentage24h: nil,
            imageUrl: nil
        )
    }

    private func searchCoinId(for symbol: String, completion: @escaping (String?, String?) -> Void)
    {
        let urlString = "\(baseURL)/search?query=\(symbol)"

        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error?.localizedDescription ?? "Network error")
                return
            }

            do {
                struct SearchResponse: Codable {
                    let coins: [CoinItem]

                    struct CoinItem: Codable {
                        let id: String
                        let symbol: String
                        let name: String
                    }
                }

                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)

                // Find the exact match for the symbol
                if let exactMatch = searchResponse.coins.first(where: {
                    $0.symbol.lowercased() == symbol.lowercased()
                }) {
                    completion(exactMatch.id, nil)
                } else if let firstResult = searchResponse.coins.first {
                    // If no exact match, use the first result
                    completion(firstResult.id, nil)
                } else {
                    completion(nil, "No results found for \(symbol)")
                }
            } catch {
                completion(nil, "Error parsing response: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchPrices(completion: @escaping ([CryptoCoin]) -> Void) {
        // Check if we have cached data and if it's still fresh
        if !cachedCoins.isEmpty,
            let lastFetch = lastFetchTime,
            Date().timeIntervalSince(lastFetch) < minimumCacheInterval
        {
            print(
                "Using cached data (last fetched \(Int(Date().timeIntervalSince(lastFetch))) seconds ago)"
            )
            completion(cachedCoins)
            return
        }

        let coinIds = allCoins.keys.joined(separator: ",")
        var urlString =
            "\(baseURL)/coins/markets?vs_currency=usd&ids=\(coinIds)&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h"

        // Add API key if available
        if !apiKey.isEmpty {
            urlString += "&x_cg_pro_api_key=\(apiKey)"
        }

        print("Fetching prices for coins: \(allCoins)")
        print("API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            // If URL is invalid, use cached data if available
            if !cachedCoins.isEmpty {
                completion(cachedCoins)
            } else {
                completion([])
            }
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15  // Increase timeout to 15 seconds

        // Add user agent to avoid being blocked
        request.addValue("PantawCoin/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            // Check for HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")

                // Handle rate limiting
                if httpResponse.statusCode == 429 {
                    print("Rate limit exceeded")

                    // If we have cached data, use it
                    if !self.cachedCoins.isEmpty {
                        print("Using cached data due to rate limit")
                        DispatchQueue.main.async {
                            completion(self.cachedCoins)
                        }
                    }

                    // Try to retry with exponential backoff if we haven't reached max retries
                    if self.retryCount < self.maxRetries && !self.isRetrying {
                        self.isRetrying = true
                        self.retryCount += 1
                        let delay = pow(2.0, Double(self.retryCount))  // Exponential backoff
                        print(
                            "Retrying in \(delay) seconds (attempt \(self.retryCount)/\(self.maxRetries))"
                        )

                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            self.isRetrying = false
                            self.fetchPrices(completion: completion)
                        }
                    } else if self.cachedCoins.isEmpty {
                        // If we've reached max retries and have no cache, return empty
                        DispatchQueue.main.async {
                            completion([])
                        }
                    }
                    return
                }
            }

            // Reset retry count on successful request
            self.retryCount = 0

            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")

                // If network error, use cached data if available
                if !self.cachedCoins.isEmpty {
                    print("Using cached data due to network error")
                    DispatchQueue.main.async {
                        completion(self.cachedCoins)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase

                struct CoinResponse: Codable {
                    let id: String
                    let symbol: String
                    let name: String
                    let currentPrice: Double
                    let priceChangePercentage24h: Double?
                    let image: String?  // Add image field
                }

                let coins = try decoder.decode([CoinResponse].self, from: data)
                print("Successfully fetched \(coins.count) coins")

                if coins.isEmpty {
                    // Print the raw response for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("API Response: \(jsonString)")
                    }
                }

                let cryptoCoins = coins.map { coin in
                    CryptoCoin(
                        id: coin.id,
                        symbol: coin.symbol,
                        name: coin.name,
                        price: coin.currentPrice,
                        priceChangePercentage24h: coin.priceChangePercentage24h,
                        imageUrl: coin.image  // Include the image URL
                    )
                }

                // Update cache
                self.cachedCoins = cryptoCoins
                self.lastFetchTime = Date()

                DispatchQueue.main.async {
                    completion(cryptoCoins)
                }
            } catch {
                print("Error decoding JSON: \(error)")
                // Print the raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString)")
                }

                // If parsing error, use cached data if available
                if !self.cachedCoins.isEmpty {
                    print("Using cached data due to parsing error")
                    DispatchQueue.main.async {
                        completion(self.cachedCoins)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            }
        }.resume()
    }

    func symbolToId(_ symbol: String) -> String? {
        if let id = defaultCoins.first(where: { $0.value == symbol.uppercased() })?.key {
            return id
        }
        return customCoins.first(where: { $0.value == symbol.uppercased() })?.key
    }

    func idToSymbol(_ id: String) -> String {
        return allCoins[id] ?? id.uppercased()
    }
}
