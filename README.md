# IMTreeView

[![CI Status](http://img.shields.io/travis/IMcD23/IMTreeView.svg?style=flat)](https://travis-ci.org/Ian McDowell/IMTreeView)
[![Version](https://img.shields.io/cocoapods/v/IMTreeView.svg?style=flat)](http://cocoapods.org/pods/IMTreeView)
[![License](https://img.shields.io/cocoapods/l/IMTreeView.svg?style=flat)](http://cocoapods.org/pods/IMTreeView)
[![Platform](https://img.shields.io/cocoapods/p/IMTreeView.svg?style=flat)](http://cocoapods.org/pods/IMTreeView)

![screenshot](https://raw.githubusercontent.com/IMcD23/IMTreeView/master/screenshot.png)

IMTreeView is a simple library that allows you to display a tree structure with any UITableView. It is simple, well-tested and documented, and written entirely in Swift.

Take a look at the example project to see it in action!

## Requirements

IMTreeView is written in Swift 2, so it requires Xcode 7.

## Installation

IMTreeView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IMTreeView"
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

1. Add the following import to the top of your source file:

```swift
import IMTreeView
```

2. Add a UITableView to the view controller, either through the storyboard, or in code. Set the tableView's `dataSource` to be the UIViewController.

3. Make the UIViewController implement the `UITableViewDataSource` and `IMTreeViewDataSource` protocols.

4. Implement the required methods as shown:

```swift

// MARK: UITableViewDataSource

func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1  // or however many you would like to
}

func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    // this allows the tableView to function as a tree
    return tableView.numberOfItemsInSection(section)
    
}

func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    // convert the tableView indexPath to a tree-based indexPath
    let treeIndexPath = tableView.treeIndexPathFromTablePath(indexPath)
    
    // retrieve the data to display
    let node = self.nodeAtIndexPath(treeIndexPath)
    
    // to determine indentation
    let level = treeIndexPath.length - 2
    
    // get a cell
    let cell = tableView.dequeueReusableCellWithIdentifier("identifier", forIndexPath: indexPath)
    
    // configure cell
    cell.textLabel?.text = node.title
    cell.indentationLevel = level
    
    return cell
}


// MARK: IMTreeViewDataSource

func tableView(tableView: UITableView, numberOfChildrenForIndexPath indexPath: NSIndexPath) -> Int {
    if indexPath.length == 1 {
        // return the number of root nodes
        return self.nodes.count
    } else {
        // return the number of children of this node
        let node = self.nodeAtIndexPath(indexPath)
        return node.children.count
    }
}

func tableView(tableView: UITableView, isCellExpandedAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true // if supporting collapsing, you should return whether this indexPath is expanded.
}


// MARK: Helpers

func nodeAtIndexPath(indexPath: NSIndexPath) -> Node {
    // see example project for implementation
}

```

## Author

Ian McDowell, mcdow.ian@gmail.com

## License

IMTreeView is available under the MIT license. See the LICENSE file for more info.
