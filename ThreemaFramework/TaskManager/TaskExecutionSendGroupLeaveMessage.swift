//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2020-2023 Threema GmbH
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
import PromiseKit

/// Reflect group leave message to mediator server is multi device enabled
/// and send it to group members (CSP).
/// Additionally, clean up hidden contacts of group (if they are unused after leave+delete of the group).
final class TaskExecutionSendGroupLeaveMessage: TaskExecution, TaskExecutionProtocol {
    func execute() -> Promise<Void> {
        guard let task = taskDefinition as? TaskDefinitionSendGroupLeaveMessage else {
            return Promise(error: TaskExecutionError.wrongTaskDefinitionType)
        }
        
        guard let groupID = task.groupID, let groupCreatorIdentity = task.groupCreatorIdentity, task.fromMember != nil,
              task.toMembers != nil else {
            return Promise(error: TaskExecutionError.missingGroupInformation)
        }

        return firstly {
            try self.generateMessageNonces(for: taskDefinition)
            return isMultiDeviceRegistered()
        }
        .then { doReflect -> Promise<Void> in
            // Reflect group leave message if is necessary
            guard doReflect else {
                return Promise()
            }
            
            let msg = self.getGroupLeaveMessage(
                groupID,
                groupCreatorIdentity,
                task.fromMember,
                self.frameworkInjector.myIdentityStore.identity
            )
            try self.reflectMessage(
                message: msg,
                ltReflect: self.taskContext.logReflectMessageToMediator,
                ltAck: self.taskContext.logReceiveMessageAckFromMediator
            )

            return Promise()
        }
        .then { _ -> Promise<[AbstractMessage?]> in
            // Send group leave messages
            var sendMessages = [Promise<AbstractMessage?>]()
            for toMember in task.toMembers {
                if toMember == self.frameworkInjector.myIdentityStore.identity {
                    continue
                }
              
                let msg = self.getGroupLeaveMessage(groupID, groupCreatorIdentity, task.fromMember, toMember)
                sendMessages.append(
                    self.sendMessage(
                        message: msg,
                        ltSend: self.taskContext.logSendMessageToChat,
                        ltAck: self.taskContext.logReceiveMessageAckFromChat
                    )
                )
            }
            
            return when(fulfilled: sendMessages)
        }
        .then { _ -> Promise<Void> in
            // cleanup: try deleting hidden contacts, delete happens iff they are not used elsewhere
            for identity in task.hiddenContacts {
                self.frameworkInjector.contactStore.deleteContact(
                    identity: identity,
                    entityManagerObject: self.frameworkInjector.entityManager
                )
            }
            return Promise()
        }
    }
}
