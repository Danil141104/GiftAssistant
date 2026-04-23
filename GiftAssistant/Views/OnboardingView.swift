import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    let userID: String
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showProfileSetup = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "wand.and.stars",
            title: "Умный подбор подарков",
            description: "Ответьте на несколько вопросов и получите персонализированные рекомендации из каталога 13 000+ товаров.",
            color: Color(hex: "#4F6AF5")
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Друзья и группы",
            description: "Добавляйте друзей, смотрите их интересы и вишлисты. Создавайте групповые комнаты для совместного сбора на подарок.",
            color: Color(hex: "#34C759")
        ),
        OnboardingPage(
            icon: "star.fill",
            title: "Ваши интересы",
            description: "Заполните профиль, чтобы друзья могли подобрать идеальный подарок. Импортируйте интересы из VK в один клик.",
            color: Color(hex: "#FF9500")
        ),
    ]

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // Skip button
                HStack {
                    Spacer()
                    Button("Пропустить") {
                        showProfileSetup = true
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.theme.primary : Color.theme.tag)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        showProfileSetup = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showProfileSetup) {
            UserProfileSetupView(userID: userID, isOnboarding: true) {
                onComplete()
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(page.color)
            }

            // Text
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title).fontWeight(.bold)
                    .foregroundColor(Color.theme.text)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
