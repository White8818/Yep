//
//  FeedCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedCell: FeedBasicCell {

    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!

    var tapMediaAction: ((transitionView: UIView, image: UIImage?, attachments: [DiscoveredAttachment], index: Int) -> Void)?

    var attachments = [DiscoveredAttachment]() {
        didSet {

            let oldHeight = collectionViewHeight.constant
            let newHeight: CGFloat
            if attachments.count == 1 {
                newHeight = 160
            } else {
                newHeight = 80
            }
            if newHeight != oldHeight {
                collectionViewHeight.constant = newHeight
            }

            mediaCollectionView.reloadData()
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    let feedMediaCellID = "FeedMediaCell"

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedCell.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15

        if let attachment = feed.attachment {
            if case let .Images(attachments) = attachment {
                let imageHeight: CGFloat = attachments.count == 1 ? 160 : 80
                height += (imageHeight + 15)
            }
        }

//        if feed.attachment == nil {
//        } else {
//            var imageHeight: CGFloat = 80
//            if feed.attachments.count == 1 {
//                imageHeight = 160
//            }
//            height = ceil(rect.height) + 10 + 40 + 4 + 15 + imageHeight + 15 + 17 + 15
//        }

        return ceil(height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        mediaCollectionView.scrollsToTop = false
        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let backgroundView = TouchClosuresView(frame: mediaCollectionView.bounds)
        backgroundView.touchesBeganAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesBeganAction?(strongSelf)
            }
        }
        backgroundView.touchesEndedAction = { [weak self] in
            if let strongSelf = self {
                if strongSelf.editing {
                    return
                }
                strongSelf.touchesEndedAction?(strongSelf)
            }
        }
        backgroundView.touchesCancelledAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesCancelledAction?(strongSelf)
            }
        }
        mediaCollectionView.backgroundView = backgroundView
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        attachments = []

        messageTextView.text = nil
        messageTextView.attributedText = nil
    }

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        var hasMedia = false

        if let attachment = feed.attachment {
            if case let .Images(attachments) = attachment {
                hasMedia = !attachments.isEmpty

                self.attachments = attachments
            }
        }

        if attachments.count > 1 {
            timeLabelTopConstraint.constant = hasMedia ? (15 + 80 + 15) : 15
        } else {
            timeLabelTopConstraint.constant = hasMedia ? (15 + 160 + 15) : 15
        }

        mediaCollectionView.hidden = hasMedia ? false : true
    }
}

extension FeedCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaCellID, forIndexPath: indexPath) as! FeedMediaCell
        
        if let attachment = attachments[safe: indexPath.item] {

            //println("attachment imageURL: \(imageURL)")
            
            cell.configureWithAttachment(attachment, bigger: (attachments.count == 1))
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        if attachments.count > 1 {
            return CGSize(width: 80, height: 80)

        } else {
            return CGSize(width: 160, height: 160)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionView = cell.imageView
        tapMediaAction?(transitionView: transitionView, image: cell.imageView.image, attachments: attachments, index: indexPath.item)
    }
}

