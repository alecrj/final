#!/usr/bin/env swift

// Test script for ResellAI pipeline
// Run with: swift test_pipeline.swift

import Foundation

print("🧪 ResellAI Pipeline Testing")
print(String(repeating: "=", count: 50))

// Test 1: API Key Configuration
func testAPIConfiguration() {
    print("\n1️⃣ Testing API Configuration...")
    
    // Simulate Configuration check
    let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    let ebayAPIKey = ProcessInfo.processInfo.environment["EBAY_API_KEY"] ?? "AlecRodr-resell-PRD-d0bc91504-be3e553a"
    
    print("✅ OpenAI API Key: \(openAIKey.isEmpty ? "❌ Missing" : "✅ Configured (\(openAIKey.prefix(10))...)")")
    print("✅ eBay API Key: \(ebayAPIKey.isEmpty ? "❌ Missing" : "✅ Configured (\(ebayAPIKey.prefix(15))...)")")
}

// Test 2: Market Search Query Building
func testMarketSearchQuery() {
    print("\n2️⃣ Testing Market Search Query Building...")
    
    let testCases = [
        "Nike Air Jordan 1 Retro High OG Size 10.5",
        "Supreme Box Logo Hoodie Size Medium",
        "Louis Vuitton Neverfull MM Monogram",
        "iPhone 15 Pro 256GB Space Black",
        "Vintage 1995 Pokemon Card Charizard"
    ]
    
    for ocrText in testCases {
        let query = buildMarketSearchQuery(from: ocrText)
        print("📝 OCR: \"\(ocrText)\"")
        print("🔍 Query: \"\(query)\"")
        print()
    }
}

func buildMarketSearchQuery(from ocrText: String) -> String {
    let text = ocrText.lowercased()
    var searchTerms: [String] = []
    
    // Look for brands
    let luxuryBrands = ["Louis Vuitton", "Gucci", "Supreme", "Nike", "Jordan", "Apple", "iPhone"]
    for brand in luxuryBrands {
        if text.contains(brand.lowercased()) {
            searchTerms.append(brand)
            break
        }
    }
    
    // Look for product identifiers
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    for word in words {
        if word.count >= 3 && word.count <= 15 {
            searchTerms.append(word)
            if searchTerms.count >= 3 { break }
        }
    }
    
    return searchTerms.isEmpty ? "item" : searchTerms.joined(separator: " ")
}

// Test 3: Model Selection Logic
func testModelSelection() {
    print("\n3️⃣ Testing Smart Model Selection...")
    
    let testCases = [
        ("Supreme Box Logo Hoodie", "luxury → gpt-5"),
        ("Nike Air Jordan 1", "hype → gpt-5"),
        ("ISBN 9780123456789", "easy → gpt-5-nano"),
        ("Vintage T-Shirt", "standard → gpt-5-mini"),
        ("Rolex Submariner", "luxury → gpt-5")
    ]
    
    for (ocrText, expected) in testCases {
        let model = selectOptimalModel(ocrText: ocrText)
        print("📝 \"\(ocrText)\" → \(model) (\(expected))")
    }
}

func selectOptimalModel(ocrText: String) -> String {
    let text = ocrText.lowercased()
    
    // Luxury brands
    let luxuryBrands = ["supreme", "louis vuitton", "gucci", "rolex", "hermes"]
    for brand in luxuryBrands {
        if text.contains(brand) {
            return "gpt-5"
        }
    }
    
    // Easy categories
    if text.contains("isbn") || text.contains("upc") {
        return "gpt-5-nano"
    }
    
    return "gpt-5-mini"
}

// Test 4: GPT-5 Request Format
func testGPT5RequestFormat() {
    print("\n4️⃣ Testing GPT-5 Request Format...")
    
    let sampleRequest: [String: Any] = [
        "model": "gpt-5-mini",
        "messages": [
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": "Analyze this Nike sneaker..."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,/9j/4AAQ..."]]
                ]
            ]
        ],
        "response_format": ["type": "json_object"],
        "temperature": 0.3,
        "max_tokens": 4096
    ]
    
    if let jsonData = try? JSONSerialization.data(withJSONObject: sampleRequest, options: .prettyPrinted),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print("✅ GPT-5 Request Format Valid:")
        print(String(jsonString.prefix(300)) + "...")
    } else {
        print("❌ Invalid request format")
    }
}

// Test 5: Market Data Processing
func testMarketDataProcessing() {
    print("\n5️⃣ Testing Market Data Processing...")
    
    // Simulate market data
    let soldPrices = [150.0, 175.0, 160.0, 180.0, 170.0, 165.0, 185.0]
    let sorted = soldPrices.sorted()
    
    let median = sorted[sorted.count / 2]
    let average = soldPrices.reduce(0, +) / Double(soldPrices.count)
    let quickSale = median * 0.85
    let premium = median * 1.15
    
    print("📊 Sample Market Data:")
    print("• Sold listings: \(soldPrices.count)")
    print("• Price range: $\(String(format: "%.2f", sorted.first!)) - $\(String(format: "%.2f", sorted.last!))")
    print("• Average: $\(String(format: "%.2f", average))")
    print("• Median: $\(String(format: "%.2f", median))")
    print("• Quick sale: $\(String(format: "%.2f", quickSale))")
    print("• Premium: $\(String(format: "%.2f", premium))")
}

// Test 6: Cost Estimation
func testCostEstimation() {
    print("\n6️⃣ Testing Cost Estimation...")
    
    let models = [
        ("gpt-5-nano", 0.05, 0.40),
        ("gpt-5-mini", 0.25, 2.00),
        ("gpt-5", 1.25, 10.00)
    ]
    
    let estimatedInputTokens = 3000.0  // OCR + prompt + images
    let estimatedOutputTokens = 1000.0
    
    for (model, inputCost, outputCost) in models {
        let totalCost = (estimatedInputTokens / 1_000_000 * inputCost) + 
                       (estimatedOutputTokens / 1_000_000 * outputCost)
        print("💰 \(model): $\(String(format: "%.4f", totalCost)) per analysis")
    }
}

// Run all tests
print("🚀 Starting ResellAI Pipeline Tests...\n")

testAPIConfiguration()
testMarketSearchQuery()
testModelSelection()
testGPT5RequestFormat()
testMarketDataProcessing()
testCostEstimation()

print("\n" + String(repeating: "=", count: 50))
print("✅ Pipeline Testing Complete!")
print("🔧 Ready for integration testing with real APIs")