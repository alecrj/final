#!/usr/bin/env swift

import Foundation

// Test eBay Market Data Service Integration
print("📊 Testing eBay Market Data Service")
print(String(repeating: "=", count: 50))

// Configuration
let ebayAPIKey = ProcessInfo.processInfo.environment["EBAY_API_KEY"] ?? ""
let ebayClientSecret = ProcessInfo.processInfo.environment["EBAY_CLIENT_SECRET"] ?? ""

print("🔧 Configuration:")
print("• eBay API Key: \(ebayAPIKey.prefix(15))...")
print("• Client Secret: \(ebayClientSecret.isEmpty ? "❌ Missing" : "✅ Configured")")

// Test 1: eBay Token Request
func testEbayTokenRequest() {
    print("\n1️⃣ Testing eBay OAuth Token Request...")
    
    let tokenEndpoint = "https://api.ebay.com/identity/v1/oauth2/token"
    
    guard let url = URL(string: tokenEndpoint) else {
        print("❌ Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // Basic auth
    let credentials = "\(ebayAPIKey):\(ebayClientSecret)"
    let credentialsData = credentials.data(using: .utf8)!
    let base64Credentials = credentialsData.base64EncodedString()
    request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
    
    // Request body
    let scope = "https://api.ebay.com/oauth/api_scope"
    let body = "grant_type=client_credentials&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    request.httpBody = body.data(using: .utf8)
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ Network error: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String,
                   let expiresIn = json["expires_in"] as? Int {
                    print("✅ Token received successfully!")
                    print("• Token: \(token.prefix(20))...")
                    print("• Expires in: \(expiresIn) seconds")
                } else {
                    print("❌ Invalid token response format")
                }
            } else {
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorString)")
                }
            }
        }
    }.resume()
    
    semaphore.wait()
}

// Test 2: eBay Browse API Search
func testEbayBrowseAPI(token: String) {
    print("\n2️⃣ Testing eBay Browse API...")
    
    let browseEndpoint = "https://api.ebay.com/buy/browse/v1/item_summary/search"
    var components = URLComponents(string: browseEndpoint)!
    
    components.queryItems = [
        URLQueryItem(name: "q", value: "Nike Air Jordan"),
        URLQueryItem(name: "limit", value: "5")
    ]
    
    guard let url = components.url else {
        print("❌ Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ Network error: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Browse API response: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let itemSummaries = json["itemSummaries"] as? [[String: Any]] {
                    print("✅ Found \(itemSummaries.count) items")
                    
                    for (index, item) in itemSummaries.enumerated() {
                        if let title = item["title"] as? String,
                           let priceDict = item["price"] as? [String: Any],
                           let priceValue = priceDict["value"] as? String {
                            print("  \(index + 1). \(title) - $\(priceValue)")
                        }
                    }
                } else {
                    print("❌ Invalid response format")
                }
            } else {
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("❌ API Error: \(errorString)")
                }
            }
        }
    }.resume()
    
    semaphore.wait()
}

// Test 3: Market Search Query Generation
func testMarketSearchQueries() {
    print("\n3️⃣ Testing Market Search Query Generation...")
    
    let testCases = [
        ("Nike Air Jordan 1 Retro High OG Chicago Size 10", ["nike", "jordan", "chicago"]),
        ("Supreme Box Logo Hoodie FW20 Size Large", ["supreme", "box", "logo"]),
        ("Louis Vuitton Neverfull PM Damier Azur", ["louis", "vuitton", "neverfull"]),
        ("Vintage 1999 Pokemon Base Set Charizard PSA 9", ["pokemon", "charizard", "psa"]),
        ("Apple iPhone 15 Pro Max 256GB Natural Titanium", ["apple", "iphone", "pro"])
    ]
    
    for (ocrText, expectedTerms) in testCases {
        let query = buildSearchQuery(from: ocrText)
        let queryTerms = query.lowercased().components(separatedBy: " ")
        
        let hasExpectedTerms = expectedTerms.allSatisfy { term in
            queryTerms.contains { $0.contains(term) }
        }
        
        print("📝 OCR: \(ocrText)")
        print("🔍 Query: \(query)")
        print("✅ Contains expected terms: \(hasExpectedTerms ? "✅" : "❌")")
        print()
    }
}

func buildSearchQuery(from ocrText: String) -> String {
    let words = ocrText.lowercased().components(separatedBy: .whitespacesAndNewlines)
    let relevantWords = words.filter { word in
        word.count >= 3 &&
        !["the", "and", "size", "with", "from", "new", "used", "set"].contains(word) &&
        word.rangeOfCharacter(from: .letters) != nil
    }
    return Array(relevantWords.prefix(4)).joined(separator: " ")
}

// Test 4: Price Statistics
func testPriceStatistics() {
    print("\n4️⃣ Testing Price Statistics Calculation...")
    
    let testPrices = [120.0, 150.0, 135.0, 180.0, 145.0, 160.0, 175.0, 140.0, 155.0, 165.0]
    let sorted = testPrices.sorted()
    
    let count = sorted.count
    let median = count % 2 == 0 ? (sorted[count/2 - 1] + sorted[count/2]) / 2 : sorted[count/2]
    let average = testPrices.reduce(0, +) / Double(testPrices.count)
    let min = sorted.first!
    let max = sorted.last!
    
    // Calculate percentiles
    let p25Index = Int(Double(count - 1) * 0.25)
    let p75Index = Int(Double(count - 1) * 0.75)
    let p25 = sorted[p25Index]
    let p75 = sorted[p75Index]
    
    print("📊 Price Analysis (10 sold listings):")
    print("• Range: $\(String(format: "%.2f", min)) - $\(String(format: "%.2f", max))")
    print("• Average: $\(String(format: "%.2f", average))")
    print("• Median: $\(String(format: "%.2f", median))")
    print("• 25th percentile: $\(String(format: "%.2f", p25))")
    print("• 75th percentile: $\(String(format: "%.2f", p75))")
    print("")
    print("💰 Recommended Pricing:")
    print("• Quick sale (25th): $\(String(format: "%.2f", p25))")
    print("• Market (median): $\(String(format: "%.2f", median))")
    print("• Premium (75th): $\(String(format: "%.2f", p75))")
}

// Run integration tests
print("🚀 Starting eBay Integration Tests...\n")

// First get a token
testEbayTokenRequest()

// Test query building (no API needed)
testMarketSearchQueries()

// Test price calculations
testPriceStatistics()

print("\n" + String(repeating: "=", count: 50))
print("✅ eBay Integration Testing Complete!")
print("💡 Next: Test with real GPT-5 API calls")