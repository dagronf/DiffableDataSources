import Cocoa
import DiffableDataSources

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet var window: NSWindow!

	@IBOutlet var BigTableView: NSTableView!

	@IBOutlet var searchField: NSSearchField!

	// MARK: Diffable data source definitions

	enum Section {
		case main
	}

	struct Mountain: Hashable {
		var name: String
		var count: String

		func contains(_ filter: String) -> Bool {
			guard !filter.isEmpty else {
				return true
			}
			return self.name.localizedCaseInsensitiveContains(filter)
		}
	}

	private let allMountains: [Mountain] = mountainsRawData.components(separatedBy: .newlines).map { line in
		let name = line.components(separatedBy: ",")[0]
		let count = line.components(separatedBy: ",")[1]
		return Mountain(name: name, count: count)
	}.sorted { a, b in a.name < b.name }

	// MARK: Data source

	private lazy var dataSource = CocoaTableViewDiffableDataSource<Section, Mountain>(tableView: BigTableView) { tableView, column, row, mountain in

		if column.identifier == NSUserInterfaceItemIdentifier("first") {
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("TableCellOne"), owner: self) as? NSTableCellView else {
				return NSTableCellView()
			}

			cell.textField?.stringValue = mountain.name
			return cell
		}

		if column.identifier == NSUserInterfaceItemIdentifier("second") {
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("TableCellTwo"), owner: self) as? NSTableCellView else {
				return NSTableCellView()
			}

			cell.textField?.stringValue = mountain.count
			return cell
		}

		fatalError("Unknown cell type '\(column.identifier)'.")
	}

	// MARK: App

	func applicationDidFinishLaunching(_: Notification) {
		// Load in all the mountains by default
		var snapshot = DiffableDataSourceSnapshot<Section, Mountain>()
		snapshot.appendSections([.main])
		snapshot.appendItems(self.allMountains)
		self.dataSource.apply(snapshot)
	}

	func applicationWillTerminate(_: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
		return true
	}
}

extension AppDelegate: NSSearchFieldDelegate {
	func controlTextDidChange(_: Notification) {
		let text = searchField.stringValue
		search(filter: text)
	}

	func search(filter: String) {
		let mountains = self.allMountains.lazy
			.filter { $0.contains(filter) }
			.sorted { $0.name < $1.name }

		var snapshot = DiffableDataSourceSnapshot<Section, Mountain>()
		snapshot.appendSections([.main])
		snapshot.appendItems(mountains)
		dataSource.apply(snapshot)
	}
}
