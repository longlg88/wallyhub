import SwiftUI

struct RoleCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
    let features: [String]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                cardHeader
                
                if !features.isEmpty {
                    divider
                    featuresSection
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
            .overlay(borderOverlay)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Components
    private var cardHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                roleIcon
                roleInfo
                Spacer()
                chevronIcon
            }
            
            descriptionText
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }
    
    private var roleIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
            
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var roleInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
    
    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.gray.opacity(0.6))
    }
    
    private var descriptionText: some View {
        HStack {
            Text(description)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.08))
            .frame(height: 1)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("주요 기능")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    FeatureRow(feature: feature, gradient: gradient)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.2) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let feature: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(gradient.first ?? .blue)
            }
            
            Text(feature)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}