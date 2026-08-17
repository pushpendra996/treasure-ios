import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @State private var showingCurrency = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.personName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let phoneNumber = viewModel.personMobileNo {
                            Text(phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        viewModel.onTapProfile()
                    }
                }
                
                Section {
                    NavigationLink(destination: ReportView()) {
                        Label("Reports", systemImage: "chart.pie")
                    }
                    NavigationLink(destination: AllTransactionsView()) {
                        Label("Transactions", systemImage: "list.bullet")
                    }
                    Button {
                        showingCurrency = true
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle")
                            Spacer()
                            Text(currencyStore.label)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    Button(role: .destructive) {
                        viewModel.signOut()
                    } label: {
                        Text("Sign Out")
                    }
                }
                
                if let appInfo = viewModel.appInfo {
                    Section {
                        Text(appInfo)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.onAppear()
            }
            .sheet(isPresented: $showingCurrency) {
                NavigationView {
                    CurrencyPickerView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct CurrencyPickerView: View {
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(CurrencyStore.options) { option in
            Button {
                currencyStore.save(option.code)
                dismiss()
            } label: {
                HStack {
                    Text(option.symbol)
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.code)
                            .foregroundColor(.primary)
                        Text(option.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if currencyStore.code == option.code {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
            )
        }
        .listStyle(.plain)
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}
