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

            Spacer(minLength: 0)

            footer
        }
        .frame(width: 300, height: 380)
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

    private var addButton: some View {
        Button(action: { store.addItem() }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("ADD FOCUS ITEM")
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
            Text("NOTHING ON THE CARD")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.textSecondary)
            Text("Add up to two things worth doing today.")
                .font(.system(size: 11))
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
        HStack(spacing: 10) {
            Rectangle()
                .fill(Theme.red)
                .frame(width: 3, height: 20)
                .cornerRadius(1)

            Button(action: { item.isDone.toggle() }) {
                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isDone ? Theme.red : Theme.textSecondary)
            }
            .buttonStyle(.plain)

            TextField("Focus item…", text: $item.text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .strikethrough(item.isDone, color: Theme.textSecondary)
                .foregroundColor(item.isDone ? Theme.textSecondary : Theme.textPrimary)
                .focused($isFocused)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.border, lineWidth: 1)
        )
        .cornerRadius(4)
    }
}
