import SwiftUI

struct ProgressBarView: View {
    let current: Double
    let goal: Double
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(Int(current)) ₽").fontWeight(.bold)
                Spacer()
                Text("из \(Int(goal)) ₽").foregroundColor(Color.theme.textSecondary)
            }
            .font(.subheadline)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.theme.tag).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.theme.success)
                        .frame(width: geo.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)
            
            Text("\(Int(progress * 100))% собрано")
                .font(.caption).foregroundColor(Color.theme.textSecondary)
        }
    }
}
