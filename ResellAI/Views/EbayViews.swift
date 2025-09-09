//
//  EbayViews.swift
//  ResellAI
//
//  Premium Dark Theme eBay Integration Views
//

import SwiftUI

// MARK: - EBAY CONNECT VIEW
struct EbayConnectView: View {
    @EnvironmentObject var businessService: BusinessService
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingInstructions = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // eBay Integration Header
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.surfaceGradient)
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(connectionStatusColor.opacity(0.3), lineWidth: 3)
                            )
                        
                        VStack(spacing: 12) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(DesignSystem.aiPrimary)
                            
                            Text("eBay")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                    }
                    .premiumGlow(color: DesignSystem.aiPrimary, radius: 25, intensity: 0.4)
                    
                    VStack(spacing: 12) {
                        Text("Connect Your eBay Store")
                            .font(DesignSystem.largeTitleFont)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Connect your eBay account to automatically list items and manage your inventory with AI-powered listings.")
                            .font(DesignSystem.bodyFont)
                            .foregroundColor(DesignSystem.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                }
                
                // Benefits Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What You Get:")
                        .font(DesignSystem.headlineFont)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    VStack(spacing: 12) {
                        BenefitRow(
                            icon: "wand.and.stars.inverse",
                            title: "AI-Powered Listings",
                            description: "Automated titles, descriptions, and pricing"
                        )
                        
                        BenefitRow(
                            icon: "photo.on.rectangle.angled",
                            title: "Photo-to-Listing",
                            description: "Take a photo, get a complete eBay listing"
                        )
                        
                        BenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Smart Pricing",
                            description: "Market data-driven price suggestions"
                        )
                        
                        BenefitRow(
                            icon: "clock.fill",
                            title: "Save Hours",
                            description: "30 seconds vs 30 minutes per listing"
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(DesignSystem.surfaceSecondary)
                .cornerRadius(DesignSystem.radiusLarge)
                .padding(.horizontal, 32)
                
                // Instructions Button
                Button(action: { showingInstructions = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                        Text("How does eBay connection work?")
                    }
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.aiPrimary)
                }
                .padding(.horizontal, 32)
                
                Spacer(minLength: 20)
                
                // Connect Button
                VStack(spacing: 16) {
                    Button(action: connectToEbay) {
                        HStack(spacing: 12) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            
                            Text(isConnecting ? "Connecting..." : "Connect to eBay")
                                .font(DesignSystem.headlineFont)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isConnecting ? Color.gray : DesignSystem.aiPrimary)
                        )
                        .premiumGlow(color: isConnecting ? .gray : DesignSystem.aiPrimary, radius: 6, intensity: 0.4)
                    }
                    .disabled(isConnecting)
                    
                    Text("Secure OAuth 2.0 • Your login stays with eBay")
                        .font(DesignSystem.footnoteFont)
                        .foregroundColor(DesignSystem.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(DesignSystem.background)
        .sheet(isPresented: $showingInstructions) {
            EbayInstructionsSheet()
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("Try Again", action: connectToEbay)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            print("🔍 EbayConnectView appeared - isAuthenticated: \(businessService.ebayService.isAuthenticated)")
        }
    }
    
    private var connectionStatusColor: Color {
        businessService.ebayService.isAuthenticated ? DesignSystem.success : DesignSystem.aiPrimary
    }
    
    private func connectToEbay() {
        isConnecting = true
        errorMessage = ""
        
        businessService.connectToEbay { success, error in
            DispatchQueue.main.async {
                isConnecting = false
                
                if !success, let error = error {
                    errorMessage = error
                    showingError = true
                }
            }
        }
    }
}

// MARK: - EBAY INSTRUCTIONS SHEET
struct EbayInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How eBay Connection Works")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.textPrimary)
                        
                        Text("ResellAI uses secure OAuth 2.0 to connect with your eBay account. Here's what happens:")
                            .font(.body)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 20) {
                        InstructionStep(
                            number: 1,
                            title: "Secure Redirect",
                            description: "You'll be redirected to eBay's official login page in Safari"
                        )
                        
                        InstructionStep(
                            number: 2,
                            title: "Sign In Safely",
                            description: "Enter your eBay credentials directly on eBay's secure website"
                        )
                        
                        InstructionStep(
                            number: 3,
                            title: "Grant Permissions",
                            description: "Allow ResellAI to manage your listings and inventory"
                        )
                        
                        InstructionStep(
                            number: 4,
                            title: "Return to App",
                            description: "You'll be automatically redirected back to ResellAI"
                        )
                    }
                    
                    // Security Note
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            Text("Security & Privacy")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Your eBay password never passes through our app")
                            Text("• We only receive secure access tokens")
                            Text("• You can revoke access anytime in eBay settings")
                            Text("• All connections use encrypted HTTPS")
                        }
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.textSecondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("eBay Connection")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

// MARK: - INSTRUCTION STEP
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number
            ZStack {
                Circle()
                    .fill(DesignSystem.aiPrimary)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(DesignSystem.textSecondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - CONNECTION STATUS CARD
struct ConnectionStatusCard: View {
    let isConnected: Bool
    let status: String
    let connectedUser: String
    
    var body: some View {
        VStack(spacing: DesignSystem.spacing4) {
            HStack(spacing: DesignSystem.spacing3) {
                StatusIndicator(
                    isConnected: isConnected,
                    label: isConnected ? "Connected" : "Not Connected",
                    showPulse: isConnected
                )
                
                Spacer()
                
                if isConnected {
                    Text("ACTIVE")
                        .font(DesignSystem.aiCaptionFont)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignSystem.success.opacity(0.2))
                        )
                }
            }
            
            if isConnected && !connectedUser.isEmpty {
                VStack(spacing: DesignSystem.spacing2) {
                    Text("eBay Account")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.textTertiary)
                    
                    Text(connectedUser)
                        .font(DesignSystem.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.textPrimary)
                }
            } else if !isConnected {
                Text("Connect your account to start creating automatic listings")
                    .font(DesignSystem.bodyFont)
                    .foregroundColor(DesignSystem.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Additional status info
            if !status.isEmpty && status != "Connected" && status != "Not Connected" {
                Text(status)
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.spacing5)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.radiusLarge)
                .fill(statusBackgroundColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.radiusLarge)
                        .stroke(statusBackgroundColor.opacity(0.3), lineWidth: 1)
                )
        )
        .premiumGlow(color: statusBackgroundColor, radius: 12, intensity: 0.3)
    }
    
    private var statusBackgroundColor: Color {
        isConnected ? DesignSystem.success : DesignSystem.warning
    }
}

// MARK: - EBAY CONNECT SHEET
struct EbayConnectSheet: View {
    @EnvironmentObject var businessService: BusinessService
    @Environment(\.dismiss) private var dismiss
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.spacing6) {
                    // Header
                    VStack(spacing: DesignSystem.spacing4) {
                        ZStack {
                            Circle()
                                .fill(DesignSystem.info.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "network")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(DesignSystem.info)
                        }
                        .premiumGlow(color: DesignSystem.info, radius: 20, intensity: 0.5)
                        
                        VStack(spacing: DesignSystem.spacing2) {
                            Text("Connect eBay")
                                .font(DesignSystem.titleFont)
                                .foregroundColor(DesignSystem.textPrimary)
                            
                            Text("Link your eBay account to automatically create optimized listings from AI analysis")
                                .font(DesignSystem.bodyFont)
                                .foregroundColor(DesignSystem.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.top, DesignSystem.spacing6)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: DesignSystem.spacing4) {
                        Text("What you get:")
                            .font(DesignSystem.headlineFont)
                            .foregroundColor(DesignSystem.textPrimary)
                        
                        VStack(spacing: DesignSystem.spacing3) {
                            BenefitRow(
                                icon: "wand.and.stars",
                                title: "Auto-listing creation",
                                description: "AI generates optimized titles and descriptions",
                                color: DesignSystem.aiPrimary
                            )
                            
                            BenefitRow(
                                icon: "photo.on.rectangle",
                                title: "Image upload",
                                description: "Photos are automatically uploaded to eBay",
                                color: DesignSystem.aiSecondary
                            )
                            
                            BenefitRow(
                                icon: "dollarsign.circle",
                                title: "Smart pricing",
                                description: "Based on real market data and sold comps",
                                color: DesignSystem.success
                            )
                            
                            BenefitRow(
                                icon: "shield.checkered",
                                title: "Secure connection",
                                description: "OAuth 2.0 authentication with eBay",
                                color: DesignSystem.info
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.spacing6)
                    
                    // Current Status
                    ConnectionStatusCard(
                        isConnected: businessService.ebayService.isAuthenticated,
                        status: businessService.ebayService.authStatus,
                        connectedUser: businessService.ebayService.connectedUserName
                    )
                    .padding(.horizontal, DesignSystem.spacing6)
                    
                    // Actions
                    VStack(spacing: DesignSystem.spacing4) {
                        if businessService.ebayService.isAuthenticated {
                            PrimaryButton(
                                title: "Done",
                                action: { dismiss() },
                                icon: "checkmark"
                            )
                            
                            SecondaryButton(
                                title: "Disconnect Account",
                                action: { businessService.ebayService.signOut() },
                                icon: "link.badge.minus"
                            )
                        } else {
                            PrimaryButton(
                                title: isConnecting ? "Connecting..." : "Connect to eBay",
                                action: { connectToEbay() },
                                isEnabled: !isConnecting,
                                isLoading: isConnecting,
                                icon: isConnecting ? nil : "link"
                            )
                            
                            if isConnecting {
                                HStack(spacing: DesignSystem.spacing2) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.aiPrimary))
                                        .scaleEffect(0.8)
                                    
                                    Text("Opening eBay authentication...")
                                        .font(DesignSystem.captionFont)
                                        .foregroundColor(DesignSystem.textSecondary)
                                }
                                .padding(.top, DesignSystem.spacing2)
                            } else {
                                Text("You'll be redirected to eBay to sign in securely with OAuth 2.0")
                                    .font(DesignSystem.captionFont)
                                    .foregroundColor(DesignSystem.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.spacing6)
                    .padding(.bottom, DesignSystem.spacing6)
                }
            }
            .background(DesignSystem.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.textSecondary)
                }
            }
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK") { }
            Button("Try Again") {
                connectToEbay()
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: businessService.ebayService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                print("✅ eBay connected in sheet - auto-dismissing after delay")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func connectToEbay() {
        isConnecting = true
        businessService.authenticateEbay { success in
            DispatchQueue.main.async {
                isConnecting = false
                if success {
                    print("✅ eBay connection successful")
                } else {
                    errorMessage = "Failed to connect to eBay. Please check your internet connection and try again."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - BENEFIT ROW
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.spacing4) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.radiusMedium)
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            .premiumGlow(color: color, radius: 8, intensity: 0.3)
            
            VStack(alignment: .leading, spacing: DesignSystem.spacing1) {
                Text(title)
                    .font(DesignSystem.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text(description)
                    .font(DesignSystem.captionFont)
                    .foregroundColor(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(DesignSystem.spacing4)
        .premiumCard()
    }
}

// MARK: - EBAY ACCOUNT STATUS VIEW
struct EbayAccountStatus: View {
    @EnvironmentObject var businessService: BusinessService
    
    var body: some View {
        HStack(spacing: DesignSystem.spacing2) {
            StatusIndicator(
                isConnected: businessService.ebayService.isAuthenticated,
                label: businessService.ebayService.isAuthenticated
                    ? "eBay: \(businessService.ebayService.connectedUserName)"
                    : "eBay: Not connected",
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
                            : DesignSystem.warning.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}
