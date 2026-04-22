import SwiftUI

struct WizardStepBudget: View {
    @ObservedObject var viewModel: WizardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What's your budget?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.theme.primary)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From: \(Int(viewModel.budgetMin)) ₽")
                        .fontWeight(.medium)
                    Slider(value: $viewModel.budgetMin, in: 0...50000, step: 500)
                        .tint(Color.theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("To: \(Int(viewModel.budgetMax)) ₽")
                        .fontWeight(.medium)
                    Slider(value: $viewModel.budgetMax, in: 0...50000, step: 500)
                        .tint(Color.theme.primary)
                }
            }
            .cardStyle()
            
            // Quick presets
            HStack(spacing: 10) {
                ForEach([(500, 2000), (2000, 5000), (5000, 15000), (15000, 50000)], id: \.0) { preset in
                    Button {
                        viewModel.budgetMin = Double(preset.0)
                        viewModel.budgetMax = Double(preset.1)
                    } label: {
                        Text("\(preset.0/1000)-\(preset.1/1000)k")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.theme.tag)
                            .foregroundColor(Color.theme.primary)
                            .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}
