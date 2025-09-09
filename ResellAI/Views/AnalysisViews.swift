import SwiftUI
import PhotosUI

// MARK: - Main Analysis View
struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Photo Section
                        PhotoSelectionSection(
                            images: $viewModel.images,
                            selectedItems: $selectedItems,
                            showingImagePicker: $showingImagePicker,
                            showingCamera: $showingCamera
                        )
                        
                        // Analyze Button
                        if !viewModel.images.isEmpty && !viewModel.isAnalyzing {
                            Button(action: {
                                Task {
                                    await viewModel.analyzeProduct()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Analyze Item")
                                    
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Analysis Status
                        if viewModel.isAnalyzing {
                            AnalysisStatusView(status: "Analyzing your item...")
                                .padding(.horizontal)
                        }
                        
                        // Results
                        if let result = viewModel.result {
                            AnalysisResultView(result: result)
                                .padding(.horizontal)
                        }
                        
                        // Error Message
                        if let error = viewModel.error {
                            ErrorView(message: error)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Item Analysis")
            .navigationBarTitleDisplayMode(.large)
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedItems,
                maxSelectionCount: 8,
                matching: .images
            )
            .onChange(of: selectedItems) { _ in
                Task {
                    await loadImages()
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    viewModel.images.append(image)
                }
            }
        }
    }
    
    private func loadImages() async {
        viewModel.images = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                viewModel.images.append(uiImage)
            }
        }
    }
}

// MARK: - Photo Selection Section
struct PhotoSelectionSection: View {
    @Binding var images: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var showingImagePicker: Bool
    @Binding var showingCamera: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Item Photos")
                .font(.headline)
                .padding(.horizontal)
            
            if images.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "camera.on.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Add photos of your item")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Take clear photos from multiple angles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button(action: { showingCamera = true }) {
                            Label("Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            Label("Library", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                // Photo Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            PhotoThumbnail(
                                image: images[index],
                                onDelete: {
                                    images.remove(at: index)
                                }
                            )
                        }
                        
                        // Add More Button
                        if images.count < 8 {
                            Button(action: { showingImagePicker = true }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(12)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Analysis Status View
struct AnalysisStatusView: View {
    let status: String
    @State private var animationAmount = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated Progress
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(animationAmount * 360))
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animationAmount = 2
                }
            }
            
            Text(status)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Analysis Result View
struct AnalysisResultView: View {
    let result: AnalysisResult
    @State private var showingListingView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Analysis Complete")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Product Info
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Item", value: result.name)
                InfoRow(label: "Brand", value: result.brand)
                InfoRow(label: "Condition", value: result.condition)
                InfoRow(label: "Category", value: result.category)
            }
            .padding()
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Market Data (integrated into pricing now)
            // Market intelligence is now built into the AI analysis
            
            // Pricing
            PricingView(result: result)
            
            // List Item Button
            Button(action: { showingListingView = true }) {
                HStack {
                    Image(systemName: "tag.fill")
                    Text("Create Listing")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showingListingView) {
            CreateListingView(analysisResult: result)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Market Data View
struct MarketDataView: View {
    let marketData: MarketDataResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Analysis")
                .font(.headline)
            
            HStack(spacing: 20) {
                MarketStatView(
                    title: "Avg. Sold",
                    value: String(format: "$%.2f", marketData.averagePrice ?? 0),
                    icon: "dollarsign.circle"
                )
                
                MarketStatView(
                    title: "Listings",
                    value: "\(marketData.soldListings.count)",
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MarketStatView(
                    title: "Data Type",
                    value: marketData.isEstimate ? "Est." : "Real",
                    icon: "checkmark.circle"
                )
            }
            
            // Recent Comps
            if !marketData.soldListings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sales")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(marketData.soldListings.prefix(3).enumerated()), id: \.offset) { index, listing in
                        HStack {
                            Text(listing.title)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "$%.2f", listing.price))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Market Stat View
struct MarketStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pricing View
struct PricingView: View {
    let result: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing Strategy")
                .font(.headline)
            
            HStack(spacing: 16) {
                PriceOptionView(
                    title: "Quick Sale",
                    price: result.quickPrice,
                    description: "Sell in 1-3 days",
                    color: .orange
                )
                
                PriceOptionView(
                    title: "Optimal",
                    price: result.suggestedPrice,
                    description: "Best value",
                    color: .green,
                    isRecommended: true
                )
                
                PriceOptionView(
                    title: "Premium",
                    price: result.premiumPrice,
                    description: "Max profit",
                    color: .purple
                )
            }
            
            // Resale Potential Indicator
            if let potential = result.resalePotential {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text("Resale Potential: \(potential)/10")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Price Option View
struct PriceOptionView: View {
    let title: String
    let price: Double
    let description: String
    let color: Color
    var isRecommended: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(4)
            }
            
            Text(String(format: "$%.2f", price))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(description)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isRecommended ? color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Create Listing View
struct CreateListingView: View {
    let analysisResult: AnalysisResult
    @Environment(\.dismiss) private var dismiss
    @State private var isCreatingListing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Create eBay Listing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Product Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Product Summary")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Item", value: analysisResult.name)
                        InfoRow(label: "Brand", value: analysisResult.brand)
                        InfoRow(label: "Condition", value: analysisResult.condition)
                        InfoRow(label: "Suggested Price", value: String(format: "$%.2f", analysisResult.suggestedPrice))
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Listing Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Listing Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(analysisResult.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Description:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        Text(analysisResult.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                Spacer()
                
                // Create Listing Button
                Button(action: createListing) {
                    HStack {
                        if isCreatingListing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isCreatingListing ? "Creating Listing..." : "Create eBay Listing")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCreatingListing ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(isCreatingListing)
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private func createListing() {
        isCreatingListing = true
        
        // Simulate creating listing (replace with actual eBay listing creation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCreatingListing = false
            // TODO: Integrate with actual eBay listing service
            dismiss()
        }
    }
}

// MARK: - Preview
struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}
