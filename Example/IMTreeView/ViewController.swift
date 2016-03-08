//
//  ViewController.swift
//  IMTreeView
//
//  Created by Ian McDowell on 03/08/2016.
//  Copyright (c) 2016 Ian McDowell. All rights reserved.
//

import UIKit
import IMTreeView

private struct Node {
    var title = ""
    var children = [Node]()
}

class ViewController: UIViewController, UITableViewDataSource, IMTreeViewDataSource {
    
    private var tableView: UITableView!
    
    private var nodes = [Node]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView = {
            let t = UITableView()
            
            t.registerClass(UITableViewCell.self, forCellReuseIdentifier: "identifier")
            
            t.dataSource = self
            
            self.view.addSubview(t)
            
            t.translatesAutoresizingMaskIntoConstraints = false
            t.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor).active = true
            t.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor).active = true
            t.topAnchor.constraintEqualToAnchor(self.view.topAnchor).active = true
            t.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor).active = true
            
            return t
        }()
        
        self.nodes = [
            Node(title: "Row 0", children: []),
            Node(title: "Row 1", children: [
                Node(title: "Row 1.0", children: [
                    Node(title: "Row 1.0.0", children: [])
                ])
            ]),
            Node(title: "Row 2", children: []),
            Node(title: "Row 3", children: [
                Node(title: "Row 3.0", children: [
                    Node(title: "Row 3.0.0", children: [
                        Node(title: "Row 3.0.0.0", children: [])
                    ]),
                    Node(title: "Row 3.0.1", children: [])
                ]),
                Node(title: "Row 3.1", children: []),
                Node(title: "Row 3.2", children: [])
            ]),
            Node(title: "Row 4", children: [
                Node(title: "Row 4.0", children: []),
                Node(title: "Row 4.1", children: []),
                Node(title: "Row 4.2", children: []),
                Node(title: "Row 4.3", children: [])
            ]),
            Node(title: "Row 5", children: [])
        ]
    }

    
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
    
    private func nodeAtIndexPath(indexPath: NSIndexPath) -> Node {
        var node = self.nodes[indexPath.indexAtPosition(0)]
        var nodes = self.nodes
        
        for i in 1 ..< indexPath.length {
            let index = indexPath.indexAtPosition(i)
            
            node = nodes[index]
            
            if indexPath.length - 1 == i {
                return node
            }
            
            nodes = node.children
        }
        
        return node
    }

}

