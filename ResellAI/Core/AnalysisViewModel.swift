//
//  AnalysisViewModel.swift  
//  ResellAI
//
//  ViewModel for Analysis Views - Bridges to Services
//

import SwiftUI
import Foundation

// MARK: - Analysis View Model
@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var isAnalyzing = false
    @Published var result: AnalysisResult?
    @Published var error: String?
    
    private let aiService = AIAnalysisService()
    
    func analyzeProduct() async {
        guard !images.isEmpty else {
            error = "No images selected"
            return
        }
        
        isAnalyzing = true
        error = nil
        
        aiService.analyzeItemWithMarketIntelligence(images: images) { [weak self] expertResult in
            Task { @MainActor in
                self?.isAnalyzing = false
                
                if let expertResult = expertResult {
                    self?.result = expertResult.toAnalysisResult()
                } else {
                    self?.error = "Analysis failed. Please try again."
                }
            }
        }
    }
    
    func clearResults() {
        result = nil
        error = nil
        images = []
    }
}