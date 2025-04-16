import SwiftUI
import Charts

struct ReportView: View {
    @StateObject private var reportVM = ReportViewModel()
    @State private var selectedTimeframe: Timeframe = .month
    
    enum Timeframe: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Summary Cards
                    HStack {
                        SummaryCard(title: "Income",
                                  amount: reportVM.totalIncome,
                                  color: .green)
                        SummaryCard(title: "Expenses",
                                  amount: reportVM.totalExpenses,
                                  color: .red)
                    }
                    .padding(.horizontal)
                    
                    // Income vs Expenses Chart
                    VStack(alignment: .leading) {
                        Text("Income vs Expenses")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(reportVM.monthlyData.sorted(by: { $0.key < $1.key }), id: \.key) { month, data in
                                BarMark(
                                    x: .value("Month", month),
                                    y: .value("Income", data.income)
                                )
                                .foregroundStyle(.green)
                                
                                BarMark(
                                    x: .value("Month", month),
                                    y: .value("Expenses", data.expenses)
                                )
                                .foregroundStyle(.red)
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    
                    // Category Distribution
                    VStack(alignment: .leading) {
                        Text("Expense Categories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(reportVM.expensesByCategory.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                                SectorMark(
                                    angle: .value("Amount", amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1
                                )
                                .foregroundStyle(by: .value("Category", category))
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                }
            }
            .navigationTitle("Reports")
            .task {
                await reportVM.loadData()
            }
            .refreshable {
                await reportVM.loadData()
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f", amount))
                .font(.title2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView()
    }
} 