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
        slider.scaling = .stepped([
            0...50: 0...100,
            50...75: 100...200,
            75...90: 200...500,
            90...100: 500...1000,
        ])
        slider.step = 5
        slider.addTarget(self, action: #selector(updateLabel), for: .valueChanged)
        updateLabel()
    }

    @objc private func updateLabel() {
        label.text = "\(slider.lowerValue) – \(slider.upperValue)"
    }

}
