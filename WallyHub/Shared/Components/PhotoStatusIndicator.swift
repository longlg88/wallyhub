import SwiftUI

// MARK: - Photo Status Indicator Components

/// 사진 상태를 시각적으로 표시하는 인디케이터
public struct PhotoStatusIndicator: View {
    let status: PhotoDisplayStatus
    let size: CGFloat
    let showLabel: Bool
    
    public init(
        status: PhotoDisplayStatus,
        size: CGFloat = 16,
        showLabel: Bool = false
    ) {
        self.status = status
        self.size = size
        self.showLabel = showLabel
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // 상태 아이콘
            Image(systemName: status.iconName)
                .font(.system(size: size))
                .foregroundColor(statusColor)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: size + 4, height: size + 4)
                        .shadow(radius: 1)
                )
            
            // 라벨 (옵션)
            if showLabel {
                Text(status.description)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .unviewed: return .blue
        case .viewed: return .gray
        }
    }
}

/// 사진 썸네일에 오버레이되는 상태 표시
public struct PhotoThumbnailOverlay: View {
    let photo: Photo
    let viewStatus: PhotoViewStatus?
    let onTap: (() -> Void)?
    
    public init(
        photo: Photo,
        viewStatus: PhotoViewStatus?,
        onTap: (() -> Void)? = nil
    ) {
        self.photo = photo
        self.viewStatus = viewStatus
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // 상태 인디케이터
                PhotoStatusIndicator(
                    status: photo.displayStatus(with: viewStatus),
                    size: 14
                )
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            
            Spacer()
            
            // 하단 정보 (조회 상태에 따라)
            if let viewStatus = viewStatus, viewStatus.isViewed {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if let lastViewed = viewStatus.lastViewedAt {
                            Text(relativeTimeString(from: lastViewed))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 8)
                    .padding(.trailing, 8)
                }
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// 사진 목록 상단의 상태 필터 컨트롤
public struct PhotoStatusFilter: View {
    @Binding var selectedFilter: PhotoFilterType
    let unviewedCount: Int
    let totalCount: Int
    
    public init(
        selectedFilter: Binding<PhotoFilterType>,
        unviewedCount: Int,
        totalCount: Int
    ) {
        self._selectedFilter = selectedFilter
        self.unviewedCount = unviewedCount
        self.totalCount = totalCount
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // 상태 요약
            HStack {
                Text("전체 \(totalCount)개")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if unviewedCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text("미확인 \(unviewedCount)개")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // 필터 버튼들
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PhotoFilterType.allCases, id: \.self) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: count(for: filter)
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func count(for filter: PhotoFilterType) -> Int {
        switch filter {
        case .all: return totalCount
        case .unviewed: return unviewedCount
        case .viewed: return totalCount - unviewedCount
        }
    }
}

/// 필터 타입 정의
public enum PhotoFilterType: String, CaseIterable {
    case all = "전체"
    case unviewed = "미확인"
    case viewed = "확인됨"
    
    public var icon: String {
        switch self {
        case .all: return "photo.stack"
        case .unviewed: return "circle.fill"
        case .viewed: return "checkmark.circle.fill"
        }
    }
}

/// 개별 필터 버튼
private struct FilterButton: View {
    let filter: PhotoFilterType
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? 
                Color.accentColor : 
                Color.gray.opacity(0.1)
            )
            .foregroundColor(
                isSelected ? 
                .white : 
                .primary
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 사진 상세 정보 카드
public struct PhotoViewDetailsCard: View {
    let photo: Photo
    let viewStatus: PhotoViewStatus?
    
    public init(photo: Photo, viewStatus: PhotoViewStatus?) {
        self.photo = photo
        self.viewStatus = viewStatus
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("조회 정보")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let viewStatus = viewStatus, viewStatus.isViewed {
                VStack(alignment: .leading, spacing: 8) {
                    if let lastViewed = viewStatus.lastViewedAt {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.green)
                            Text("\(formatDate(lastViewed))에 확인")
                            Spacer()
                        }
                    }
                    
                    // 확인 기록 (날짜시간만)
                    if !viewStatus.viewRecords.isEmpty {
                        Divider()
                        
                        Text("확인 기록")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(viewStatus.viewRecords.prefix(3)) { record in
                            HStack {
                                Text(formatDate(record.viewedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        
                        if viewStatus.viewRecords.count > 3 {
                            Text("외 \(viewStatus.viewRecords.count - 3)건 더")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("아직 확인되지 않은 사진입니다")
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview Support

#if DEBUG
struct PhotoStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PhotoStatusIndicator(status: .unviewed, showLabel: true)
            PhotoStatusIndicator(status: .viewed, showLabel: true)
        }
        .padding()
    }
}
#endif