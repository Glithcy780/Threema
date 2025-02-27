//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2022-2024 Threema GmbH
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

struct MultiDeviceWizardInformationView: View {
    @Environment(\.openURL) var openURL

    @ObservedObject var wizardVM: MultiDeviceWizardViewModel
    @Binding var dismiss: Bool

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        MultiDeviceWizardBulletPointView(
                            text: BundleUtil.localizedString(forKey: "md_wizard_info_download_title"),
                            imageName: "arrow.down.circle.fill"
                        )
                        .padding(.bottom, 2.0)
                        
                        Text(BundleUtil.localizedString(forKey: "md_wizard_info_download_text"))
                        
                        Link("three.ma/md", destination: URL(string: "https://three.ma/md")!)
                            .foregroundColor(Color(.primary))
                            .highPriorityGesture(DragGesture())
                    }
                    .padding(.top)
                    .accessibilityElement(children: .combine)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        MultiDeviceWizardBulletPointView(
                            text: BundleUtil.localizedString(forKey: "md_wizard_info_linking_title"),
                            imageName: "link.circle.fill"
                        )
                        .padding(.bottom, 2.0)
                        
                        Text(LocalizedStringKey(String.localizedStringWithFormat(
                            BundleUtil.localizedString(forKey: "md_wizard_info_linking_text"),
                            DeviceLinking(businessInjector: BusinessInjector()).threemaSafeServer
                        )))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAction(named: Text(String.localizedStringWithFormat(
                        BundleUtil.localizedString(forKey: "accessibility_action_open_link"),
                        "https://threema.ch/en/faq/threema_safe_webdav"
                    ))) {
                        openURL(URL(string: "https://threema.ch/en/faq/threema_safe_webdav")!)
                    }
                }
            }
            Spacer()
                
            HStack {
                Button {
                    dismiss = true
                    wizardVM.cancelLinking()
                } label: {
                    Text(BundleUtil.localizedString(forKey: "md_wizard_cancel"))
                }
                .buttonStyle(.bordered)
                .tint(Color(.primary))
                    
                Spacer()
                    
                NavigationLink {
                    MultiDeviceWizardPreparationView(wizardVM: wizardVM, dismiss: $dismiss)
                        
                } label: {
                    Text(BundleUtil.localizedString(forKey: "md_wizard_start"))
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        
        .navigationBarTitle(BundleUtil.localizedString(forKey: "md_wizard_header"))
        .navigationBarBackButtonHidden()
        
        .onAppear {
            wizardVM.advanceState(.information)
        }
    }
}

// MARK: - Preview

struct MultiDeviceWizardProcessView_Previews: PreviewProvider {
    static var previews: some View {
        MultiDeviceWizardInformationView(wizardVM: MultiDeviceWizardViewModel(), dismiss: .constant(false))
    }
}
