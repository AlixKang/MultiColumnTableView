//
//  MultiColumnTableView.swift
//  MultiColumnTableView
//
//  Created by Alix.Kang on 6/27/16.
//  Copyright © 2016 Alix.Kang. All rights reserved.
//

import UIKit

// MARK: 表格视图
/*
 
 @note 视图排列结构
    | 左上角标题 |  上标题1 -  上标题2 - 上标题... |
    ------------------------------------------------
    | 左标题1   |   C0R0      | C1R0      | CxR0...  |
    | 左标题2   |   C0R1      | C1R1      | CxR1...  |
    | 左标题3   |   C0R2      | C1R2      | CxR2...  |
    | 左标题... |   C0R...    | C1R...    | CxR...   |

 * @note
    * 左上角标题是UILabel对象
    * 上面标题是UIScrollView上面放的是UILabels
    * 左标题是UITableView, Cell是UILabel
    * 右边CxRx 底层是UIScrollView, 对应每一列是UITableView, Cell是UILabel
 
 * @note
    * 在Reload之前, 会找出上标题和下方共几个Cx最大值, 即最大列数
    * 在Reload之前, 会找出左标题和右方Cx最大行数, 即tableView最大行数
    * 在Reload之时, 如果内容小于上方的最大值, 则用 `invalidDataDescription`填充显示内容
 */
class MultiColumnView : UIView, UITableViewDataSource, UITableViewDelegate {
    
    private var leftTopTitle : String?
    private var leftTitles : [String]?
    private var leftTitleWidth : CGFloat!
    
    private var topTitles : [String]?
    private var topTitleRowHeight : CGFloat!
    
    private var rowHeight : CGFloat!
    private var columnWidth : CGFloat!
 
    private var invalidDataDescription : String?
    private var invalidDataColor : UIColor!
    
    private var mainData : [[String]]?
    
    private var titleBorderColor : UIColor!
    private var titleBorderWidth : CGFloat!
    
    private var borderColor : UIColor!
    private var borderWidth : CGFloat!
    
    private var titleFont : UIFont!
    private var mainDataFont : UIFont!
    
    private var titleColor : UIColor!
    private var mainDataColor : UIColor!
    
    private var leftTitleLabel : DataLabel?
    private var leftTitlesTableView : UITableView?
    private var topScrollView : UIScrollView?
    private var mainContentScrollView : UIScrollView?
    
    
    // scrollView判断滑动方向
    private var lastContentOffset : CGPoint?
    
    // 最多的行数和列数, 为了保证表格整齐
    private var maxRowCount = 0
    private var maxColumnCount = 0
    
    var datasource : MultiColumnViewDatasource? {
        didSet {
            reloadData()
        }
    }
    
    /*!
     刷新表格
     */
    func reloadData() {
        // 移除所有视图
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        leftTitleLabel = nil
        leftTitlesTableView = nil
        topScrollView = nil
        mainContentScrollView = nil

        guard datasource != nil else {
            return
        }
        
        leftTopTitle = datasource!.leftTopTitle(self)
        leftTitles = datasource!.leftTitles(self)
        leftTitleWidth = datasource!.leftTitleWidth(self)
        
        topTitles = datasource!.topTitles(self)
        topTitleRowHeight = datasource!.topTitleRowHeight(self)
        
        rowHeight = datasource!.rowHeight(self)
        columnWidth = datasource!.columnWidth(self)
        
        invalidDataDescription = datasource!.invalidDataDescription(self)
        invalidDataColor = datasource!.invalidDataColor(self)
        mainData = datasource!.mainData(self)
        
        titleBorderColor = datasource!.titleBorderColor(self)
        titleBorderWidth = datasource!.titleBorderWidth(self)
        
        borderColor = datasource!.borderColor(self)
        borderWidth = datasource!.borderWidth(self)
        
        titleFont = datasource!.titleFont(self)
        mainDataFont = datasource!.mainDataFont(self)
        
        // 右边有多少TableView
        maxColumnCount = 0
        maxColumnCount = topTitles?.count ?? maxColumnCount
        let mainDataCount = mainData?.count ?? maxColumnCount
        maxColumnCount = max(mainDataCount, maxColumnCount)
        
        // TableView返回多少行
        maxRowCount = 0
        maxRowCount = leftTitles?.count ?? maxRowCount
        if mainData != nil  {
            for dataItem in mainData! {
                maxRowCount = max(maxRowCount, dataItem.count)
            }
        }
        
        
        // 更新左/左上角标题
        updateLeft()
        
        // 更新上方标题
        updateTop()
        
        // 更新主要内容
        updateMainContent()
        
        layoutIfNeeded()
    }
    
    private func updateLeft() {
        // 左上角标题
        if leftTopTitle != nil {
            leftTitleLabel = DataLabel(frame : CGRect(x: 0, y: 0, width: leftTitleWidth, height: topTitleRowHeight))
            addSubview(leftTitleLabel!)
            leftTitleLabel?.textAlignment = .Center
            leftTitleLabel?.font = titleFont
            leftTitleLabel?.textColor = titleColor
            leftTitleLabel?.text = leftTopTitle
            leftTitleLabel?.userInteractionEnabled = true
            leftTitleLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MultiColumnView.leftTopLabelTapped)))
            leftTitleLabel?.layer.borderColor = titleBorderColor.CGColor
            leftTitleLabel?.layer.borderWidth = titleBorderWidth
        }
        
        // 左边标题
        if leftTitles?.count > 0 {
            leftTitlesTableView = UITableView(frame: CGRect(x: 0, y: topTitleRowHeight, width: leftTitleWidth, height: CGFloat(leftTitles!.count) * rowHeight), style: .Plain)
            leftTitlesTableView!.dataSource = self
            leftTitlesTableView!.delegate = self
            leftTitlesTableView?.showsVerticalScrollIndicator = false
            leftTitlesTableView?.showsHorizontalScrollIndicator = false
            leftTitlesTableView?.scrollsToTop = false
            leftTitlesTableView?.separatorStyle = .None
            leftTitlesTableView?.alwaysBounceVertical = false
            leftTitlesTableView?.alwaysBounceHorizontal = false
            addSubview(leftTitlesTableView!)
        }
    }
    
    private func updateTop() {
        topScrollView = UIScrollView(frame: CGRect(x:leftTitleWidth, y:0, width: bounds.width - leftTitleWidth, height: topTitleRowHeight))
        addSubview(topScrollView!)
        topScrollView?.delegate = self
        topScrollView?.showsVerticalScrollIndicator = false
        topScrollView?.showsHorizontalScrollIndicator = false
        topScrollView?.scrollsToTop = false
        topScrollView?.alwaysBounceHorizontal = false
        topScrollView?.alwaysBounceVertical = false
        
        let topCount = topTitles?.count ?? 0
        for i in 0..<maxColumnCount {
            let label = DataLabel(frame: CGRect(x: CGFloat(i) * columnWidth, y: 0, width: columnWidth, height: topTitleRowHeight))
            label.tag = i
            label.textAlignment = .Center
            label.font = titleFont
            label.textColor = titleColor
            label.text =  topCount > i ? topTitles?[i] : "";
            topScrollView?.addSubview(label)
            label.layer.borderWidth = titleBorderWidth
            label.layer.borderColor = titleBorderColor.CGColor
            label.backgroundColor = datasource?.columnBackgroundColor(self, column: i) ?? UIColor.clearColor()
        }
        topScrollView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MultiColumnView.topTitleTapped)))
        topScrollView?.contentSize = CGSize(width: CGFloat(maxColumnCount) * columnWidth, height: topTitleRowHeight)
        
    }
    
    private func updateMainContent() {
        mainContentScrollView = UIScrollView(frame: CGRect(x: leftTitleWidth, y: topTitleRowHeight, width: bounds.width-leftTitleWidth, height: bounds.height - topTitleRowHeight))
        mainContentScrollView?.showsHorizontalScrollIndicator = false
        mainContentScrollView?.showsVerticalScrollIndicator = false
        addSubview(mainContentScrollView!)
        mainContentScrollView?.scrollsToTop = false
        mainContentScrollView?.delegate = self
        mainContentScrollView?.alwaysBounceVertical = false
        mainContentScrollView?.alwaysBounceHorizontal = false
        
        let size = CGSize(width: columnWidth, height: CGFloat(maxRowCount) * rowHeight)
        for i in 0..<maxColumnCount {
            let tv = UITableView(frame: CGRect(origin: CGPoint(x: CGFloat(i)*columnWidth, y: 0), size:size), style: .Plain)
            tv.scrollsToTop = false
            tv.dataSource = self
            tv.delegate = self
            tv.scrollEnabled = false
            tv.showsVerticalScrollIndicator = false
            tv.showsHorizontalScrollIndicator = false
            mainContentScrollView?.addSubview(tv)
            tv.tag = i
            tv.separatorStyle = .None
        }
        mainContentScrollView?.contentSize = CGSize(width: columnWidth * CGFloat(maxColumnCount), height: size.height)
    }
    
    @objc private func topTitleTapped(gesture : UIGestureRecognizer) {
        let locationX = gesture.locationInView(topScrollView).x + 0.1
        let index = locationX / columnWidth
        datasource?.topTitleSelected(self, index: Int(index))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // leftTop
        var leftTitleFrame = leftTitleLabel?.frame
        leftTitleFrame?.origin = CGPointZero
        leftTitleFrame?.size = CGSize(width: leftTitleWidth, height: topTitleRowHeight)
        leftTitleLabel?.frame = leftTitleFrame ?? CGRectZero
        
        // left titles
        var leftTableFrame = leftTitlesTableView?.frame
        leftTableFrame?.origin = CGPoint(x: 0, y: topTitleRowHeight)
        leftTableFrame?.size = CGSize(width: leftTitleWidth, height: bounds.height - topTitleRowHeight)
        leftTitlesTableView?.frame = leftTableFrame ?? CGRectZero
    }
    
    @objc private func leftTopLabelTapped(gesture : UIGestureRecognizer) {
        datasource?.leftTopTitleSelected(self)
    }
    
    
    // MARK: - TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return maxRowCount
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(ContentCell.CellReuseID) as? ContentCell
        if nil == cell {
            cell = ContentCell(style: .Default, reuseIdentifier: ContentCell.CellReuseID)
        }
        cell?.dataLabel.font = tableView == leftTitlesTableView ? titleFont : mainDataFont
        cell?.dataLabel.textColor = tableView == leftTitlesTableView ? titleColor : mainDataColor
        var title : String?
        if tableView == leftTitlesTableView {
            title = (leftTitles?.count ?? 0) > indexPath.row ? leftTitles?[indexPath.row] : nil
            cell?.contentView.layer.borderColor = titleBorderColor.CGColor
            cell?.contentView.layer.borderWidth = titleBorderWidth
        } else {
            cell?.contentView.layer.borderWidth = borderWidth
            cell?.contentView.layer.borderColor = borderColor.CGColor
            let tag = tableView.tag
            if mainData?.count > tag {
                let dataItem = mainData?[tag]
                title = (dataItem?.count ?? 0) > indexPath.row ? dataItem![indexPath.row] : nil
            } else {
                title = nil
            }
            cell?.contentView.backgroundColor = datasource?.columnBackgroundColor(self, column: tableView.tag) ?? UIColor.clearColor()
        }
        if title == nil {
            cell?.dataLabel.textColor = invalidDataColor
            title = invalidDataDescription
        }
        cell?.setTitle(title)
        cell?.selectionStyle = .None

        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == leftTitlesTableView {
            datasource?.leftTitleSelected(self, index: indexPath.row)
        } else {
            datasource?.selected(self, row: indexPath.row, column: tableView.tag)
        }
    }
    
    
    // MARK: - ScrollView
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if scrollView == mainContentScrollView {
            lastContentOffset = scrollView.contentOffset
        } else {
            lastContentOffset = nil
        }
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset
        if scrollView == leftTitlesTableView  && lastContentOffset == nil {
            if mainContentScrollView?.contentOffset.y != contentOffset.y {
                mainContentScrollView?.contentOffset = CGPoint(x: mainContentScrollView?.contentOffset.x ?? 0, y: contentOffset.y)
            }
        } else if scrollView == mainContentScrollView && lastContentOffset != nil {
            // 判断是左右还是上下
            let deltaX = fabs(contentOffset.x - lastContentOffset!.x)
            let deltaY = fabs(contentOffset.y - lastContentOffset!.y)
            if deltaX > deltaY {
                // 左右滑
                mainContentScrollView?.contentOffset = CGPoint(x: contentOffset.x, y: lastContentOffset!.y)
                leftTitlesTableView?.contentOffset = CGPoint(x: leftTitlesTableView?.contentOffset.x ?? 0, y: lastContentOffset!.y)
                if topScrollView?.contentOffset.x != contentOffset.x {
                    topScrollView?.contentOffset = CGPoint(x: contentOffset.x, y: topScrollView?.contentOffset.y ?? 0)
                }
            } else {
                // 上下滑
                mainContentScrollView?.contentOffset = CGPoint(x: lastContentOffset!.x, y: contentOffset.y)
                topScrollView?.contentOffset = CGPoint(x: lastContentOffset!.x, y: topScrollView?.contentOffset.y ?? 0)
                if leftTitlesTableView?.contentOffset.y != contentOffset.y {
                    leftTitlesTableView?.contentOffset = CGPoint(x: leftTitlesTableView?.contentOffset.x ?? 0, y: contentOffset.y)
                }
            }
        } else if scrollView == topScrollView && lastContentOffset == nil {
            if mainContentScrollView?.contentOffset.x != contentOffset.x {
                mainContentScrollView?.contentOffset = CGPoint(x: contentOffset.x, y: mainContentScrollView?.contentOffset.y ?? 0)
            }
        }
    }
    
    // MARK: - 私有类
    private class ContentCell : UITableViewCell {
        static let CellReuseID = "ContentCell"
        var dataLabel = DataLabel()
        
        func setTitle(title : String?) {
            dataLabel.text = title
            layoutIfNeeded()
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(dataLabel)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            contentView.addSubview(dataLabel)
        }
        
        private override func layoutSubviews() {
            super.layoutSubviews()
            dataLabel.sizeToFit()
            dataLabel.center = CGPoint(x: contentView.frame.width * 0.5, y: contentView.frame.height * 0.5)
        }
    }
    
    
    /*!
     扩展UILabel, 决定UILabel在垂直方向的位置
     */
    private class DataLabel : UILabel {
        enum VAlignment {
            case Top, Center, Bottom
        }
        
        var vAlignment = VAlignment.Center {
            didSet {
                if oldValue != vAlignment {
                    setNeedsDisplay()
                }
            }
        }
        
        private override var text: String? {
            didSet {
                setNeedsDisplay()
            }
        }
        override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            var rect = super.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines)
            switch vAlignment {
            case .Top:
                rect.origin.y = bounds.origin.y;
            case .Center:
                rect.origin.y = bounds.origin.y + (bounds.height - rect.height) / 2
            default:
                rect.origin.y = bounds.origin.y + bounds.height - rect.height
            }
            return rect
        }
        
        override func drawTextInRect(rect: CGRect) {
            super.drawTextInRect(textRectForBounds(rect, limitedToNumberOfLines: numberOfLines))
        }
    }
    
}

protocol MultiColumnViewDatasource : NSObjectProtocol {
    // 左上角标题
    func leftTopTitle(mvc : MultiColumnView) -> String?
    
    // 左边标题
    func leftTitles(mvc : MultiColumnView) -> [String]?
    
    // 左边标题宽度
    func leftTitleWidth(mvc : MultiColumnView) -> CGFloat
    
    // 上方标题
    func topTitles(mvc : MultiColumnView) -> [String]?
    
    // 上方标题高度
    func topTitleRowHeight(mvc : MultiColumnView) -> CGFloat
    
    // 单行高度
    func rowHeight(mvc : MultiColumnView) -> CGFloat
    
    // 单列宽度
    func columnWidth(mvc : MultiColumnView) -> CGFloat
    
    // 无数据时显示字符, 默认是 '---'
    func invalidDataDescription(mvc : MultiColumnView) -> String?
    func invalidDataColor(mvc : MultiColumnView) -> UIColor
    
    // 表格主要数据
    func mainData(mvc : MultiColumnView) -> [[String]]?
    
    // MARK : - 颜色配置
    // 标题边框
    func titleBorderColor(mvc : MultiColumnView) -> UIColor
    func titleBorderWidth(mvc : MultiColumnView) -> CGFloat
    
    // 内容边框
    func borderColor(mvc : MultiColumnView) -> UIColor
    func borderWidth(mvc : MultiColumnView) -> CGFloat
    
    // 字体
    func titleFont(mvc : MultiColumnView) -> UIFont
    func mainDataFont(mvc : MultiColumnView) -> UIFont
    
    // 字色
    func titleColor(mvc : MultiColumnView) -> UIColor
    func mainDataColor(mvc : MultiColumnView) -> UIColor
    
    // 数据列背景颜色
    func columnBackgroundColor(mvc : MultiColumnView, column : Int) -> UIColor?

    
    // 选中后事件 
    // 左边标题选中后事件
    func leftTitleSelected(mvc : MultiColumnView, index : Int) -> Void
    // 上边标题选中后事件
    func topTitleSelected(mvc : MultiColumnView, index : Int) -> Void
    // 左上角标题点击事件
    func leftTopTitleSelected(mvc : MultiColumnView) -> Void
    
    // 内容选中后事件
    func selected(mvc : MultiColumnView, row : Int, column : Int) -> Void
    
    
}

extension MultiColumnViewDatasource {
    
    // 左边标题宽度
    func leftTitleWidth(mvc : MultiColumnView) -> CGFloat {
        return 100
    }
    
    
    // 上方标题高度
    func topTitleRowHeight(mvc : MultiColumnView) -> CGFloat {
        return 50
    }
    
    // 单行高度
    func rowHeight(mvc : MultiColumnView) -> CGFloat {
        return 44
    }
    
    // 单列宽度
    func columnWidth(mvc : MultiColumnView) -> CGFloat {
        return 90
    }
    
    // 无数据时显示字符, 默认是 '---'
    func invalidDataDescription(mvc : MultiColumnView) -> String? {
        return "---"
    }
    
    func invalidDataColor(mvc : MultiColumnView) -> UIColor {
        return UIColor.greenColor()
    }
    
    
    // MARK : - 颜色配置
    // 标题边框
    func titleBorderColor(mvc : MultiColumnView) -> UIColor {
        return UIColor.blackColor()
    }
    func titleBorderWidth(mvc : MultiColumnView) -> CGFloat {
        return 1
    }
    
    // 内容边框
    func borderColor(mvc : MultiColumnView) -> UIColor {
        return UIColor.lightGrayColor()
    }
    func borderWidth(mvc : MultiColumnView) -> CGFloat {
        return 0.5
    }
    
    // 字体
    func titleFont(mvc : MultiColumnView) -> UIFont {
        return UIFont.boldSystemFontOfSize(13)
    }
    func mainDataFont(mvc : MultiColumnView) -> UIFont {
        return UIFont.systemFontOfSize(10)
    }
    
    // 字色
    func titleColor(mvc : MultiColumnView) -> UIColor {
        return UIColor.blackColor()
    }
    func mainDataColor(mvc : MultiColumnView) -> UIColor {
        return UIColor.lightGrayColor()
    }
    
    // 数据列背景颜色
    func columnBackgroundColor(mvc : MultiColumnView, column : Int) -> UIColor? {
        return column % 2 == 0 ? UIColor(red: 0xAA/255.0, green: 0xAA/255.0, blue: 0xAA/255.0, alpha: 0x33/255.0) : nil
    }
    
    // 选中后事件
    // 左边标题选中后事件
    func leftTitleSelected(mvc : MultiColumnView, index : Int) -> Void { print("左边标题被点击, 可以理解为选中某行" + " " + String(index))}
    // 上边标题选中后事件
    func topTitleSelected(mvc : MultiColumnView, index : Int) -> Void { print("上边标题被点击, 可以理解为选中某列" + " " + String(index))}
    // 左上角标题点击事件
    func leftTopTitleSelected(mvc : MultiColumnView) -> Void { print("左上角标题被点击, 可以理解为选中了整张表")}
    
    // 内容选中后事件
    func selected(mvc : MultiColumnView, row : Int, column : Int) -> Void { print("右下内容区某行某列被点击, 可以理解为选中了具体某个数据" + "C" + String(column) + "R" + String(row)) }

}


