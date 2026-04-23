import SwiftUI

struct CatalogListView: View {
    @StateObject private var viewModel = CatalogViewModel()
    @EnvironmentObject var favoritesService: FavoritesService
    @EnvironmentObject var blacklistService: BlacklistService
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var displayedGifts: [GiftItem] {
        viewModel.filteredGifts.filter { gift in
            !blacklistService.isBlacklisted(gift.name)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.theme.textSecondary)
                            TextField("Поиск подарков...", text: $viewModel.searchText)
                                .onChange(of: viewModel.searchText) { _ in
                                    viewModel.applyFilters()
                                }
                        }
                        .padding(12)
                        .background(Color.theme.card)
                        .cornerRadius(12)
                        
                        Button {
                            withAnimation { viewModel.showPriceFilter.toggle() }
                        } label: {
                            Image(systemName: viewModel.showPriceFilter ? "slider.horizontal.below.rectangle" : "slider.horizontal.3")
                                .font(.title3)
                                .padding(12)
                                .background(Color.theme.card)
                                .cornerRadius(12)
                                .foregroundColor(Color.theme.primary)
                        }
                    }
                    
                    if viewModel.showPriceFilter {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Цена")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(Int(viewModel.priceMin)) – \(Int(viewModel.priceMax)) ₽")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text("От").font(.caption).foregroundColor(Color.theme.textSecondary)
                                    Slider(value: $viewModel.priceMin, in: 0...30000, step: 500)
                                        .tint(Color.theme.primary)
                                        .onChange(of: viewModel.priceMin) { _ in viewModel.applyFilters() }
                                }
                                VStack(alignment: .leading) {
                                    Text("До").font(.caption).foregroundColor(Color.theme.textSecondary)
                                    Slider(value: $viewModel.priceMax, in: 0...30000, step: 500)
                                        .tint(Color.theme.primary)
                                        .onChange(of: viewModel.priceMax) { _ in viewModel.applyFilters() }
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.theme.card)
                        .cornerRadius(12)
                    }
                    
                    if !viewModel.allCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Button {
                                    viewModel.selectCategory(nil)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.grid.2x2").font(.caption)
                                        Text("Все").font(.subheadline).fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(viewModel.selectedCategory == nil ? Color.theme.primary : Color.theme.card)
                                    .foregroundColor(viewModel.selectedCategory == nil ? .white : Color.theme.text)
                                    .cornerRadius(20)
                                }
                                ForEach(viewModel.allCategories, id: \.name) { cat in
                                    Button {
                                        viewModel.selectCategory(cat.name)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.icon).font(.caption)
                                            Text(cat.name).font(.subheadline).fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(viewModel.selectedCategory == cat.name ? Color.theme.primary : Color.theme.card)
                                        .foregroundColor(viewModel.selectedCategory == cat.name ? .white : Color.theme.text)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Text("\(displayedGifts.count) подарков")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                        
                        if !blacklistService.blacklist.isEmpty {
                            Text("(\(viewModel.filteredGifts.count - displayedGifts.count) скрыто)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        if viewModel.selectedCategory != nil || !viewModel.selectedTags.isEmpty || viewModel.priceMin > 0 || viewModel.priceMax < 30000 {
                            Button("Сбросить") { viewModel.resetFilters() }
                                .font(.subheadline)
                                .foregroundColor(Color.theme.secondary)
                        }
                    }
                    
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView().scaleEffect(1.5)
                            Text("Загружаем подарки...")
                                .foregroundColor(Color.theme.textSecondary)
                        }
                        .padding(.top, 60)
                    } else if displayedGifts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "gift").font(.system(size: 40)).foregroundColor(Color.theme.textSecondary)
                            Text("Подарки не найдены").foregroundColor(Color.theme.textSecondary)
                            Button("Сбросить фильтры") { viewModel.resetFilters() }
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Color.theme.primary).foregroundColor(.white).cornerRadius(10)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayedGifts) { gift in
                                GiftCardView(gift: gift)
                                    .environmentObject(favoritesService)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Каталог")
            .onAppear {
                if viewModel.gifts.isEmpty { viewModel.loadGifts() }
            }
            .refreshable { viewModel.loadGifts() }
        }
    }
}
