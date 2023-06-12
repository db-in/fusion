//
//  MainViewController.swift
//  Sample iOS
//
//  Created by Diney on 5/6/23.
//

import UIKit

class MainViewController: UIViewController {

	lazy var tableView: UITableView = {
		let tableView = UITableView(frame: view.bounds, style: .plain)
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		return tableView
	}()
	
	let viewControllers: [UIViewController.Type] = [TweenViewController.self]
	
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
		return viewControllers.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		let viewControllerType = viewControllers[indexPath.row]
		cell.textLabel?.text = "\(viewControllerType)"
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let viewControllerType = viewControllers[indexPath.row]
		let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "\(viewControllerType)") //viewControllerType.init()
		navigationController?.pushViewController(viewController, animated: true)
	}
}
