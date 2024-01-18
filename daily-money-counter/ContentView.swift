import SwiftUI
import Combine

struct ContentView: View {
    @State private var monthlySalary: String = ""
    @State private var additionalHolidaysCount: String = ""
    @State private var currentEarnings: Double = 0.0
    @State private var earningsPerMinute: Double = 0.0
    @State private var earningsPerHour: Double = 0.0
    @State private var dailyEarnings: Double = 0.0
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack {
            TextField("Введите месячный оклад", text: $monthlySalary)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Введите количество доп. выходных", text: $additionalHolidaysCount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Рассчитать") {
                calculateEarnings()
                startTimer()
            }

            Text("₽\(currentEarnings, specifier: "%.2f")")
                .font(.system(size: 50))
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text("₽\(earningsPerMinute, specifier: "%.2f")/мин • ₽\(earningsPerHour, specifier: "%.2f")/час • ₽\(dailyEarnings, specifier: "%.2f")/день")
                .font(.system(size: 20))
        }
        .padding()
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentEarnings += earningsPerMinute
        }
    }

    func startTimer() {
        timerCancellable?.cancel() // Отменяем предыдущий таймер, если он существует
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
                            .autoconnect()
                            .sink(receiveValue: { _ in
                                self.currentEarnings += self.earningsPerMinute
                            })
    }

    func calculateEarnings() {
        let workdays = countWorkdaysInMonth()
        guard let salary = Double(monthlySalary), workdays > 0 else { return }

        let dailyEarnings = salary / Double(workdays)
        let hourlyEarnings = dailyEarnings / 8 // Предполагаем 8 рабочих часов в день
        let minuteEarnings = hourlyEarnings / 60

        self.dailyEarnings = dailyEarnings
        self.earningsPerHour = hourlyEarnings
        self.earningsPerMinute = minuteEarnings
        self.currentEarnings = 0.0 // Обнуляем текущий заработок при новом расчете
    }

    func countWorkdaysInMonth() -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: Date()) else { return 0 }

        let additionalHolidays = Int(additionalHolidaysCount) ?? 0

        var workdays = 0
        calendar.enumerateDates(startingAfter: interval.start, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) { date, _, stop in
            if let date = date, date <= interval.end {
                if !calendar.isDateInWeekend(date) {
                    workdays += 1
                }
            } else {
                stop = true
            }
        }
        return workdays - additionalHolidays
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
