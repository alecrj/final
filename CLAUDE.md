# ResellAI - AI-Powered eBay Listing Automation

## What We're Building
An iOS app that transforms camera roll photos into professional eBay listings automatically. Users select photos, AI analyzes them overnight, users review/edit results, then post to eBay with one tap.

## The Core Workflow
```
1. User selects 20-50 photos from camera roll
2. Smart grouping: "These 3 photos = 1 Nike shoe"
3. Queue processes all items (GPT-5 analysis + eBay market data)
4. User reviews results with edit capabilities
5. Bulk post to eBay or individual item posting
```

## Post-Analysis User Experience
```
After AI completes analysis:
├── Quick Actions
│   ├── "Post All to eBay" (AI suggested prices)
│   ├── "Post All Quick Sale" (15% below market)
│   └── "Review Items" (manual editing)
├── Individual Item Controls
│   ├── Edit price (slider + text input)
│   ├── Edit title and description
│   ├── Select which photos to use
│   ├── Change category/condition
│   └── "Post This Item"
└── Bulk Management
    ├── Select multiple items for batch operations
    ├── Apply price adjustments to selections
    └── Schedule listings over multiple days
```

## Technical Architecture

### Current Foundation (70% Complete)
- SwiftUI iOS app with dark theme
- Firebase authentication and data storage
- eBay OAuth 2.0 production setup
- Queue system for batch processing
- Core data models and UI structure

### Critical Services Needing Completion

#### 1. AIAnalysisService (`Services/AnalysisService.swift`)
**Current State**: Partially implemented, GPT-5 integration broken
**Needs**: 
- Complete GPT-5 Responses API integration with proper JSON parsing
- Smart model selection: gpt-5-mini (default) → gpt-5 (luxury brands/unclear photos)
- OCR text extraction from photos using Vision framework
- Robust error handling with retry logic

#### 2. EbayMarketDataService (Needs Creation)
**Purpose**: Fetch real pricing data for intelligent suggestions
**Needs**:
- eBay Browse API integration for sold listings (last 30 days)
- Current active listings analysis for competition
- Price trend calculation and demand assessment
- Caching to avoid rate limits

#### 3. EbayListingService (`Services/EbayListingService.swift`)
**Current State**: Stub implementation
**Needs**:
- Complete listing creation with professional titles/descriptions
- Multi-image upload to eBay with optimization
- Auto-policy creation for shipping/returns if missing
- Individual and bulk posting capabilities

#### 4. PhotoProcessingService (Needs Creation)
**Purpose**: Smart photo grouping and enhancement
**Needs**:
- Algorithm to group related photos into single items
- Image enhancement and optimization for eBay
- Photo selection interface for each grouped item
- Duplicate detection and management

#### 5. BulkOperationsService (Needs Creation)  
**Purpose**: Mass listing and management operations
**Needs**:
- Bulk eBay posting with progress tracking
- Batch price adjustments and edits
- Scheduled listing capabilities
- Export functionality for power users

### Key UI Components to Build

#### PhotoImportView
- PhotosPicker integration for camera roll multi-select
- Visual grouping interface showing "Item 1: 3 photos"
- Drag-and-drop reordering and regrouping
- Batch confirmation before analysis

#### PostAnalysisReviewView
- Grid/list view of analyzed items with AI suggestions
- Inline editing: tap price to edit, tap title to modify
- Photo carousel for each item with selection controls
- Bulk action toolbar at bottom

#### BulkListingView
- Progress tracking for mass eBay posting
- Real-time status updates per item
- Error handling and retry options for failed posts
- Success summary with profit estimates

## Implementation Priority Order

### Phase 1: Core Pipeline
**Goal**: Single photo → eBay listing works end-to-end
1. Fix GPT-5 analysis service with proper API integration
2. Build eBay market data service for pricing
3. Complete eBay listing creation service
4. Test and debug the complete pipeline

### Phase 2: Bulk Photo Processing
**Goal**: Handle camera roll import and smart grouping  
1. Build photo import with multi-select from camera roll
2. Implement smart photo grouping algorithms
3. Create batch confirmation and queue management
4. Test with 20+ item batches

### Phase 3: Review and Edit Interface
**Goal**: Users can review, edit, and post results
1. Build post-analysis review interface
2. Implement inline editing for price, title, description
3. Add photo selection controls for each item
4. Create individual and bulk posting capabilities

### Phase 4: Advanced Features
**Goal**: Professional bulk operations
1. Advanced bulk editing and management
2. Scheduled posting over multiple days
3. Export and power user features
4. Performance optimization and polish

## File Structure
```
ResellAI/
├── App/
│   ├── ResellAIApp.swift
│   ├── ContentView.swift (main navigation)
│   └── Configuration.swift (API keys)
├── Features/
│   ├── PhotoImport/
│   │   ├── PhotoImportView.swift
│   │   ├── PhotoGroupingView.swift
│   │   └── PhotoProcessingService.swift
│   ├── Analysis/
│   │   ├── AIAnalysisService.swift
│   │   └── EbayMarketDataService.swift
│   ├── Review/
│   │   ├── PostAnalysisReviewView.swift
│   │   ├── ItemEditView.swift
│   │   └── ResultsDashboard.swift
│   ├── Listing/
│   │   ├── EbayListingService.swift
│   │   ├── BulkListingView.swift
│   │   └── BulkOperationsService.swift
│   └── Queue/
│       ├── QueueView.swift
│       └── QueueModels.swift
├── Services/
│   ├── BusinessService.swift (main orchestrator)
│   ├── EbayService.swift (OAuth)
│   ├── FirebaseService.swift
│   └── AuthService.swift
├── Core/
│   ├── Models.swift
│   ├── DesignSystem.swift
│   └── Extensions/
└── Views/
    └── [Existing UI components]
```

## Technical Requirements

### Swift/SwiftUI Standards
- Swift 6.0+ with strict concurrency
- SwiftUI for all new UI components
- Combine for reactive data flows
- MVVM architecture with ObservableObject
- Protocol-oriented design for services

### API Integration Standards
- URLSession with Combine for networking
- Codable for JSON parsing with custom handling
- Comprehensive error types and handling
- Rate limiting with exponential backoff
- Request/response logging for debugging

### AI Integration Specifics
- OpenAI GPT-5 Responses API (not Chat Completions)
- Smart model tiering based on item complexity
- OCR integration using Vision framework
- Confidence scoring and threshold management
- Cost optimization through intelligent model selection

### eBay Integration Requirements
- Production OAuth 2.0 with existing credentials
- Browse API for market data (sold/active listings)
- Sell API for listing creation and management
- Image upload with eBay specifications (1600px min)
- Policy auto-creation and management

## Business Logic Rules

### AI Processing
- Luxury brands (Supreme, Gucci, Rolex, etc.) → escalate to gpt-5
- Clear product photos with text → use gpt-5-mini
- Unclear/low quality photos → escalate to gpt-5
- Confidence >0.9 → auto-approve, 0.7-0.9 → review, <0.7 → flag
- Maximum 3 retry attempts with different models

### Pricing Strategy
- Market price: Average of recent sold listings
- Quick sale: 85% of market price
- Premium: 115% of market price
- Factor in condition assessment from AI
- Alert for items priced significantly above/below market

### Photo Management
- Group photos by visual similarity and OCR text
- Maximum 12 photos per eBay listing
- Auto-select best photos (clear, well-lit, different angles)
- Allow manual reordering and selection
- Optimize images for eBay requirements

### User Experience Principles
- Bulk operations feel instant with proper progress indication
- Never lose user data - persist everything locally
- Graceful error handling with actionable recovery options
- Manual override always available for AI suggestions
- Visual feedback for all async operations

## Development Notes

### Current API Configuration
- OpenAI API key configured for GPT-5 Responses API
- eBay Production Client ID: `AlecRodr-resell-PRD-d0bc91504-be3e553a`
- Firebase project configured and ready
- All environment variables properly set

### Known Issues to Fix
- GPT-5 response parsing in AIAnalysisService needs completion
- Queue processing sometimes stalls on errors
- eBay image upload not fully implemented
- Photo grouping logic doesn't exist yet

### Success Criteria
- User can select 30 photos and get 30 eBay listings with minimal manual input
- AI accuracy >90% for common items, >95% for luxury items
- Bulk posting completes without errors 95% of the time
- App feels professional and never crashes

## Build Commands
```bash
# Build and run
xcodebuild -project ResellAI.xcodeproj -scheme ResellAI -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild -project ResellAI.xcodeproj -scheme ResellAI -destination 'platform=iOS Simulator,name=iPhone 15' test

# Clean build
xcodebuild -project ResellAI.xcodeproj -scheme ResellAI clean
```

---

**This is the blueprint for building ResellAI exactly as envisioned. Focus on completing the core services first, then building the bulk processing capabilities, then polishing the user experience. Every feature should feel professional and reliable.**