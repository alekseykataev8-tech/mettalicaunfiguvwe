import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("dailyReadingReminder") private var dailyReadingReminder = false
    @AppStorage("defaultSessionDuration") private var defaultSessionDuration = 30

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                    .tint(.purple)
                }

                Section("Reading") {
                    Toggle(isOn: $dailyReadingReminder) {
                        Label("Daily Reading Reminder", systemImage: "bell.fill")
                    }
                    .tint(.purple)

                    if dailyReadingReminder {
                        Stepper(value: $defaultSessionDuration, in: 10...120, step: 10) {
                            Label("Default session: \(defaultSessionDuration) min", systemImage: "clock.fill")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Developer", systemImage: "person.fill")
                        Spacer()
                        Text("PageQuest Team")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Built with", systemImage: "swift")
                        Spacer()
                        Text("SwiftUI + SwiftData")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
