import UIKit
import Slider
import os.log

class ViewController: UIViewController {

    @IBOutlet private var uiSlider: UISlider!
    @IBOutlet private var slider: Slider!
    @IBOutlet private var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        slider.log = OSLog(subsystem: "com.thread.SliderPlayground", category: "slider")
        slider.tintColor = .red
        slider.scaling = .linear(0...100)
        slider.step = 0.5
        slider.addTarget(self, action: #selector(updateLabel), for: .valueChanged)
        updateLabel()
    }

    @objc private func updateLabel() {
        label.text = "\(slider.lowerValue) – \(slider.upperValue)"
    }

}
