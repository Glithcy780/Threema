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

import Foundation
import MBProgressHUD
import SwiftUI
import ThreemaFramework

struct ProfileView: View {
    @ObservedObject var model = ProfileViewModel()
    
    var body: some View {
        ThreemaNavigationView(.manual) {
            DynamicHeader {
                QuickActionsViewSection()
                ThreemaSafeSection()
                IDSection()
                LinkedDataSection()
                PublicKeySection()
                RemoveIDAndDataSection()
            }
            .navigationDestination(for: AnyViewDestination.self)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leftBarButtonItem
                }
                ToolbarItem(placement: isModallyPresented ? .topBarLeading : .topBarTrailing) {
                    rightBarButtonItem
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(model)
            .environmentObject(model.navigator)
            .onAppear { model.load() }
            .onReceive(\.identityLinked) { _ in model.load() }
            .onReceive(\.enteredForeground) { _ in model.load() }
            .onReceive(\.showSafeSetup) { _ in
                model.navigator.navigate(ThreemaSafeSection.safe)
            }
            .onReceive(\.profileSyncPublisher) { _ in model.incomingSync() }
        }
    }
    
    @ViewBuilder
    private var leftBarButtonItem: some View {
        Button(
            action: editAction,
            label: {
                Text("profile_edit".localized)
            }
        )
        .accessibilityLabel("edit_profile".localized)
    }
    
    @ViewBuilder
    private var rightBarButtonItem: some View {
        if ScanIdentityController.canScan() {
            Button(action: scanAction, label: {
                Image(systemName: "qrcode.viewfinder")
            })
            .tint(UIColor.primary.color)
            .accessibilityLabel("scan_identity".localized)
        }
    }
    
    private func editAction() {
        guard let topViewController else {
            return
        }
        
        if UserSettings.shared().enableMultiDevice,
           BusinessInjector().serverConnector.connectionState != .loggedIn {
            
            UIAlertTemplate.showAlert(
                owner: topViewController,
                title: "not_connected_for_edit_profile_title".localized,
                message: "not_connected_for_edit_profile_message".localized
            )
        }
        else {
            let vc = ProfileView.viewController("editProfileViewController")
            let mvc = ModalNavigationController(rootViewController: vc)
            mvc.modalDelegate = model.delegateHandler
            ModalPresenter.present(mvc, on: topViewController)
        }
    }
    
    private func scanAction() {
        guard let topViewController else {
            return
        }
        
        guard let disableAddContact = model.mdmSetup?.disableAddContact(), disableAddContact else {
            let scanIdentity = ScanIdentityController()
            scanIdentity.containingViewController = topViewController
            scanIdentity.startScan()
            
            BusinessInjector().contactStore
                .synchronizeAddressBook(
                    forceFullSync: true,
                    ignoreMinimumInterval: false,
                    onCompletion: nil
                )
            
            return
        }
        
        UIAlertTemplate.showAlert(
            owner: topViewController,
            title: "",
            message: "disabled_by_device_policy".localized
        )
    }
}
