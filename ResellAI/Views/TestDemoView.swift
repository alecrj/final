//
//  TestDemoView.swift
//  ResellAI
//
//  Demo Interface for Testing Pipeline
//

import SwiftUI
import PhotosUI

struct TestDemoView: View {
    @StateObject private var aiService = AIAnalysisService()
    @StateObject private var marketService = EbayMarketDataService()
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isAnalyzing = false
    @State private var analysisResult: ExpertAnalysisResult?
    @State private var marketData: MarketDataResult?
    @State private var testOCRText = "Nike Air Jordan 1 Retro High OG Size 10.5"
    @State private var logs: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ResellAI Pipeline Demo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Test the complete GPT-5 + Market Intelligence pipeline")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Photo Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. Select Photos")
                            .font(.headline)
                        
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Select Photos (\(selectedImages.count) selected)")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 80)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // OCR Text Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("2. OCR Text (or edit manually)")
                            .font(.headline)
                        
                        TextEditor(text: $testOCRText)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Test Buttons
                    VStack(spacing: 12) {
                        Button("🔍 Test Market Data Only") {
                            testMarketData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAnalyzing)
                        
                        Button("🧠 Test Full AI Analysis") {
                            testFullAnalysis()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAnalyzing || selectedImages.isEmpty)
                        
                        Button("📊 Test All Components") {
                            testAllComponents()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isAnalyzing)
                    }
                    
                    Divider()
                    
                    // Results
                    if isAnalyzing {
                        VStack {
                            ProgressView("Analyzing...")
                            Text("This may take 5-15 seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let marketData = marketData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 Market Data Results")
                                .font(.headline)
                            
                            Text("Found: \(marketData.soldListings.count) sold listings")
                            if let median = marketData.medianPrice {
                                Text("Median Price: $\(String(format: "%.2f", median))")
                            }
                            Text("Data Source: \(marketData.isEstimate ? "Estimates" : "Real sold listings")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🤖 AI Analysis Results")
                                .font(.headline)
                            
                            Text("Item: \(result.attributes.name)")
                            Text("Brand: \(result.attributes.brand)")
                            Text("Confidence: \(String(format: "%.1f%%", result.confidence * 100))")
                            Text("Market Price: $\(String(format: "%.2f", result.suggestedPrice.market))")
                            Text("Model Used: \(result.escalatedToGPT5 ? "gpt-5" : "gpt-5-mini")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Logs
                    if !logs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📝 Process Log")
                                .font(.headline)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                                        Text("\(index + 1). \(log)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Clear button
                    Button("🗑️ Clear All") {
                        clearAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Pipeline Test")
            .onChange(of: selectedItems) { items in
                loadSelectedImages(items)
            }
        }
    }
    
    // MARK: - Test Functions
    
    private func testMarketData() {
        isAnalyzing = true
        logs.append("Testing market data for: \"\(testOCRText)\"")
        
        let query = buildMarketQuery(from: testOCRText)
        logs.append("Generated search query: \"\(query)\"")
        
        marketService.fetchSoldListings(query: query) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                if let result = result {
                    marketData = result
                    logs.append("✅ Market data retrieved: \(result.soldListings.count) listings")
                } else {
                    logs.append("❌ Market data failed")
                }
            }
        }
    }
    
    private func testFullAnalysis() {
        guard !selectedImages.isEmpty else { return }
        
        isAnalyzing = true
        logs.append("Starting full AI analysis with \(selectedImages.count) images")
        
        aiService.analyzeItemWithMarketIntelligence(images: selectedImages) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                if let result = result {
                    analysisResult = result
                    logs.append("✅ AI analysis complete: \(result.attributes.name)")
                    logs.append("Model used: \(result.escalatedToGPT5 ? "gpt-5" : "gpt-5-mini/nano")")
                } else {
                    logs.append("❌ AI analysis failed")
                }
            }
        }
    }
    
    private func testAllComponents() {
        logs.append("=== Testing All Components ===")
        
        // Test 1: OCR simulation
        logs.append("1. OCR Text: \"\(testOCRText)\"")
        
        // Test 2: Model selection
        let model = selectModel(for: testOCRText)
        logs.append("2. Selected model: \(model)")
        
        // Test 3: Market data
        testMarketData()
        
        // Test 4: Full analysis (if images available)
        if !selectedImages.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                testFullAnalysis()
            }
        }
    }
    
    private func buildMarketQuery(from text: String) -> String {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let relevantWords = words.filter { word in
            word.count >= 3 && !["the", "and", "size", "with"].contains(word)
        }
        return Array(relevantWords.prefix(3)).joined(separator: " ")
    }
    
    private func selectModel(for text: String) -> String {
        let lower = text.lowercased()
        
        if ["supreme", "rolex", "louis vuitton", "gucci"].contains(where: lower.contains) {
            return "gpt-5"
        } else if lower.contains("isbn") || lower.contains("upc") {
            return "gpt-5-nano"
        } else {
            return "gpt-5-mini"
        }
    }
    
    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                selectedImages = images
                if !images.isEmpty {
                    logs.append("📸 Loaded \(images.count) images")
                }
            }
        }
    }
    
    private func clearAll() {
        selectedItems = []
        selectedImages = []
        analysisResult = nil
        marketData = nil
        logs = []
        isAnalyzing = false
    }
}

#Preview {
    TestDemoView()
}