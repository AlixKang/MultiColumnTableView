//
//  ViewController.swift
//  MultiColumnTableView
//
//  Created by Alix.Kang on 6/27/16.
//  Copyright © 2016 Alix.Kang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MultiColumnViewDatasource {

    override func viewDidLoad() {
        super.viewDidLoad()
        let columnView = MultiColumnView(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: view.bounds.height))
        columnView.datasource = self
        view.addSubview(columnView)
    }
    
    func leftTopTitle(mvc: MultiColumnView) -> String? {
        return "hahaha"
    }
    
    func leftTitles(mvc: MultiColumnView) -> [String]? {
        var array = [String]()
        for i in 0..<8 {
            array.append(String(i))
        }
        return array
    }
    
    func topTitles(mvc: MultiColumnView) -> [String]? {
        var array = [String]()
        for i in 0..<21 {
            array.append(String(i))
        }
        return array
    }
    
    func mainData(mvc: MultiColumnView) -> [[String]]? {
        var array = [[String]]()
        for i in 0..<20 {
            var a1 = [String]()
            for j in 0..<80 {
                a1.append(String(i*j))
            }
            array.append(a1)
        }
        return array
    }
}

