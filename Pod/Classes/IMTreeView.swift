//
//  IMTreeView.swift
//  rslash
//
//  Created by Ian McDowell on 3/7/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import UIKit

/// This class contains variables useful to the extended UITableView. Since you can't define variables
/// in an extension, they are static variables here.
public class IMTreeView {
    
    /// Static dictionary containing all tree views used by the application.
    private static var treeViews = [Int: IMTreeView]()
    
    /// Returns the IMTreeView object for a tableView, and if it doesn't exist, it creates one.
    public static func get(treeView: UITableView) -> IMTreeView {
        let hash = treeView.hashValue // a hash value reference to the tableView, in case it gets deallocated later
        
        //let wtv = WeakTableView(treeView)
        if let tv = IMTreeView.treeViews[hash] {
            return tv
        }
        let tv = IMTreeView()
        IMTreeView.treeViews[hash] = tv
        return tv
    }
    
    /// Private internal storage for the library. Maps `NSIndexPath`s to the number of children they have.
    private var model = [NSIndexPath: Int]()
    
    /// Private internal storage for the library. Maps `NSIndexPath`s to the number of children they have.
    private var directModel = [NSIndexPath: Int]()
    
    /// The animation to use when expanding
    public var expandingAnimation: UITableViewRowAnimation = .Automatic
    
    /// The animation to use when collapsing
    public var collapsingAnimation: UITableViewRowAnimation = .Automatic
}


/// The protocol that is a data source for a n-deep tree view. This _MUST_ be applied to the same datasource as the `UITableViewDataSource`!
/// All methods are optional.
public protocol IMTreeViewDataSource {
    func tableView(tableView: UITableView, numberOfChildrenForIndexPath indexPath: NSIndexPath) -> Int
    func tableView(tableView: UITableView, isCellExpandedAtIndexPath indexPath: NSIndexPath) -> Bool
}


/// This extension on the IMTreeViewDataSource defines the default implementations of the data source methods.
public extension IMTreeViewDataSource {
    func tableView(tableView: UITableView, numberOfChildrenForIndexPath indexPath: NSIndexPath) -> Int {
        return 0
    }
    func tableView(tableView: UITableView, isCellExpandedAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}


/// The core of this library is an extension of UITableView. This was decided for a number of reasons.
///
/// - 1: You can use the set of APIs you are already familiar with
/// - 2: All obscure and future APIs added to UITableView will automatically be usable.
/// - 3: This allows a developer to migrate their code to use a tree structure from a 2D structure relatively easily.
///
/// There are a number of limitations and drawbacks to going by this approach.
///
/// - 1: The UITableView still requires a UITableViewDataSource, meaning you must implement the basic 3 methods.
///      `tableView:numberOfRowsInSection(_)` may be confusing to developers, since a section contains rows, with rows
///       within them, which may be hard to count. Fortunately, the developer doesn't have to count these themself. It is
///       recommended to use the `numberOfItemsInSection(section)` method (part of the extension), which uses the 
///       IMTreeViewDataSource methods to count this information.
/// - 2: In order to switch a UITableView into a tree-based tableview, you must also implement a separate datasource:
///      `IMTreeViewDataSource`. This contains tree-specific methods.
/// - 3: All UITableViews in the application will be extended, since that is how extending a class works. This library has been
///      designed not to mess with the default implementation of a UITableView, and will not mess with UITableViews whose dataSources
///      are not also `IMTreeViewDataSource`s.
public extension UITableView {
    
    
    // MARK: Public
    
    
    /// Returns the number if items in the given section of the tree
    ///
    /// - Parameter section: The section of the table view
    /// - Returns: The number of items (and sub-items) in the section
    public func numberOfItemsInSection(section: Int) -> Int {
        var rows = 0
        if let ds = self.dataSource as? IMTreeViewDataSource {
            rows = ds.tableView(self, numberOfChildrenForIndexPath: NSIndexPath(index: section))
        }
        var totalRowsCount = rows
        
        let ip = NSIndexPath(index: section)
        IMTreeView.get(self).directModel[ip] = rows
        
        for i in 0..<rows {
            let ip  = NSIndexPath(forRow: i, inSection: section)
            totalRowsCount += self.numberOfChildren(ip)
        }
        
        IMTreeView.get(self).model[ip] = totalRowsCount
        
        return totalRowsCount
    }
    
    
    /// Expands the row at the given index path (n-dimensional)
    ///
    /// - Parameter indexPath: The index path to expand
    public func expand(indexPath: NSIndexPath) {
        if self.isExpanded(indexPath) {
            return
        }
        
        let _ = self.numberOfChildren(indexPath) // make sure to enumerate the children, so it is present in the model
        
        let insertRows = self.getRowsToExpand(indexPath)
        
        self.insertRowsAtIndexPaths(insertRows, withRowAnimation: IMTreeView.get(self).expandingAnimation)
    }
    
    
    /// Checks if the row at the given index path (n-dimensional) is expanded
    ///
    /// - Parameter indexPath: The index path referred to
    /// - Returns: Whether or not the index path is expanded
    public func isExpanded(indexPath: NSIndexPath) -> Bool {
        return IMTreeView.get(self).directModel[indexPath] != nil
    }
    
    
    /// Collapses the row at the given index path
    ///
    /// - Parameter indexPath: The index path to collapse
    public func collapse(indexPath: NSIndexPath) {
        if !self.isExpanded(indexPath) {
            return
        }
        
        let dismissRows = self.getRowsToCollapse(indexPath)
        
        self.deleteRowsAtIndexPaths(dismissRows, withRowAnimation: IMTreeView.get(self).collapsingAnimation)
    }
    
    
    /// Returns the sibling index paths to the given one. (rows at the same level, with the same parent)
    ///
    /// - Parameter indexPath: The index path to find siblings of
    /// - Returns: An array of index paths containing the siblings. Does not include the given indexPath
    public func siblings(indexPath: NSIndexPath) -> [NSIndexPath] {
        let parent = self.parent(indexPath)
        var arr = [NSIndexPath]()
        
        for i in 0 ..< self.numberOfSections {
            var ip: NSIndexPath
            if parent != nil {
                ip = parent!.indexPathByAddingIndex(i)
            } else {
                ip = NSIndexPath(index: i)
            }
            
            if ip.compare(indexPath) != .OrderedSame {
                arr.append(ip)
            }
        }
        return arr
    }
    
    
    /// Gets the parent of a given index path (n-dimensional). If there is no parent, it will return nil.
    /// 
    /// - Returns: An optional index path that represents the parent.
    public func parent(indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.length > 1 {
            return indexPath.indexPathByRemovingLastIndex()
        }
        return nil
    }
    
    
    /// Convenience method to return the `UITableViewCell` for the given tree index path (n-dimensional)
    public func cellForRowAtTreeIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
        return self.cellForRowAtIndexPath(self.tableIndexPathFromTreePath(indexPath))!
    }
    
    
    /// Convenience method to get the tree index path of a cell (n-dimensional)
    public func treeIndexPathForCell(cell: UITableViewCell) -> NSIndexPath {
        return self.treeIndexPathFromTablePath(self.indexPathForCell(cell)!)
    }
    
    
    /// Coverts multidimensional indexPath into 2d UITableView-like indexPath.
    ///
    /// This method is required to prepare indexPath parameter when calling original UITableView's methods.
    public func tableIndexPathFromTreePath(indexPath: NSIndexPath) -> NSIndexPath {
        let row = self.rowOffsetForIndexPath(indexPath)
        return NSIndexPath(forRow: row, inSection: 0)
    }
    
    
    /// Converts UITableTable 2d indexPath into multidimentional indexPath.
    ///
    /// - Parameter indexPath: 2d UITableView-like index path
    /// - Returns: multidimantional TreeView-like indexPath.
    public func treeIndexPathFromTablePath(indexPath: NSIndexPath) -> NSIndexPath {
        var count = 0
        
        let section = indexPath.section
        let row = indexPath.row
        
        let ip = NSIndexPath(index: section)
        guard let rowsCount = IMTreeView.get(self).directModel[ip] else {
            return NSIndexPath()
        }
        
        for i in 0 ..< rowsCount {
            let ip = NSIndexPath(forRow: i, inSection: section)
            
            if row == count {
                return ip
            }
            
            let numValue = IMTreeView.get(self).model[ip]!
            
            count += 1
            
            if row < numValue + count {
                return self.treeIndexOfRow(row - count, root: ip, offset: count)
            }
            
            count += numValue
        }
        
        return NSIndexPath()
    }
    
    

    
    // MARK: Private
    
    
    /// Similar to `getRowsToCollapse(_)`
    /// Used when calling `expand(_)`, and returns all children that need to be added to the tableView.
    /// This method is recursive
    /// 
    /// - Returns: An array of index paths which need to be added
    private func getRowsToExpand(indexPath: NSIndexPath) -> [NSIndexPath] {
        var rows = [NSIndexPath]()
        
        let section = indexPath.section
        let count = IMTreeView.get(self).directModel[indexPath]
        
        if count > 0 {
            for var i = 0; i < count; i += 1 {
                rows.appendContentsOf(self.getRowsToExpand(indexPath.indexPathByAddingIndex(i)))
            }
            
            for var i = 0; i < count; i += 1 {
                rows.append(NSIndexPath(forRow: self.rowOffsetForIndexPath(indexPath.indexPathByAddingIndex(i)), inSection: section))
            }
        }
        
        return rows
    }
    
    
    /// Similar to `getRowsToExpand(_)`
    /// Used when calling `collapse(_)`, and returns all children that need to be remvoed from the tableView.
    /// This method is recursive
    ///
    /// - Returns: An array of index paths which need to be removed
    private func getRowsToCollapse(indexPath: NSIndexPath) -> [NSIndexPath] {
        var rows = [NSIndexPath]()
        
        let section = indexPath.section
        let count = IMTreeView.get(self).directModel[indexPath]
        
        if count > 0 {
            for i in 0 ..< count! {
                rows.append(NSIndexPath(forRow: self.rowOffsetForIndexPath(indexPath.indexPathByAddingIndex(i)), inSection: section))
            }
            
            for var i = count! - 1; i >= 0; i -= 1 {
                rows.appendContentsOf(self.getRowsToCollapse(indexPath.indexPathByAddingIndex(i)))
            }
        }
        
        IMTreeView.get(self).model.removeValueForKey(indexPath)
        IMTreeView.get(self).directModel.removeValueForKey(indexPath)
        
        return rows
    }
    
    
    /// Calls the recursive method `rowOffsetForIndexPath(_,_)`, which is defined below.
    /// Begins with the given index path, and the root being an index path with an index of the first index of the given index path.
    private func rowOffsetForIndexPath(indexPath: NSIndexPath) -> Int {
        let section = indexPath.indexAtPosition(0)
        let ip = NSIndexPath(index: section)
        
        return self.rowOffsetForIndexPath(indexPath, root: ip)
    }
    
    
    /// Determines the offset of a given index path, beginning at a given root.
    /// This will represent the location of the n-dimensional index path within the 2D space of the tableView.
    ///
    /// Traverses the indexPath up _recursively_, tallying up all the rows.
    ///
    /// - Parameter indexPath: The index path we are trying to find the offset of
    /// - Parameter root: The root index path that we are finding the distance to
    /// - Returns: An offset (int), which is the distance between the two.
    private func rowOffsetForIndexPath(indexPath: NSIndexPath, root: NSIndexPath) -> Int {
        if indexPath.compare(root) == .OrderedSame {
            return 0
        }
        
        var totalCount = 0
        if root.length > 1 {
            totalCount += 1
        }
        
        var subitemsCount = 0
        if let num = IMTreeView.get(self).directModel[root] {
            subitemsCount = num
        } else if let ds = self.dataSource as? IMTreeViewDataSource {
            if ds.tableView(self, isCellExpandedAtIndexPath: root) {
                subitemsCount = ds.tableView(self, numberOfChildrenForIndexPath: root)
            }
        }
        
        for i in 0 ..< subitemsCount {
            let ip = root.indexPathByAddingIndex(i)
            
            if ip.compare(indexPath) != .OrderedAscending {
                break
            }
            
            totalCount += self.rowOffsetForIndexPath(indexPath, root: ip)
        }
        
        return totalCount
    }
    
    
    /// Determines the indexPath in the tree of a row in the tableView. This is the opposite of `rowOffsetForIndexPath(_,_)`.
    /// This method is called by `treeIndexPathFromTablePath(_)`, and is recursive.
    /// 
    /// - Parameter row:
    /// - Parameter root: The root index path to base it off of
    /// - Parameter offset:
    /// - Returns: An n-dimensional index path that represents the location in the tree.
    private func treeIndexOfRow(row: Int, root: NSIndexPath, offset: Int) -> NSIndexPath {
        var count = 0
        
        var ip: NSIndexPath! = nil
        let num = IMTreeView.get(self).model[root]!
        
        if num == 0 {
            return root
        }
        
        for i in 0 ..< num {
            ip = root.indexPathByAddingIndex(i)
            
            if row == count {
                return ip
            }
            
            let numValue = IMTreeView.get(self).model[ip]!
            
            count += 1
            if row < numValue + count {
                return self.treeIndexOfRow(row - count, root: ip, offset: count)
            }
            
            count += numValue
        }
        
        return ip
    }
    
    
    /// Calculates the number of children, by asking the datasource.
    ///
    /// - Returns the count of the children of the item at the indexpath
    private func numberOfChildren(indexPath: NSIndexPath) -> Int {
        if self.dataSource == nil {
            return 0
        }
        
        var count = 0
        
        var isExpanded = false
        if indexPath.length == 1 {
            isExpanded = true
        } else if let ds = self.dataSource as? IMTreeViewDataSource {
            isExpanded = ds.tableView(self, isCellExpandedAtIndexPath: indexPath)
        }
        
        if isExpanded {
            var subitemsCount = 0
            if let ds = self.dataSource as? IMTreeViewDataSource {
                subitemsCount = ds.tableView(self, numberOfChildrenForIndexPath: indexPath)
            }
            
            for i in  0..<subitemsCount {
                count += self.numberOfChildren(indexPath.indexPathByAddingIndex(i))
            }
            
            count += subitemsCount
            IMTreeView.get(self).directModel[indexPath] = subitemsCount
        }
        
        IMTreeView.get(self).model[indexPath] = count
        return count
    }
    
}