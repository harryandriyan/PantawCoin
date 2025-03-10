import XCTest

@testable import PantawCoin

final class PantawCoinTests: XCTestCase {
    func testCryptoCoinFormatting() {
        // Test price formatting for different price ranges
        let lowPriceCoin = CryptoCoin(
            id: "test1", symbol: "TEST1", name: "Test Coin 1", price: 0.00123)
        XCTAssertTrue(
            lowPriceCoin.formattedPrice.contains("0.0012"), "Low price should show 4 decimal places"
        )

        let mediumPriceCoin = CryptoCoin(
            id: "test2", symbol: "TEST2", name: "Test Coin 2", price: 5.67)
        XCTAssertTrue(
            mediumPriceCoin.formattedPrice.contains("5.67"),
            "Medium price should show 2 decimal places")

        let highPriceCoin = CryptoCoin(
            id: "test3", symbol: "TEST3", name: "Test Coin 3", price: 45678.9)
        XCTAssertFalse(
            highPriceCoin.formattedPrice.contains("."), "High price should not show decimal places")
    }

    func testPriceChangeFormatting() {
        // Test positive price change
        let positiveCoin = CryptoCoin(
            id: "pos", symbol: "POS", name: "Positive Coin", price: 100,
            priceChangePercentage24h: 5.67)
        XCTAssertTrue(
            positiveCoin.formattedPriceChange.contains("+5.67%"),
            "Positive change should have + prefix")
        XCTAssertTrue(positiveCoin.isPositiveChange, "Should detect positive change")

        // Test negative price change
        let negativeCoin = CryptoCoin(
            id: "neg", symbol: "NEG", name: "Negative Coin", price: 100,
            priceChangePercentage24h: -2.34)
        XCTAssertTrue(
            negativeCoin.formattedPriceChange.contains("-2.34%"),
            "Negative change should have - prefix")
        XCTAssertFalse(negativeCoin.isPositiveChange, "Should detect negative change")

        // Test nil price change
        let nilChangeCoin = CryptoCoin(
            id: "nil", symbol: "NIL", name: "Nil Change Coin", price: 100)
        XCTAssertEqual(
            nilChangeCoin.formattedPriceChange, "", "Nil change should return empty string")
        XCTAssertFalse(nilChangeCoin.isPositiveChange, "Nil change should not be positive")
    }

    func testSymbolMapping() {
        let dataManager = CryptoDataManager.shared

        // Test symbol to ID mapping
        XCTAssertEqual(dataManager.symbolToId("BTC"), "bitcoin")
        XCTAssertEqual(dataManager.symbolToId("ETH"), "ethereum")
        XCTAssertNil(dataManager.symbolToId("UNKNOWN"), "Unknown symbol should return nil")

        // Test ID to symbol mapping
        XCTAssertEqual(dataManager.idToSymbol("bitcoin"), "BTC")
        XCTAssertEqual(dataManager.idToSymbol("ethereum"), "ETH")
        XCTAssertEqual(
            dataManager.idToSymbol("unknown"), "UNKNOWN", "Unknown ID should return uppercase ID")
    }
}
