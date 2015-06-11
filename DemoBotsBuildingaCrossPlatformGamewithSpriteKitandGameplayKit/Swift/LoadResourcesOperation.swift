/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A subclass of `NSOperation` that manages the loading of a `ResourceLoadableType`'s resources.
            
*/

import Foundation

class LoadResourcesOperation: NSOperation {
    // MARK: Properties
    
    private var _executing = false
    override var executing: Bool {
        get {
            return _executing
        }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    
    private var _finished = false
    override var finished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    override var asynchronous: Bool {
        return true
    }
    
    /// A class that conforms to the `ResourceLoadableType` protocol.
    var loadableType: ResourceLoadableType.Type
    
    // MARK: Initialization
    
    init(loadableType: ResourceLoadableType.Type) {
        self.loadableType = loadableType
    }
    
    // MARK: NSOperation
    
    override func start() {
        // If the operation is cancelled there's nothing to do. 
        guard !cancelled else { return }
        
        // Avoid reloading the resources if they are already available.
        guard loadableType.resourcesNeedLoading else {
            finished = true
            return
        }
        
        // Mark the operation as executing.
        executing = true
        
        // Begin loading the resources.
        loadableType.loadResourcesWithCompletionHandler {
            // Mark the operation as complete once the resources are loaded.
            self.executing = false
            self.finished = true
        }
    }
}
