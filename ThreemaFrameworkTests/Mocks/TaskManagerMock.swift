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
@testable import ThreemaFramework

class TaskManagerMock: NSObject, TaskManagerProtocol {
    
    typealias TaskAddedCallback = () -> Void
    
    var addedTasks = [TaskDefinitionProtocol]() {
        didSet {
            taskAdded?()
        }
    }
    
    /// Called on each task added
    var taskAdded: TaskAddedCallback?
    
    init(taskAdded: TaskAddedCallback? = nil) {
        self.taskAdded = taskAdded
    }
    
    // MARK: Mocks
    
    func add(taskDefinition: TaskDefinitionProtocol) {
        addedTasks.append(taskDefinition)
    }

    func add(taskDefinition: TaskDefinitionProtocol, completionHandler: @escaping TaskCompletionHandler) {
        addedTasks.append(taskDefinition)
        completionHandler(taskDefinition, nil)
    }
    
    func add(taskDefinitionTuples: [(
        taskDefinition: TaskDefinitionProtocol,
        completionHandler: TaskCompletionHandler
    )]) {
        for tuple in taskDefinitionTuples {
            add(taskDefinition: tuple.taskDefinition, completionHandler: tuple.completionHandler)
        }
    }
    
    static func flush(queueType: TaskQueueType) { }

    static func isEmpty(queueType: TaskQueueType) -> Bool {
        false
    }
    
    func spool() { }
    
    func save() { }
}

// MARK: - TaskManagerProtocolObjc

extension TaskManagerMock: TaskManagerProtocolObjc {
    func addObjc(taskDefinition: AnyObject) {
        // no-op
    }

    func addObjc(taskDefinition: AnyObject, completionHandler: @escaping (AnyObject, Error?) -> Void) {
        // no-op
    }
}
