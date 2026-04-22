import SwiftUI

struct TagChipView: View {
    let label: String
    let isSelected: Bool
    var onTap: () -> Void = {}
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.theme.secondary : Color.theme.tag)
            .foregroundColor(isSelected ? .white : Color.theme.primary)
            .cornerRadius(20)
            .onTapGesture { onTap() }
    }
}
