//
//  ViewController.swift
//  SliderPlayground
//
//  Created by Joseph Duffy on 18/07/2019.
//  Copyright © 2019 Joseph Duffy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private var uiSlider: UISlider!
    @IBOutlet private var slider: Slider!

    override func viewDidLoad() {
        super.viewDidLoad()

        slider.backgroundColor = .red
//        uiSlider.setThumbImage(#imageLiteral(resourceName: "thumb"), for: .normal)
    }


}

open class ThumbImageView: UIImageView {

    public override init(image: UIImage?) {
        super.init(image: image)

        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.masksToBounds = false

        clipsToBounds = false

        contentMode = .center
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

//@IBDesignable 
open class Slider: UIControl {

    open var minimumTrackTintColor: UIColor? {
        get {
            return minimumTrackView.tintColor
        }
        set {
            minimumTrackView.tintColor = newValue
        }
    }

    @IBInspectable
    open var lowerValue: Float = 0.25

    @IBInspectable
    open var upperValue: Float = 0.75

    @IBInspectable
    open var minimumValue: Float = 0

    @IBInspectable
    open var maximumValue: Float = 1

    /// A number in the range 0...100
    open var lowerValueAsPercentage: Float {
        let range = maximumValue - minimumValue
        return (lowerValue - minimumValue) / range
    }

    /// A number in the range 0...100
    open var upperValueAsPercentage: Float {
        let range = maximumValue - minimumValue
        return (upperValue - minimumValue) / range
    }

    open var minimumThumbDistance: CGFloat {
        return currentThumbImage.size.width
    }

    open var minimumValueDistance: Float {
        return valueChangePerPoint * Float(lowerThumbView.bounds.width)
    }

    private var valueChangePerPoint: Float {
        let range = maximumValue - minimumValue
        return range/Float(thumbTrackBoundingRect.width)
    }

    private let minimumTrackView = UIImageView(image: nil)
    private let maximumTrackView = UIImageView(image: nil)
    private let lowerThumbView = ThumbImageView(image: nil)
    private let upperThumbView = ThumbImageView(image: nil)

    public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviews()
        copyStyle(of: UISlider())
    }

    public required init(styledAfter slider: UISlider, frame: CGRect) {
        super.init(frame: frame)

        addSubviews()
        copyStyle(of: slider)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        addSubviews()
        copyStyle(of: UISlider())
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let backgroundTrackRect = trackRect(forBounds: bounds)
        minimumTrackView.frame = backgroundTrackRect
        maximumTrackView.frame = backgroundTrackRect
        layoutThumbView()
    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 31
        size.width += 4
        return size
    }

    private var thumbTrackBoundingRect: CGRect {
        let visualWidth = bounds.width - (lowerThumbView.bounds.width / 2)
        let trackWidth = minimumTrackView.bounds.width
        let availableWidth = min(visualWidth, trackWidth)
        let widthDifference = bounds.width - availableWidth
        assert(widthDifference >= 0, "Thumb track bounding rect should never be greater than the bounds")
        return bounds.insetBy(dx: widthDifference, dy: 0)
    }

    private var thumbImageSize: CGSize {
        return CGSize(width: 31, height: 31)
    }

    private func layoutThumbView() {
        lowerThumbView.frame.size = thumbImageSize
        upperThumbView.frame.size = thumbImageSize

        position(thumb: lowerThumbView, percent: CGFloat(lowerValueAsPercentage))
        position(thumb: upperThumbView, percent: CGFloat(upperValueAsPercentage))

//        let lowerThumbX = thumbTrackBoundingRect.width * CGFloat(lowerValueAsPercentage)
//        lowerThumbView.center = CGPoint(x: lowerThumbX, y: minimumTrackView.frame.midY)
//        let upperThumbX = thumbTrackBoundingRect.width * CGFloat(upperValueAsPercentage)
//        upperThumbView.center = CGPoint(x: upperThumbX, y: minimumTrackView.frame.midY)
    }

    private func position(thumb: UIImageView, percent: CGFloat) {
        print("-----")
        print("percent", percent)
        let trackWidth = thumbTrackBoundingRect.width
        print("trackWidth", trackWidth)
        let xOffset = trackWidth * percent
        print("xOffset", xOffset)
        print("minimumTrackView.frame.minX", thumbTrackBoundingRect.minX)
        let midX = thumbTrackBoundingRect.minX + xOffset
        print("midX", midX)
        thumb.center = CGPoint(x: midX, y: minimumTrackView.frame.midY)
    }

    private func addSubviews() {
        updateThumbImages()
        updateMinimumTrackImage()

        addSubview(minimumTrackView)
        addSubview(maximumTrackView)
        addSubview(lowerThumbView)
        addSubview(upperThumbView)
        minimumTrackView.tintColor = tintColor
        maximumTrackView.tintColor = .gray
//        lowerThumbView.contentMode = .
        lowerThumbView.isUserInteractionEnabled = true
        upperThumbView.isUserInteractionEnabled = true

        let lowerGesture = UIPanGestureRecognizer(target: self, action: #selector(lowerThumbViewGesture))
        lowerThumbView.addGestureRecognizer(lowerGesture)

        let upperGesture = UIPanGestureRecognizer(target: self, action: #selector(upperThumbViewGesture))
        upperThumbView.addGestureRecognizer(upperGesture)
    }

    @objc private func lowerThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &lowerValue, allowedRange: minimumValue...(upperValue - minimumValueDistance))
    }

    @objc private func upperThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &upperValue, allowedRange: (lowerValue + minimumValueDistance)...maximumValue)
    }

    private func handleGesture(recognizer: UIPanGestureRecognizer, value: inout Float, allowedRange: ClosedRange<Float>) {
        switch recognizer.state {
        case .changed, .ended:
            let point = recognizer.translation(in: self)
            value += Float(point.x) * valueChangePerPoint
            if value > allowedRange.upperBound {
                value = allowedRange.upperBound
            } else if value < allowedRange.lowerBound {
                value = allowedRange.lowerBound
            }
            recognizer.setTranslation(.zero, in: self)
            setNeedsLayout()
        case .cancelled:
            // TODO: Reset to start
            break
        case .began, .possible, .failed:
            break
        @unknown default:
            break
        }
    }

    open func copyStyle(of slider: UISlider) {
        tintColor = slider.tintColor
    }

    func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbImages[state.rawValue] = image

        if self.state == state {
            updateThumbImages()
        }
    }

    private(set) lazy var currentThumbImage: UIImage = Slider.defaultThumbImage()
    private(set) lazy var currentMinimumTrackImage: UIImage = Slider.defaultMinimumValueImage()

    open func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect = rect.insetBy(dx: 2, dy: 0)
        rect.origin.y = bounds.midY.rounded(.down)
        rect.size.height = currentMinimumTrackImage.size.height
        return rect
    }

    open override var isHighlighted: Bool {
        didSet {
            updateThumbImages()
        }
    }

    private var thumbImages: [UIControl.State.RawValue: UIImage] = [:]

    private func updateThumbImages() {
        currentThumbImage = thumbImages[state.rawValue] ?? Slider.defaultThumbImage()
        lowerThumbView.image = currentThumbImage
        upperThumbView.image = currentThumbImage
    }

    private func updateMinimumTrackImage() {
        minimumTrackView.image = currentMinimumTrackImage
        setNeedsLayout()
    }

}

extension Slider {

    internal static func defaultMinimumValueImage() -> UIImage {
        return UIImage(named: "minimumSliderImage")!
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 4), format: format)
        let image =  renderer.image { context in
            context.fill(CGRect(x: 0, y: 0, width: 6, height: 4))

            UIColor.black.setFill()
            context.fill(CGRect(x: 3, y: 0, width: 3, height: 4))
            context.fill(CGRect(x: 1, y: 1, width: 2, height: 2))

            UIColor.black.withAlphaComponent(0.329412).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            context.fill(CGRect(x: 0, y: 3, width: 1, height: 1))

            UIColor.black.withAlphaComponent(0.890196).setFill()
            context.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
            context.fill(CGRect(x: 1, y: 3, width: 1, height: 1))

            UIColor.black.withAlphaComponent(0.996078).setFill()
            context.fill(CGRect(x: 2, y: 0, width: 1, height: 1))
            context.fill(CGRect(x: 2, y: 3, width: 1, height: 1))

            UIColor.black.withAlphaComponent(0.921569).setFill()
            context.fill(CGRect(x: 0, y: 1, width: 1, height: 1))
            context.fill(CGRect(x: 0, y: 2, width: 1, height: 1))
        }

        print(image.pngData()!.base64EncodedString())

        return image.stretchableImage(withLeftCapWidth: 2, topCapHeight: 1).withRenderingMode(.alwaysTemplate)
    }

    internal static func defaultMaximumValueImage() -> UIImage {
        return UIImage(named: "maximumSliderImage")!
    }

    internal static func defaultThumbImage() -> UIImage {
        return UIImage(named: "thumb")!
        //        let format = UIGraphicsImageRendererFormat()
        //        format.scale = 1
        //        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 114, height: 87), format: format)
        //
        //        let insets = UIEdgeInsets(top: 15, left: 29, bottom: 16, right: 29)
        //        let innerSquareSize = CGSize(width: 38, height: 40)
    }

}

