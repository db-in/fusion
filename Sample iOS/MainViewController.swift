//
//  MainViewController.swift
//  Sample iOS
//
//  Created by Diney on 5/6/23.
//

import SwiftUI
import UIKit

class MainViewController: UIViewController {

	private enum SampleRow: CaseIterable {
		case tween
		case navigation
	}

	lazy var tableView: UITableView = {
		let tableView = UITableView(frame: view.bounds, style: .plain)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		return tableView
	}()
	
// MARK: - Overriden Methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .red
		view.addSubview(tableView)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.frame = view.bounds
	}
}

extension MainViewController : UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		SampleRow.allCases.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		switch SampleRow.allCases[indexPath.row] {
		case .tween:
			cell.textLabel?.text = "\(TweenViewController.self)"
		case .navigation:
			cell.textLabel?.text = "Navigation"
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		switch SampleRow.allCases[indexPath.row] {
		case .tween:
			let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "\(TweenViewController.self)")
			navigationController?.pushViewController(viewController, animated: true)
		case .navigation:
			let host = UIHostingController(rootView: NavigationSampleView())
			host.title = "Navigation"
			navigationController?.pushViewController(host, animated: true)
		}
	}
}
