//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2022-2023 Threema GmbH
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

extension SystemMessage: MessageAccessibility {
    
    public var customAccessibilityLabel: String {
        
        switch systemMessageType {
        case let .callMessage(type: call):
            var localizedLabel = call.localizedMessage
            
            if let duration = callTime() {
                let durationString = String.localizedStringWithFormat(
                    BundleUtil.localizedString(forKey: "call_duration"),
                    duration
                )
                localizedLabel.append(durationString)
            }
            
            return "\(localizedLabel)."
            
        case let .workConsumerInfo(type: wcInfo):
            return String.localizedStringWithFormat(
                BundleUtil.localizedString(forKey: "accessibility_senderDescription_systemMessage"),
                wcInfo.localizedMessage
            )
            
        case let .systemMessage(type: infoType):
            return String.localizedStringWithFormat(
                BundleUtil.localizedString(forKey: "accessibility_senderDescription_systemMessage"),
                infoType.localizedMessage
            )
        }
    }
    
    public var customAccessibilityHint: String? {
        switch systemMessageType {
        case .callMessage:
            return BundleUtil.localizedString(forKey: "accessibility_systemCallMessage_hint")
        case .workConsumerInfo, .systemMessage:
            return nil
        }
    }
    
    public var customAccessibilityTrait: UIAccessibilityTraits {
        switch systemMessageType {
        case .callMessage:
            return [.button, .staticText]
            
        case .workConsumerInfo, .systemMessage:
            return [.staticText, .notEnabled]
        }
    }
    
    public var accessibilityMessageTypeDescription: String {
        // The other system message types do not need a description
        guard case .callMessage = systemMessageType else {
            return ""
        }
        
        return BundleUtil.localizedString(forKey: "accessibility_systemCallMessage_description")
    }
}
