//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2020-2024 Threema GmbH
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
import GroupCalls
import MarqueeLabel
import SnapKit
import ThreemaFramework

@objc class NotificationBannerHelper: NSObject {
    @objc class func newBanner(baseMessage: BaseMessage) {
        DispatchQueue.main.async {
            // Reload CoreData object because of concurrency problem
            let entityManager = EntityManager()
            let message = entityManager.entityFetcher.getManagedObject(by: baseMessage.objectID) as! BaseMessage

            var contactImageView: UIImageView?
            var thumbnailImageView: UIImageView?
            
            var title = message.conversation.displayName
            
            if let contactImage = AvatarMaker.shared().avatar(for: message.conversation, size: 56.0, masked: true) {
                contactImageView = UIImageView(image: contactImage)
            }
            
            if let imageMessageEntity = message as? ImageMessageEntity {
                if let thumbnail = imageMessageEntity.thumbnail {
                    thumbnailImageView = UIImageView(image: thumbnail.uiImage)
                    thumbnailImageView?.contentMode = .scaleAspectFit
                }
            }
            else if let fileMessageEntity = message as? FileMessageEntity {
                if let thumbnail = fileMessageEntity.thumbnail {
                    thumbnailImageView = UIImageView(image: thumbnail.uiImage)
                    thumbnailImageView?.contentMode = .scaleAspectFit
                }
            }
            else if message.isKind(of: AudioMessageEntity.self) {
                let thumbnail = BundleUtil.imageNamed("ActionMicrophone")?.withTint(Colors.text)
                thumbnailImageView = UIImageView(image: thumbnail)
                thumbnailImageView?.contentMode = .center
            }
            
            let titleFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
            
            var body = message.previewText()
            body = TextStyleUtils.makeMentionsString(forText: body)
            
            if message.isGroupMessage {
                // Quickfix: Sender should never be `nil` for an incoming group message
                if let sender = message.sender {
                    body = "\(sender.displayName): \(body ?? "")"
                }
            }
            
            if message.conversation.conversationCategory == .private {
                title = BundleUtil.localizedString(forKey: "private_message_label")
                body = " "
                thumbnailImageView = nil
                
                if message.isGroupMessage {
                    contactImageView = UIImageView(image: AvatarMaker.shared().unknownGroupImage())
                }
                else {
                    contactImageView = UIImageView(image: AvatarMaker.shared().unknownPersonImage())
                }
            }
            
            let banner = FloatingNotificationBanner(
                title: title,
                subtitle: "",
                titleFont: UIFont.boldSystemFont(ofSize: titleFontDescriptor.pointSize),
                titleColor: Colors.text,
                subtitleFont: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
                subtitleColor: Colors.text,
                leftView: contactImageView,
                rightView: thumbnailImageView,
                style: .info,
                colors: CustomBannerColors(),
                sideViewSize: 50.0
            )
            
            if let groupID = message.conversation?.groupID {
                banner.identifier = groupID.hexEncodedString()
            }
            else {
                if let contact = message.conversation?.contact {
                    banner.identifier = contact.identity
                }
            }
            
            banner.transparency = 0.9
            banner.duration = 3.0
            banner.applyStyling(cornerRadius: 8)
            banner.subtitleLabel?.numberOfLines = 2
            
            var formattedAttributeString: NSMutableAttributedString?
            if message.conversation.groupID != nil {
                var contactString = ""
                if !message.isKind(of: SystemMessage.self) {
                    if let sender = message.sender {
                        contactString = "\(sender.displayName): "
                    }
                    else {
                        contactString = "\(BundleUtil.localizedString(forKey: "me")): "
                    }
                }
                
                let attributed = TextStyleUtils.makeAttributedString(
                    from: message.previewText(),
                    with: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
                    textColor: Colors.text,
                    isOwn: true,
                    application: UIApplication.shared
                )
                let messageAttributedString = NSMutableAttributedString(
                    attributedString: banner.subtitleLabel!
                        .applyMarkup(for: attributed)
                )
                let attributedContact = TextStyleUtils.makeAttributedString(
                    from: contactString,
                    with: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
                    textColor: Colors.text,
                    isOwn: true,
                    application: UIApplication.shared
                )
                formattedAttributeString = NSMutableAttributedString(attributedString: attributedContact!)
                formattedAttributeString?.append(messageAttributedString)
            }
            else {
                let attributed = TextStyleUtils.makeAttributedString(
                    from: message.previewText(),
                    with: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
                    textColor: Colors.text,
                    isOwn: true,
                    application: UIApplication.shared
                )
                formattedAttributeString = NSMutableAttributedString(
                    attributedString: banner.subtitleLabel!
                        .applyMarkup(for: attributed)
                )
            }
            
            if message.conversation.conversationCategory == .private {
                banner.subtitleLabel?.setText(nil)
            }
            else {
                banner.subtitleLabel!.attributedText = TextStyleUtils.makeMentionsAttributedString(
                    for: formattedAttributeString,
                    textFont: banner.subtitleLabel!.font,
                    at: Colors.textLight.withAlphaComponent(0.6),
                    messageInfo: 2,
                    application: UIApplication.shared
                )
            }
            banner.onTap = {
                banner.bannerQueue.dismissAllForced()
                // switch to selected conversation
                if let conversation = message.conversation {
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: kNotificationShowConversation),
                        object: nil,
                        userInfo: [kKeyConversation: conversation]
                    )
                }
            }
            
            banner.onSwipeUp = {
                banner.bannerQueue.removeAll()
            }
            let shadowEdgeInsets = UIEdgeInsets(top: 8, left: 2, bottom: 0, right: 2)
            if Colors.theme == .dark {
                banner.show(
                    shadowColor: Colors.shadowNotification,
                    shadowOpacity: 0.5,
                    shadowBlurRadius: 7,
                    shadowEdgeInsets: shadowEdgeInsets
                )
            }
            else {
                banner.show(
                    shadowColor: Colors.shadowNotification,
                    shadowOpacity: 1.0,
                    shadowBlurRadius: 10,
                    shadowEdgeInsets: shadowEdgeInsets
                )
            }
        }
    }
    
    class func newBannerForStartGroupCall(
        conversationManagedObjectID: NSManagedObjectID,
        title: String,
        body: String,
        contactImage: UIImage,
        identifier: String
    ) {
        let titleFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        
        let banner = FloatingNotificationBanner(
            title: title,
            subtitle: body,
            titleFont: UIFont.boldSystemFont(ofSize: titleFontDescriptor.pointSize),
            titleColor: Colors.text,
            subtitleFont: UIFont.preferredFont(forTextStyle: .title1),
            subtitleColor: Colors.text,
            leftView: UIImageView(image: contactImage),
            rightView: nil,
            style: .info,
            colors: CustomBannerColors(),
            sideViewSize: 50.0
        )
        
        banner.identifier = identifier
        banner.transparency = 0.9
        banner.duration = 3.0
        banner.applyStyling(cornerRadius: 8)
        banner.subtitleLabel?.numberOfLines = 2
        
        let attributed = TextStyleUtils.makeAttributedString(
            from: body,
            with: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
            textColor: Colors.text,
            isOwn: true,
            application: UIApplication.shared
        )
        let bodyAttributedString = NSMutableAttributedString(
            attributedString: banner.subtitleLabel!
                .applyMarkup(for: attributed)
        )
        
        banner.subtitleLabel!.attributedText = bodyAttributedString
        
        banner.onTap = {
            banner.bannerQueue.dismissAllForced()
            // switch to selected conversation
            let entityManager = BusinessInjector().entityManager
            entityManager.performBlock {
                if let conversation = entityManager.entityFetcher.getManagedObject(by: conversationManagedObjectID) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: kNotificationShowConversation),
                        object: nil,
                        userInfo: [kKeyConversation: conversation]
                    )
                }
            }
        }
        
        banner.onSwipeUp = {
            banner.bannerQueue.removeAll()
        }
        let shadowEdgeInsets = UIEdgeInsets(top: 8, left: 2, bottom: 0, right: 2)
        if Colors.theme == .dark {
            banner.show(
                shadowColor: Colors.shadowNotification,
                shadowOpacity: 0.5,
                shadowBlurRadius: 7,
                shadowEdgeInsets: shadowEdgeInsets
            )
        }
        else {
            banner.show(
                shadowColor: Colors.shadowNotification,
                shadowOpacity: 1.0,
                shadowBlurRadius: 10,
                shadowEdgeInsets: shadowEdgeInsets
            )
        }
    }
        
    @objc class func dismissAllNotifications() {
        DispatchQueue.main.async {
            NotificationBannerQueue.default.removeAll()
        }
    }
    
    @objc class func dismissAllNotifications(for conversation: Conversation) {
        DispatchQueue.main.async {
            var identifier: String?
            if let groupID = conversation.groupID {
                identifier = groupID.hexEncodedString()
            }
            else if let contact = conversation.contact {
                identifier = contact.identity
            }
            else {
                return
            }
            let banners = NotificationBannerQueue.default.banners
            for banner in banners {
                if banner.identifier == identifier {
                    if banner.isDisplaying == true {
                        banner.dismiss()
                    }
                    NotificationBannerQueue.default.removeBanner(banner)
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Use `NotificationPresenterWrapper` instead")
    @objc class func newInfoToast(title: String, body: String) {
        newToast(title: title, body: body, bannerStyle: .warning)
    }
    
    @available(*, deprecated, message: "Use `NotificationPresenterWrapper` instead")
    @objc class func newErrorToast(title: String, body: String) {
        newToast(title: title, body: body, bannerStyle: .danger)
    }
    
    @objc class func newSuccessToast(title: String, body: String) {
        newToast(title: title, body: body, bannerStyle: .success)
    }
    
    @available(*, deprecated, message: "Use `NotificationPresenterWrapper` instead")
    private class func newToast(title: String, body: String, bannerStyle: BannerStyle) {
        DispatchQueue.main.async {
            let titleFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
            
            let banner = FloatingNotificationBanner(
                title: title,
                subtitle: body,
                titleFont: UIFont.boldSystemFont(ofSize: titleFontDescriptor.pointSize),
                titleColor: Colors.text,
                subtitleFont: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize),
                subtitleColor: Colors.white,
                leftView: UIImageView(image: BundleUtil.imageNamed("InfoFilled")),
                rightView: nil,
                style: bannerStyle,
                colors: CustomBannerColors()
            )
            
            banner.titleLabel!.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    NSAttributedString.Key.foregroundColor: Colors.white as Any,
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: titleFontDescriptor.pointSize) as Any,
                ]
            )
            banner.subtitleLabel!.attributedText = NSAttributedString(
                string: body,
                attributes: [
                    NSAttributedString.Key.foregroundColor: Colors.white as Any,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: bodyFontDescriptor.pointSize) as Any,
                ]
            )
            
            banner.transparency = 1.0
            banner.duration = 5.0
            banner.subtitleLabel?.numberOfLines = 0
            
            banner.show()
        }
    }
}

class CustomBannerColors: BannerColorsProtocol {
    internal func color(for style: BannerStyle) -> UIColor {
        switch style {
        case .danger: return Colors.red
        case .info: return Colors.backgroundNotification
        case .customView: return Colors.backgroundNotification
        case .success: return Colors.green
        case .warning: return Colors.orange
        }
    }
}
