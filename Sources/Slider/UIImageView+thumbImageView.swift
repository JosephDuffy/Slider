import UIKit

extension UIImageView {

    internal static func thumbImageView(image: UIImage?) -> Self {
        let imageView = self.init(image: image)
        imageView.layer.shadowColor = UIColor.gray.cgColor
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOpacity = 0
        imageView.layer.shadowOffset = CGSize(width: 0, height: -3)
        imageView.layer.masksToBounds = false

        imageView.clipsToBounds = false

        imageView.contentMode = .center

        return imageView
    }

}
