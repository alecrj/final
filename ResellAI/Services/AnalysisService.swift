//
//  AnalysisService.swift
//  ResellAI
//
//  GPT-5 Analysis System - Fixed for Real API
//

import SwiftUI
import Foundation
import Vision

// MARK: - ANALYSIS SERVICE WITH GPT-5
class AIAnalysisService: ObservableObject {
    private let apiKey = Configuration.openAIKey
    private let endpoint = "https://api.openai.com/v1/responses"
    
    // Retry configuration
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    // Market data service
    private let marketDataService = EbayMarketDataService()
    
    // MARK: - MAIN ANALYSIS FUNCTION
    func analyzeItemWithMarketIntelligence(images: [UIImage], completion: @escaping (ExpertAnalysisResult?) -> Void) {
        guard !apiKey.isEmpty else {
            print("❌ API key not configured")
            completion(nil)
            return
        }
        
        guard !images.isEmpty else {
            print("❌ No images provided")
            completion(nil)
            return
        }
        
        print("🧠 Starting GPT-5 analysis with \(images.count) images")
        
        // Process images to extract text first
        extractTextFromImages(images) { [weak self] extractedText in
            self?.analyzeWithMarketIntelligence(images: images, ocrText: extractedText, completion: completion)
        }
    }
    
    // MARK: - EXTRACT TEXT FROM IMAGES
    private func extractTextFromImages(_ images: [UIImage], completion: @escaping (String) -> Void) {
        var allText: [String] = []
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            
            guard let cgImage = image.cgImage else {
                group.leave()
                continue
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                defer { group.leave() }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                if !recognizedText.isEmpty {
                    allText.append(recognizedText)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            try? requestHandler.perform([request])
        }
        
        group.notify(queue: .main) {
            let combinedText = allText.joined(separator: "\n")
            print("📝 Extracted OCR text: \(combinedText.prefix(200))...")
            completion(combinedText)
        }
    }
    
    // MARK: - ANALYSIS WITH MARKET INTELLIGENCE
    private func analyzeWithMarketIntelligence(images: [UIImage], ocrText: String, completion: @escaping (ExpertAnalysisResult?) -> Void) {
        // First, try to identify the item from OCR text to fetch market data
        let searchQuery = buildMarketSearchQuery(from: ocrText)
        let category = extractCategory(from: ocrText)
        
        print("🔍 Searching market data for: \(searchQuery)")
        
        // Fetch market data in parallel with AI analysis
        marketDataService.fetchSoldListings(
            query: searchQuery,
            category: category,
            condition: nil
        ) { [weak self] marketData in
            // Proceed with GPT-5 analysis using market data
            self?.analyzeWithGPT5(
                images: images, 
                ocrText: ocrText,
                marketData: marketData,
                completion: completion
            )
        }
    }
    
    // MARK: - MARKET SEARCH QUERY BUILDER
    private func buildMarketSearchQuery(from ocrText: String) -> String {
        let text = ocrText.lowercased()
        var searchTerms: [String] = []
        
        // Look for brands first
        for brand in Configuration.luxuryBrands + Configuration.hypeBrands {
            if text.contains(brand.lowercased()) {
                searchTerms.append(brand)
                break // Use first found brand
            }
        }
        
        // Look for product identifiers
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            // Style codes, model numbers, etc.
            if word.count >= 3 && word.count <= 15 && 
               (word.rangeOfCharacter(from: .alphanumerics.inverted) == nil ||
                word.contains("-") || word.contains("/")) {
                searchTerms.append(word)
                if searchTerms.count >= 3 { break }
            }
        }
        
        // If no specific terms found, use a broader search
        if searchTerms.isEmpty {
            // Extract potential product words
            let productWords = words.filter { word in
                word.count >= 4 && 
                !["the", "and", "with", "from", "size", "color", "new", "used"].contains(word)
            }
            searchTerms = Array(productWords.prefix(2))
        }
        
        let query = searchTerms.joined(separator: " ")
        return query.isEmpty ? "item" : query
    }
    
    private func extractCategory(from ocrText: String) -> String? {
        let text = ocrText.lowercased()
        
        // Check for common categories
        for (category, _) in Configuration.ebayCategoryMappings {
            if text.contains(category.lowercased()) {
                return category
            }
        }
        
        return nil
    }
    
    // MARK: - GPT-5 ANALYSIS
    private func analyzeWithGPT5(
        images: [UIImage], 
        ocrText: String, 
        marketData: MarketDataResult?,
        completion: @escaping (ExpertAnalysisResult?) -> Void
    ) {
        let prompt = buildAnalysisPrompt(ocrText: ocrText, marketData: marketData)
        
        // Smart three-tier model selection
        let model = selectOptimalModel(images: images, ocrText: ocrText)
        
        // Log market data availability
        if let marketData = marketData {
            print("📊 Using market data: \(marketData.soldListings.count) sold listings")
            if let median = marketData.medianPrice {
                print("💰 Market median price: $\(String(format: "%.2f", median))")
            }
        } else {
            print("⚠️ No market data available - using AI-only pricing")
        }
        
        // Perform analysis with retry logic
        performAnalysisWithRetry(
            model: model,
            images: images,
            prompt: prompt,
            attempt: 1,
            completion: completion
        )
    }
    
    // MARK: - ANALYSIS WITH RETRY LOGIC
    private func performAnalysisWithRetry(
        model: String,
        images: [UIImage],
        prompt: String,
        attempt: Int,
        completion: @escaping (ExpertAnalysisResult?) -> Void
    ) {
        performGPT5Analysis(model: model, images: images, prompt: prompt) { [weak self] result in
            guard let self = self else {
                completion(nil)
                return
            }
            
            if let result = result {
                // Success
                completion(result)
            } else if attempt < self.maxRetries {
                // Retry with exponential backoff
                let delay = self.baseDelay * pow(2.0, Double(attempt - 1))
                print("🔄 Attempt \(attempt) failed, retrying in \(delay)s...")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Potentially escalate model on retry
                    let retryModel = attempt >= 2 && model != "gpt-5" ? "gpt-5" : model
                    if retryModel != model {
                        print("⬆️ Escalating to \(retryModel) for retry \(attempt + 1)")
                    }
                    
                    self.performAnalysisWithRetry(
                        model: retryModel,
                        images: images,
                        prompt: prompt,
                        attempt: attempt + 1,
                        completion: completion
                    )
                }
            } else {
                // All retries exhausted
                print("❌ All \(self.maxRetries) attempts failed")
                completion(nil)
            }
        }
    }
    
    // MARK: - SMART MODEL SELECTION (THREE-TIER)
    private func selectOptimalModel(images: [UIImage], ocrText: String) -> String {
        let ocrLower = ocrText.lowercased()
        
        // Check for luxury brands → gpt-5
        for brand in Configuration.luxuryBrands {
            if ocrLower.contains(brand.lowercased()) {
                print("💎 Luxury brand detected: \(brand) - using gpt-5 for maximum accuracy")
                return "gpt-5"
            }
        }
        
        // Check for hype brands → gpt-5
        for brand in Configuration.hypeBrands {
            if ocrLower.contains(brand.lowercased()) {
                print("🔥 Hype brand detected: \(brand) - using gpt-5")
                return "gpt-5"
            }
        }
        
        // Check for easy categories → gpt-5-nano
        for category in Configuration.easyCategories {
            if ocrLower.contains(category.lowercased()) {
                print("📚 Easy category detected: \(category) - using gpt-5-nano for speed")
                return "gpt-5-nano"
            }
        }
        
        // Check for clear identifiers (UPC, ISBN, etc.) → gpt-5-nano
        if ocrText.contains(where: { $0.isNumber }) && ocrText.count > 10 {
            if ocrLower.contains("isbn") || ocrLower.contains("upc") || ocrLower.contains("ean") {
                print("📊 Clear product identifier detected - using gpt-5-nano")
                return "gpt-5-nano"
            }
        }
        
        // Check text clarity and image count
        if ocrText.count < 20 || images.count > 5 {
            print("⚠️ Complex analysis needed (limited text or multiple images) - using gpt-5")
            return "gpt-5"
        }
        
        // Default to balanced model
        print("⚖️ Standard item detected - using gpt-5-mini for balanced performance")
        return "gpt-5-mini"
    }
    
    // MARK: - GPT-5 API CALL (CORRECTED FOR RESPONSES API)
    private func performGPT5Analysis(
        model: String,
        images: [UIImage],
        prompt: String,
        completion: @escaping (ExpertAnalysisResult?) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(nil)
            return
        }
        
        // Build message content with images for GPT-5 Vision
        var messageContent: [[String: Any]] = [
            ["type": "text", "text": prompt]
        ]
        
        // Add images to content array
        for image in images.prefix(5) { // Limit to 5 images
            if let imageData = compressImage(image) {
                let base64Image = imageData.base64EncodedString()
                let imageUrl = "data:image/jpeg;base64,\(base64Image)"
                
                messageContent.append([
                    "type": "image_url",
                    "image_url": ["url": imageUrl]
                ])
            }
        }
        
        // Build proper GPT-5 Responses API request
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": messageContent
                ]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3,
            "max_tokens": 4096,
            "timeout": 60
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90 // Generous timeout for complex analysis
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            request.httpBody = jsonData
            
            // Log request for debugging (without showing full images)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let truncated = jsonString.prefix(500) + "..."
                print("📤 GPT-5 Request: \(truncated)")
            }
        } catch {
            print("❌ Error encoding request: \(error)")
            completion(nil)
            return
        }
        
        print("🚀 Calling \(model) with \(images.count) images")
        print("💰 Estimated cost: $\(estimateRequestCost(model: model, images: images))")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 API Response: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        if let data = data, let errorString = String(data: data, encoding: .utf8) {
                            print("❌ API Error (\(httpResponse.statusCode)): \(errorString)")
                        }
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ No response data")
                    completion(nil)
                    return
                }
                
                // Parse the response
                if let result = self?.parseGPT5Response(data, model: model) {
                    completion(result)
                } else {
                    print("❌ Failed to parse GPT-5 response")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - COST ESTIMATION
    private func estimateRequestCost(model: String, images: [UIImage]) -> String {
        // Rough token estimation: ~300 tokens per image + 2000 for prompt
        let estimatedInputTokens = 2000 + (images.count * 300)
        let estimatedOutputTokens = 1000
        
        let (inputCost, outputCost): (Double, Double) = {
            switch model {
            case "gpt-5-nano":
                return (0.05, 0.40) // per 1M tokens
            case "gpt-5-mini":
                return (0.25, 2.00)
            case "gpt-5":
                return (1.25, 10.00)
            default:
                return (0.25, 2.00)
            }
        }()
        
        let totalCost = (Double(estimatedInputTokens) / 1_000_000 * inputCost) +
                       (Double(estimatedOutputTokens) / 1_000_000 * outputCost)
        
        return String(format: "%.4f", totalCost)
    }
    
    // MARK: - BUILD ANALYSIS PROMPT
    private func buildAnalysisPrompt(ocrText: String, marketData: MarketDataResult? = nil) -> String {
        var prompt = """
        You are a product-identification expert for resale. Analyze the provided product images and return ONLY a valid JSON object.
        
        OCR_TEXT extracted from images:
        \(ocrText)
        
        """
        
        // Add market data if available
        if let marketData = marketData, !marketData.soldListings.isEmpty {
            let priceTiers = marketData.priceTiers()
            
            prompt += """
            REAL MARKET DATA (use this for accurate pricing):
            • Sold listings found: \(marketData.soldListings.count)
            • Market median price: $\(String(format: "%.2f", priceTiers.market))
            • Quick sale price: $\(String(format: "%.2f", priceTiers.quickSell))
            • Premium price: $\(String(format: "%.2f", priceTiers.premium))
            • Data source: \(marketData.isEstimate ? "Active listings (estimated)" : "Actual sold listings")
            
            Recent sold titles:
            \(marketData.soldListings.prefix(5).map { "• \($0.title) - $\(String(format: "%.2f", $0.price))" }.joined(separator: "\n"))
            
            """
        } else {
            prompt += """
            No specific market data available - use your knowledge of typical resale values.
            
            """
        }
        
        prompt += """
        Return this exact JSON structure:
        {
            "attributes": {
                "brand": "exact brand name or Unknown",
                "model": "model name or null",
                "name": "full product name",
                "category": "product category",
                "size": "size or null",
                "color": "primary color",
                "material": "material or null",
                "condition": {
                    "grade": "New/Like New/Good/Fair/Poor",
                    "score": 1-10,
                    "details": "condition description"
                },
                "defects": ["list of defects or empty array"],
                "identifiers": {
                    "styleCode": "style code or null",
                    "upc": "UPC or null",
                    "sku": "SKU or null",
                    "serialNumber": "serial or null"
                },
                "yearReleased": "year or null",
                "collaboration": "collab name or null",
                "specialEdition": "special edition or null"
            },
            "confidence": 0.0-1.0,
            "evidence": ["specific visual elements that led to identification"],
            "suggestedPrice": {
                "quickSale": price in USD,
                "market": price in USD,
                "premium": price in USD,
                "reasoning": "pricing explanation based on condition and market"
            },
            "listingContent": {
                "title": "eBay title (70-80 chars max)",
                "description": "professional eBay description with condition details",
                "keywords": ["keyword1", "keyword2", "keyword3"],
                "bulletPoints": ["key feature 1", "key feature 2", "key feature 3"]
            },
            "marketAnalysis": {
                "demandLevel": "High/Medium/Low",
                "competitorCount": estimated number or null,
                "recentSales": estimated number or null,
                "seasonalFactors": "seasonal notes or null"
            }
        }
        
        Instructions:
        - Use the OCR_TEXT to help identify style codes, brands, and other text
        - Be precise and accurate in identification
        - If brand is not clearly visible, use "Unknown" rather than guessing
        - CRITICAL: If market data is provided, use those exact prices for your suggestions
        - If no market data: estimate based on condition and typical resale values
        - Create eBay-optimized title with searchable terms matching sold listings
        - If uncertain, set confidence lower
        - Factor in condition when adjusting from market data (lower for poor condition)
        
        CRITICAL: Return ONLY the JSON object, no other text.
        """
        
        return prompt
    }
    
    // MARK: - PARSE GPT-5 RESPONSE (CORRECTED)
    private func parseGPT5Response(_ data: Data, model: String) -> ExpertAnalysisResult? {
        do {
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw GPT-5 response: \(responseString.prefix(500))...")
            }
            
            // Parse GPT-5 Responses API structure
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Invalid JSON response")
                return nil
            }
            
            print("📄 Response keys: \(json.keys.joined(separator: ", "))")
            
            // Extract content from choices array (standard OpenAI format)
            if let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                print("📝 Got message content, length: \(content.count)")
                
                // Log token usage if available
                if let usage = json["usage"] as? [String: Any] {
                    print("🔢 Token usage: \(usage)")
                }
                
                // Clean and parse JSON content
                let cleanedText = extractJSON(from: content)
                
                if let jsonData = cleanedText.data(using: .utf8) {
                    let parsedData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                    
                    // Convert to ExpertAnalysisResult
                    if let result = parseToExpertResult(parsedData, wasEscalated: model == "gpt-5") {
                        print("✅ Analysis complete: \(result.attributes.name)")
                        print("📊 Confidence: \(String(format: "%.2f", result.confidence))")
                        print("💰 Market price: $\(String(format: "%.2f", result.suggestedPrice.market))")
                        print("🤖 Model: \(model)")
                        return result
                    } else {
                        print("❌ Failed to convert to ExpertAnalysisResult")
                        if let parsedData = parsedData {
                            print("📊 Parsed keys: \(parsedData.keys.joined(separator: ", "))")
                        }
                    }
                } else {
                    print("❌ Failed to parse cleaned JSON")
                    print("🔍 Cleaned text: \(cleanedText.prefix(200))...")
                }
            } else {
                print("❌ Unexpected response structure - no choices/message/content found")
                
                // Try alternative response formats
                if let outputText = json["output_text"] as? String {
                    print("📝 Found output_text field, trying to parse...")
                    let cleanedText = extractJSON(from: outputText)
                    
                    if let jsonData = cleanedText.data(using: .utf8),
                       let parsedData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let result = parseToExpertResult(parsedData, wasEscalated: model == "gpt-5") {
                        return result
                    }
                }
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response causing error: \(responseString.prefix(300))...")
            }
        }
        
        return nil
    }
    
    // MARK: - EXTRACT JSON FROM TEXT
    private func extractJSON(from text: String) -> String {
        // Find the first { and last }
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            let jsonSubstring = text[startIndex...endIndex]
            return String(jsonSubstring)
        }
        return text
    }
    
    // MARK: - CONVERT TO EXPERT RESULT
    private func parseToExpertResult(_ json: [String: Any]?, wasEscalated: Bool) -> ExpertAnalysisResult? {
        guard let json = json,
              let attributes = json["attributes"] as? [String: Any],
              let suggestedPrice = json["suggestedPrice"] as? [String: Any],
              let listingContent = json["listingContent"] as? [String: Any] else {
            print("❌ Missing required fields in JSON")
            return nil
        }
        
        // Parse attributes
        let brand = attributes["brand"] as? String ?? "Unknown"
        let model = attributes["model"] as? String
        let name = attributes["name"] as? String ?? "Unknown Item"
        let category = attributes["category"] as? String ?? "Other"
        let size = attributes["size"] as? String
        let color = attributes["color"] as? String
        let material = attributes["material"] as? String
        
        // Parse condition
        let conditionData = attributes["condition"] as? [String: Any] ?? [:]
        let conditionGrade = conditionData["grade"] as? String ?? "Good"
        let conditionScore = conditionData["score"] as? Int ?? 7
        let conditionDetails = conditionData["details"] as? String ?? ""
        
        // Parse identifiers
        let identifiersData = attributes["identifiers"] as? [String: Any] ?? [:]
        let styleCode = identifiersData["styleCode"] as? String
        let upc = identifiersData["upc"] as? String
        let sku = identifiersData["sku"] as? String
        let serialNumber = identifiersData["serialNumber"] as? String
        
        // Parse other attributes
        let defects = attributes["defects"] as? [String] ?? []
        let yearReleased = attributes["yearReleased"] as? String
        let collaboration = attributes["collaboration"] as? String
        let specialEdition = attributes["specialEdition"] as? String
        
        // Parse main response data
        let confidence = json["confidence"] as? Double ?? 0.7
        let evidence = json["evidence"] as? [String] ?? []
        
        // Parse pricing
        let quickSale = suggestedPrice["quickSale"] as? Double ?? 0
        let market = suggestedPrice["market"] as? Double ?? 0
        let premium = suggestedPrice["premium"] as? Double ?? 0
        let reasoning = suggestedPrice["reasoning"] as? String ?? ""
        
        // Parse listing content
        let title = listingContent["title"] as? String ?? ""
        let description = listingContent["description"] as? String ?? ""
        let keywords = listingContent["keywords"] as? [String] ?? []
        let bulletPoints = listingContent["bulletPoints"] as? [String] ?? []
        
        // Parse market analysis
        let marketAnalysis = json["marketAnalysis"] as? [String: Any]
        let demandLevel = marketAnalysis?["demandLevel"] as? String
        let competitorCount = marketAnalysis?["competitorCount"] as? Int
        let recentSales = marketAnalysis?["recentSales"] as? Int
        let seasonalFactors = marketAnalysis?["seasonalFactors"] as? String
        
        // Create ExpertAnalysisResult
        let itemAttributes = ExpertAnalysisResult.ItemAttributes(
            brand: brand,
            model: model,
            name: name,
            category: category,
            size: size,
            color: color,
            material: material,
            condition: ExpertAnalysisResult.ConditionGrade(
                grade: conditionGrade,
                score: conditionScore,
                details: conditionDetails
            ),
            defects: defects,
            identifiers: ExpertAnalysisResult.ItemIdentifiers(
                styleCode: styleCode,
                upc: upc,
                sku: sku,
                serialNumber: serialNumber
            ),
            yearReleased: yearReleased,
            collaboration: collaboration,
            specialEdition: specialEdition
        )
        
        let pricingStrategy = ExpertAnalysisResult.PricingStrategy(
            quickSale: quickSale,
            market: market,
            premium: premium,
            reasoning: reasoning
        )
        
        let content = ExpertAnalysisResult.ListingContent(
            title: title,
            description: description,
            keywords: keywords,
            bulletPoints: bulletPoints
        )
        
        let insights = marketAnalysis != nil ? ExpertAnalysisResult.MarketInsights(
            demandLevel: demandLevel ?? "Medium",
            competitorCount: competitorCount,
            recentSales: recentSales,
            seasonalFactors: seasonalFactors
        ) : nil
        
        return ExpertAnalysisResult(
            attributes: itemAttributes,
            confidence: confidence,
            evidence: evidence,
            suggestedPrice: pricingStrategy,
            listingContent: content,
            marketAnalysis: insights,
            escalatedToGPT5: wasEscalated
        )
    }
    
    // MARK: - IMAGE COMPRESSION
    private func compressImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        
        let size = image.size
        let ratio = min(maxDimension/size.width, maxDimension/size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let resizedImage: UIImage
        if ratio < 1.0 {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // Compress to ~500KB max per image for GPT-5
        var compression: CGFloat = 0.8
        var data = resizedImage.jpegData(compressionQuality: compression)
        
        while let imageData = data, imageData.count > 500_000, compression > 0.3 {
            compression -= 0.1
            data = resizedImage.jpegData(compressionQuality: compression)
        }
        
        return data
    }
}
