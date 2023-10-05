//
//  Created by Diney Bomfim on 5/22/23.
//

import UIKit
import Fusion

// MARK: - Definitions -

extension UIView {

// MARK: - Properties
	
	@IBInspectable var cornerRadius: CGFloat {
		get { layer.cornerRadius }
		set {
			layer.cornerRadius = newValue
			layer.masksToBounds = newValue > 0.0
		}
	}
	
	@IBInspectable var borderWidth: CGFloat {
		get { layer.borderWidth }
		set { layer.borderWidth = newValue }
	}

	@IBInspectable var borderColor: UIColor? {
		get { .init(cgColor: layer.borderColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 0)) }
		set { layer.borderColor = newValue?.cgResolved() }
	}
}

// MARK: - Type -

class TweenSampleCell : UICollectionViewCell {
	
	private lazy var lineLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = UIColor.clear.cgResolved()
		layer.lineWidth = 2.0
		layer.lineDashPattern = [2, 2]
		return layer
	}()
	
	private lazy var circle: UIView = {
		let view = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
		view.backgroundColor = UIColor.red
		view.cornerRadius = 5.0
		return view
	}()
	
	@IBOutlet weak var colorNameLabel: UILabel!
	@IBOutlet weak var colorView: UIView!
	
	private func drawContent(with tween: Ease) {
		let margin: Double = 20
		let padding = margin * 2
		let range = (0...60)
		let path = UIBezierPath()

		range.forEach {
			let value = Double($0)
			let posX = margin + (value / Double(range.upperBound)) * (bounds.width - padding)
			let posY = bounds.height - tween.calculate(margin, bounds.height - padding, value, Double(range.upperBound))
			
			if $0 == 0 {
				path.move(to: CGPoint(x: posX, y: posY))
			} else {
				path.addLine(to: CGPoint(x: posX, y: posY))
			}
		}
		
		lineLayer.path = path.cgPath
		
		let optionsX = TweenOption(repetition: .mirrorValuesAndEase, repetitionDelay: 0.5)
		let optionsY = TweenOption(ease: tween, repetition: .mirrorValuesAndEase, repetitionDelay: 0.5)
		
		Tween.stopTweens(withTarget: circle)
		Tween(target: circle, duration: 1, options: optionsX, fromValues: [\.center.x : margin], toValues: [\.center.x : bounds.width - margin])
		Tween(target: circle, duration: 1, options: optionsY, fromValues: [\.center.y : bounds.height - margin], toValues: [\.center.y : margin])
	}
	
	func configure(with tween: Ease) {
		backgroundColor = .clear
		contentView.layer.addSublayer(lineLayer)
		contentView.addSubview(circle)
		
		colorView.backgroundColor = .lightGray.withAlphaComponent(0.25)
		colorNameLabel.text = tween.name
		cornerRadius = 10
		borderWidth = 0.5
		borderColor = .lightGray

		drawContent(with: tween)
		updateColors()
	}
	
	fileprivate func updateColors() {
		lineLayer.strokeColor = UIColor.label.withAlphaComponent(0.5).cgResolved()
	}
}

extension Ease {
	
	var name: String {
		switch self {
		case .linear:
			return "linear"
		case .smoothOut:
			return "smoothOut"
		case .smoothIn:
			return "smoothIn"
		case .smoothInOut:
			return "smoothInOut"
		case .strongOut:
			return "strongOut"
		case .strongIn:
			return "strongIn"
		case .strongInOut:
			return "strongInOut"
		case .elasticOut:
			return "elasticOut"
		case .elasticIn:
			return "elasticIn"
		case .elasticInOut:
			return "elasticInOut"
		case .bounceOut:
			return "bounceOut"
		case .bounceIn:
			return "bounceIn"
		case .bounceInOut:
			return "bounceInOut"
		case .backOut:
			return "backOut"
		case .backIn:
			return "backIn"
		case .backInOut:
			return "backInOut"
		case .custom(_):
			return "custom"
		}
	}
}

class TweenViewController: UICollectionViewController {

// MARK: - Properties

// MARK: - Constructors

// MARK: - Protected Methods

// MARK: - Exposed Methods

// MARK: - Overridden Methods

	override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.backgroundColor = .systemBackground
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return Ease.allCases.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as? TweenSampleCell
		cell?.configure(with: Ease.allCases[indexPath.row])
		return cell ?? .init()
	}
}
