import SwiftUI

struct ContentView: View {
    @ObservedObject var store: TodoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar
            titleBlock
            Rectangle()
                .fill(Theme.red)
                .frame(height: 2)
                .padding(.bottom, 14)

            if !store.items.isEmpty {
                gotItButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach($store.items) { $item in
                        ItemRow(item: $item, onDelete: { store.removeItem(item) })
                    }

                    if store.canAddItem {
                        addButton
                    }

                    if store.items.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            footer
        }
        .frame(width: 300, height: 520)
        .background(Theme.background)
        .foregroundColor(Theme.textPrimary)
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.red)
                .frame(width: 7, height: 7)
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.red)
            Spacer()
            Text("\(store.items.count)/\(TodoStore.maxItems)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var titleBlock: some View {
        Text("TWO DO")
            .font(.system(size: 26, weight: .heavy))
            .tracking(1)
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 10)
    }

    /// The only thing that closes the popover — deliberately, not by
    /// accident. See `TodoStore.onAcknowledge`.
    private var gotItButton: some View {
        Button(action: { store.onAcknowledge?() }) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                Text("GOT IT")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Theme.textPrimary)
            .foregroundColor(.black)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: { store.addItem() }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("ADD REMINDER")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Theme.red)
            .foregroundColor(.white)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("NOTHING SET")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.textSecondary)
            Text("Add up to \(TodoStore.maxItems) recurring reminders — chores,\nfollow-ups, whatever you keep forgetting.")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary.opacity(0.8))
        }
        .padding(.vertical, 12)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.border)
            HStack {
                Toggle(isOn: $store.launchAtLogin) {
                    Text("LAUNCH AT LOGIN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(Theme.textSecondary)
                }
                .toggleStyle(.switch)
                .tint(Theme.red)

                Spacer()

                Button(action: { NSApp.terminate(nil) }) {
                    Text("QUIT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

private struct ItemRow: View {
    @Binding var item: TodoItem
    var onDelete: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Theme.red)
                    .frame(width: 3, height: 20)
                    .cornerRadius(1)

                TextField("What do you keep forgetting?", text: $item.text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .focused($isFocused)
                    .onSubmit { isFocused = false }

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            scheduleControl
                .padding(.leading, 13) // align under the text, past the accent bar
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.border, lineWidth: 1)
        )
        .cornerRadius(4)
    }

    private var scheduleControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                scheduleToggle(label: "AT LOGIN", isSelected: item.schedule == .atLogin) {
                    item.schedule = .atLogin
                }

                scheduleToggle(label: "DAILY", isSelected: item.schedule.isDaily) {
                    if !item.schedule.isDaily {
                        item.schedule = .daily([TimeOfDay(hour: 9, minute: 0)])
                    }
                }

                Spacer(minLength: 0)
            }

            if item.schedule.isDaily {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 6, alignment: .leading)],
                    alignment: .leading,
                    spacing: 6
                ) {
                    ForEach(Array(item.schedule.times.enumerated()), id: \.offset) { index, _ in
                        timeSlot(at: index)
                    }

                    if item.schedule.times.count < ReminderSchedule.maxDailyTimes {
                        addTimeButton
                    }
                }
            }
        }
    }

    private func timeSlot(at index: Int) -> some View {
        HStack(spacing: 4) {
            DatePicker("", selection: timeBinding(at: index), displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)
                .labelsHidden()
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .fixedSize()

            // Removing the last slot would leave a "daily" reminder that
            // never fires — switch to AT LOGIN for that instead.
            if item.schedule.times.count > 1 {
                Button(action: { removeTime(at: index) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addTimeButton: some View {
        Button(action: addTime) {
            HStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                Text("TIME")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .foregroundColor(Theme.textSecondary)
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    private func addTime() {
        var times = item.schedule.times
        guard times.count < ReminderSchedule.maxDailyTimes else { return }
        times.append(times.last?.nextHour ?? TimeOfDay(hour: 9, minute: 0))
        item.schedule = .daily(times)
    }

    private func removeTime(at index: Int) {
        var times = item.schedule.times
        guard times.indices.contains(index), times.count > 1 else { return }
        times.remove(at: index)
        item.schedule = .daily(times)
    }

    private func scheduleToggle(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Theme.red : Color.white.opacity(0.06))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    private func timeBinding(at index: Int) -> Binding<Date> {
        Binding<Date>(
            get: {
                let times = item.schedule.times
                let time = times.indices.contains(index) ? times[index] : TimeOfDay(hour: 9, minute: 0)
                var comps = DateComponents()
                comps.hour = time.hour
                comps.minute = time.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                var times = item.schedule.times
                guard times.indices.contains(index) else { return }
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                times[index] = TimeOfDay(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
                item.schedule = .daily(times)
            }
        )
    }
}
