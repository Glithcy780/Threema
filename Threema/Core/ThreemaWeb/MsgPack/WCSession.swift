//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2019-2024 Threema GmbH
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

import CocoaLumberjackSwift
import Foundation

@objc public class WCSession: NSObject, NSCoding {
    
    internal var privateKey: Data?
    internal var webClientSession: WebClientSession?
    internal var messageQueue: WebMessageQueue
    
    private var connection: WCConnection?
    
    private var requestedConversations = [String]()
    private var requestedThumbnails = [Data]()
    private var lastLoadedMessageIndexes = [Data: Int]()
    private var requestCreateMessagesFromWeb = [String: WebAbstractMessage]()
    
    private(set) var webClientProcessQueue: DispatchQueue
    
    public init(webClientSession: WebClientSession) {
        self.webClientSession = webClientSession
        self.privateKey = webClientSession.privateKey
        var hash = webClientSession.initiatorPermanentPublicKeyHash
        
        if hash == nil {
            hash = WCSession.ccSha256(data: webClientSession.initiatorPermanentPublicKey!).hexEncodedString()
            WebClientSessionStore.shared.updateWebClientSession(session: webClientSession, hash: hash!)
        }
        self.webClientProcessQueue = DispatchQueue(label: "ch.threema.webClientProcessQueue", attributes: [])
        self.messageQueue = WebMessageQueue()
        super.init()
        messageQueue.delegate = self
    }
    
    // MARK: NSCoding

    public required init?(coder aDecoder: NSCoder) {
        // super.init(coder:) is optional, see notes below
        self.privateKey = aDecoder.decodeObject(forKey: "privateKey") as? Data
        self.connection = aDecoder.decodeObject(forKey: "connection") as? WCConnection
        let entityManager = EntityManager()
        if privateKey != nil {
            self.webClientSession = entityManager.entityFetcher.webClientSession(forPrivateKey: privateKey!)
        }
        else {
            self.webClientSession = entityManager.entityFetcher.activeWebClientSession()
        }
        self.messageQueue = aDecoder.decodeObject(forKey: "messageQueue") as! WebMessageQueue
        self.requestedConversations = aDecoder.decodeObject(forKey: "requestedConversations") as! [String]
        self.requestedThumbnails = aDecoder.decodeObject(forKey: "requestedThumbnails") as! [Data]
        self.lastLoadedMessageIndexes = aDecoder.decodeObject(forKey: "lastLoadedMessageIndexes") as! [Data: Int]
        self.requestedConversations = aDecoder.decodeObject(forKey: "requestedConversations") as! [String]
        self.webClientProcessQueue = DispatchQueue(label: "ch.threema.webClientProcessQueue", attributes: [])
    }
    
    public func encode(with aCoder: NSCoder) {
        // super.encodeWithCoder(aCoder) is optional, see notes below
        aCoder.encode(privateKey, forKey: "privateKey")
        aCoder.encode(connection, forKey: "connection")
        aCoder.encode(messageQueue, forKey: "messageQueue")
        aCoder.encode(requestedConversations, forKey: "requestedConversations")
        aCoder.encode(requestedThumbnails, forKey: "requestedThumbnails")
        aCoder.encode(lastLoadedMessageIndexes, forKey: "lastLoadedMessageIndexes")
    }
}

extension WCSession {
    // MARK: class functions
    
    class func ccSha256(data: Data) -> Data {
        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes { digestBuffer in
            data.withUnsafeBytes { buffer in
                _ = CC_SHA256(
                    buffer.baseAddress!,
                    CC_LONG(buffer.count),
                    digestBuffer.bindMemory(to: UInt8.self).baseAddress
                )
            }
        }
        return digest
    }
}

extension WCSession {
    // MARK: public functions
    
    public func connect(authToken: Data?) {
        let newConnection = WCConnection(delegate: self)
        if connection != nil {
            if connection!.context != nil {
                newConnection.context = connection!.context!.copy() as? WebConnectionContext
            }
            
            let oldConnection = connection
            ValidationLogger.shared().logString("[Threema Web] Close old session")
            oldConnection?.close(close: false, forget: false, sendDisconnect: false, reason: .replace)
        }
        connection = newConnection
        connection?.connect(authToken: authToken)
    }
    
    public func sendMessage() { }
    
    public func receive() { }
    
    public func stop(close: Bool, forget: Bool, sendDisconnect: Bool, reason: WCConnection.WCConnectionStopReason) {
        connection?.close(close: close, forget: forget, sendDisconnect: sendDisconnect, reason: reason)
    }
    
    internal func setWCConnectionStateToReady() {
        connection?.setWCConnectionStateToReady()
    }
    
    internal func setWCConnectionStateToConnectionInfoReceived() {
        connection?.setWCConnectionStateToConnectionInfoReceived()
    }
    
    internal func connectionContext() -> WebConnectionContext? {
        connection?.context
    }
    
    internal func connectionInfoResponse() -> WebUpdateConnectionInfoResponse? {
        connection?.connectionInfoResponse
    }
    
    internal func sendChunk(chunk: [UInt8], msgpack: Data?, connectionInfo: Bool) {
        connection?.sendChunk(chunk: chunk, msgpack: msgpack, connectionInfo: connectionInfo)
    }
    
    internal func connectionWca() -> String? {
        connection?.wca
    }
    
    internal func setWcaForConnection(wca: String) {
        connection?.wca = wca
    }
    
    internal func addRequestCreateMessage(requestID: String, abstractMessage: WebAbstractMessage) {
        requestCreateMessagesFromWeb[requestID] = abstractMessage
    }
    
    internal func removeRequestCreateMessage(requestID: String) {
        requestCreateMessagesFromWeb.removeValue(forKey: requestID)
    }
    
    internal func requestMessage(for requestID: String) -> WebAbstractMessage? {
        requestCreateMessagesFromWeb[requestID]
    }
}

extension WCSession {
    // MARK: Requested lists
    
    public func requestedConversations(contains conversationID: String) -> Bool {
        requestedConversations.contains(conversationID)
    }
    
    public func addRequestedConversation(conversationID: String) {
        if !requestedConversations(contains: conversationID) {
            requestedConversations.append(conversationID)
        }
    }
    
    public func requestedThumbnails(contains messageID: Data) -> Bool {
        requestedThumbnails.contains(messageID)
    }
    
    public func addRequestedThumbnail(messageID: Data) {
        if !requestedThumbnails(contains: messageID) {
            requestedThumbnails.append(messageID)
        }
    }
    
    public func lastLoadedMessageIndexes(contains messageID: Data) -> Int? {
        lastLoadedMessageIndexes[messageID]
    }
    
    public func addLastLoadedMessageIndex(messageID: Data, index: Int) {
        lastLoadedMessageIndexes[messageID] = index
    }
    
    public func clearAllRequestedLists() {
        requestedConversations.removeAll()
        requestedThumbnails.removeAll()
        lastLoadedMessageIndexes.removeAll()
    }
}

// MARK: - MessageCompleteDelegate

extension WCSession: MessageCompleteDelegate {
    func messageComplete(message: Data) {
        do {
            let object = try message.unpack() as! [AnyHashable: Any?]
            
            let webMessage = WebAbstractMessage(dictionary: object)
            DDLogVerbose(
                "[Threema Web] MessagePack -> Received \(webMessage.messageType)/\(webMessage.messageSubType ?? "")"
            )
            webClientProcessQueue.async {
                webMessage.getResponseMsgpack(session: self, completionHandler: { responseMsgpack, blackListed in
                    if responseMsgpack != nil {
                        self.messageQueue.enqueue(data: responseMsgpack, blackListed: blackListed)
                    }
                    else {
                        print("ResponseMsgpack is nil")
                    }
                })
            }
        }
        catch {
            print("Something went wrong while unpacking data: \(error)")
        }
    }
}

// MARK: - WCConnectionDelegate

extension WCSession: WCConnectionDelegate {
    internal func currentWebClientSession() -> WebClientSession? {
        webClientSession
    }
    
    internal func currentWCSession() -> WCSession {
        self
    }
    
    internal func currentMessageQueue() -> WebMessageQueue {
        messageQueue
    }
}

// MARK: - WebMessageQueueDelegate

extension WCSession: WebMessageQueueDelegate {
    internal func sendMessageToWeb(blacklisted: Bool, msgpack: Data, _ connectionInfo: Bool = false) {
        connection?.sendMessageToWeb(blacklisted: blacklisted, msgpack: msgpack, connectionInfo)
    }
    
    internal func connectionStatus() -> WCConnectionState? {
        connection?.connectionStatus
    }
}
