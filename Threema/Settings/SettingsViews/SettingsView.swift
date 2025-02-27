//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2023-2024 Threema GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License, version 3,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import SwiftUI
import ThreemaFramework

struct SettingsView: View {
    @StateObject var settingsStore = BusinessInjector().settingsStore as! SettingsStore
    @ObservedObject var settingsViewModel = SettingsViewModel()

    // MARK: - Body
    
    var body: some View {
        ThreemaNavigationView {
            ThreemaTableView {
                FeedbackDevSection()
                GeneralSection()
                CallWebSection()
                ConnectionSection()
                #if !THREEMA_WORK && !THREEMA_ONPREM
                    if !LicenseStore.requiresLicenseKey() {
                        ThreemaWorkSection()
                        InviteSection()
                    }
                #endif
                
                #if THREEMA_WORK
                    RateSection()
                #endif
                
                AboutSection()
            }
            .navigationDestination(for: AnyViewDestination.self)
            .navigationTitle(title)
        }
        .environmentObject(settingsViewModel)
        .environmentObject(settingsViewModel.navigator)
        .environmentObject(settingsStore)
        .onReceive(\.showNotificationSettings) { _ in
            settingsViewModel.navigator.navigate(NotificationSettingsView())
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .listStyle(.insetGrouped)
        }
    }
}
