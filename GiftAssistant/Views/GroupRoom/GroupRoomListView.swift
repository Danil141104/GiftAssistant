import SwiftUI

struct GroupRoomListView: View {
    @StateObject private var viewModel = GroupRoomViewModel()
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var joinCode = ""
    @State private var joinResult: String?
    
    let userID: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Button { showCreate = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Создать").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                        }
                        
                        Button { showJoin = true } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Войти").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.theme.secondary).foregroundColor(.white).cornerRadius(12)
                        }
                    }
                    
                    if !viewModel.rooms.isEmpty {
                        HStack(spacing: 12) {
                            MiniStat(icon: "person.3.fill", value: "\(viewModel.rooms.count)", label: "Комнат")
                            MiniStat(icon: "checkmark.circle", value: "\(viewModel.rooms.filter { $0.status == "open" }.count)", label: "Активных")
                            MiniStat(icon: "rublesign.circle", value: "\(Int(viewModel.rooms.reduce(0) { $0 + $1.currentTotal }))", label: "Собрано ₽")
                        }
                    }
                    
                    if viewModel.rooms.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "person.3").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                            Text("Нет комнат").font(.title3).fontWeight(.semibold)
                            Text("Создайте комнату для\nсовместного сбора на подарок")
                                .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(viewModel.rooms) { room in
                            NavigationLink(destination: GroupRoomDetailView(roomID: room.id, userID: userID)) {
                                RoomCard(room: room)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal).padding(.top, 8)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Комнаты")
            .onAppear { viewModel.startListening(userID: userID) }
            .sheet(isPresented: $showCreate) {
                CreateRoomView(userID: userID, viewModel: viewModel)
            }
            .alert("Войти в комнату", isPresented: $showJoin) {
                TextField("Введите код приглашения", text: $joinCode)
                Button("Войти") {
                    Task {
                        let success = await viewModel.joinRoom(inviteCode: joinCode, userID: userID)
                        joinResult = success ? "Вы присоединились!" : "Комната не найдена"
                        joinCode = ""
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Введите 6-значный код от организатора")
            }
            .alert("Результат", isPresented: .init(get: { joinResult != nil }, set: { if !$0 { joinResult = nil } })) {
                Button("OK") { joinResult = nil }
            } message: {
                Text(joinResult ?? "")
            }
        }
    }
}

struct RoomCard: View {
    let room: GroupRoom
    
    var progress: Double {
        guard room.budgetGoal > 0 else { return 0 }
        return min(room.currentTotal / room.budgetGoal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.recipientName).font(.headline).foregroundColor(Color.theme.text)
                    Text(room.occasion).font(.caption).foregroundColor(Color.theme.textSecondary)
                }
                Spacer()
                StatusBadge(status: room.status)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.theme.tag).frame(height: 8)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progress >= 1.0 ? Color.theme.success : Color.theme.primary)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(room.currentTotal)) из \(Int(room.budgetGoal)) ₽")
                        .font(.caption).foregroundColor(Color.theme.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.caption).fontWeight(.semibold)
                        .foregroundColor(progress >= 1.0 ? Color.theme.success : Color.theme.primary)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill").font(.caption2)
                    Text("\(room.memberIDs.count) участников").font(.caption)
                }
                .foregroundColor(Color.theme.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "key.fill").font(.caption2)
                    Text(room.inviteCode).font(.caption).fontWeight(.medium)
                }
                .foregroundColor(Color.theme.secondary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.theme.textSecondary)
            }
        }
        .padding(16).background(Color.theme.card).cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status == "open" ? Color.green : Color.gray).frame(width: 6, height: 6)
            Text(status == "open" ? "Активна" : "Закрыта").font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(status == "open" ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MiniStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(Color.theme.primary)
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(10).background(Color.theme.card).cornerRadius(10)
    }
}
