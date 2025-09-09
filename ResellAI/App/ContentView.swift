//
//  ContentView.swift
//  ResellAI
//
//  Premium Dark Theme Main App
//

import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - MAIN CONTENT VIEW
struct ContentView: View {
    @StateObject private var firebaseService = FirebaseService()
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var businessService = BusinessService()
    
    // Test mode toggle (enable with long press)
    @State private var showTestMode = false
    
    // Directly observe the authService to ensure proper state updates
    @ObservedObject private var authService: AuthService
    
    init() {
        let firebase = FirebaseService()
        self._firebaseService = StateObject(wrappedValue: firebase)
        self.authService = firebase.authService
        self._inventoryService = StateObject(wrappedValue: InventoryService())
        self._businessService = StateObject(wrappedValue: BusinessService())
    }
    
    var body: some View {
        Group {
            if showTestMode {
                // Test Demo Mode
                TestDemoView()
            } else if authService.isAuthenticated {
                if businessService.ebayService.isAuthenticated {
                    // Main Camera App with Premium Design
                    MainCameraView()
                        .environmentObject(authService)
                        .environmentObject(firebaseService)
                        .environmentObject(inventoryService)
                        .environmentObject(businessService)
                } else {
                    // eBay Connection Flow
                    EbayConnectView()
                        .environmentObject(authService)
                        .environmentObject(firebaseService)
                        .environmentObject(inventoryService)
                        .environmentObject(businessService)
                }
            } else {
                WelcomeFlow()
                    .environmentObject(authService)
            }
        }
        .preferredColorScheme(.dark) // Force dark theme
        .background(DesignSystem.background)
        .onAppear {
            initializeServices()
        }
        .onLongPressGesture(minimumDuration: 3.0) {
            // Triple tap to toggle test mode
            withAnimation {
                showTestMode.toggle()
            }
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            print("🔄 Auth state changed in ContentView: \(isAuthenticated)")
        }
        .onChange(of: businessService.ebayService.isAuthenticated) { isAuthenticated in
            print("🔄 eBay auth state changed in ContentView: \(isAuthenticated)")
            if isAuthenticated {
                print("✅ eBay connected - showing camera view")
                businessService.objectWillChange.send()
            }
        }
    }
    
    private func initializeServices() {
        print("🚀 Initializing ResellAI services...")
        Configuration.validateConfiguration()
        businessService.initialize(with: firebaseService)
        inventoryService.initialize(with: firebaseService)
        print("✅ Services initialized")
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 Incoming URL: \(url)")
        
        // Handle eBay OAuth callback
        if url.scheme == "resellai" && url.host == "auth" {
            if url.path.contains("ebay") || url.absoluteString.contains("ebay") {
                print("🔗 Handling eBay Auth callback")
                businessService.handleEbayAuthCallback(url: url)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔄 Forcing UI state refresh after eBay callback")
                    self.businessService.objectWillChange.send()
                }
            }
        }
    }
}

// MARK: - MAIN CAMERA VIEW WITH PREMIUM DESIGN
struct MainCameraView: View {
    @EnvironmentObject var businessService: BusinessService
    @EnvironmentObject var authService: AuthService
    
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            Text("🎉 ResellAI Pipeline Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Long press anywhere to enter test mode")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
            
            // Show our test interface directly for now
            TestDemoView()
        }
        .background(DesignSystem.background)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Premium Header
    private var premiumHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignSystem.spacing4) {
                // App Branding
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DesignSystem.spacing2) {
                        Text("ResellAI")
                            .font(DesignSystem.largeTitleFont)
                            .foregroundColor(DesignSystem.textPrimary)
                        
                        // AI Badge with subtle glow
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("AI")
                                .font(DesignSystem.aiCaptionFont)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(DesignSystem.aiPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.aiPrimary.opacity(0.15))
                        )
                        .premiumGlow(color: DesignSystem.aiPrimary, radius: 6, intensity: 0.3)
                    }
                    
                    Text("Photo to eBay listing in 30 seconds")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.textTertiary)
                }
                
                Spacer()
                
                // Status Indicators
                HStack(spacing: DesignSystem.spacing4) {
                    // eBay Status
                    Button(action: { }) {
                        HStack(spacing: 6) {
                            StatusIndicator(
                                isConnected: businessService.ebayService.isAuthenticated,
                                label: businessService.ebayService.isAuthenticated ? "eBay" : "eBay",
                                showPulse: businessService.ebayService.isAuthenticated
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(DesignSystem.surfaceSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            businessService.ebayService.isAuthenticated
                                            ? DesignSystem.success.opacity(0.3)
                                            : DesignSystem.error.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    
                    // Usage Meter
                    if let user = authService.currentUser {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(authService.monthlyAnalysisCount)/\(user.monthlyAnalysisLimit)")
                                .font(DesignSystem.aiCaptionFont)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.textSecondary)
                            
                            if !authService.canAnalyze {
                                Text("UPGRADE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(DesignSystem.error)
                            } else {
                                Text("analyses")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignSystem.textTertiary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignSystem.surfaceSecondary)
                        )
                    }
                    
                    // Settings Button
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(DesignSystem.surfaceSecondary)
                            )
                    }
                }
            }
            .padding(.horizontal, DesignSystem.spacing6)
            .padding(.vertical, DesignSystem.spacing4)
            
            // Subtle separator
            Rectangle()
                .fill(DesignSystem.surfaceTertiary)
                .frame(height: 1)
                .opacity(0.5)
        }
        .background(DesignSystem.surfaceSecondary)
    }
}

#Preview {
    ContentView()
}
