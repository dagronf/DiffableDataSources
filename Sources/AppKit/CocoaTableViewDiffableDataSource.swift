#if os(macOS)

import AppKit
import DifferenceKit

/// A class for backporting `NSTableViewDiffableDataSource` introduced in macOS 10.11+.
/// Represents the data model object for `NSTableView` that can be applies the
/// changes with automatic diffing.
open class CocoaTableViewDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: NSObject, NSTableViewDataSource, NSTableViewDelegate {
	 /// The type of closure providing the cell. (Table, Column, Row, Item)
	public typealias CellProvider = (NSTableView, NSTableColumn, Int, ItemIdentifierType) -> NSTableCellView?

	 /// The default animation to updating the views.
	 public var defaultRowAnimation: NSTableView.AnimationOptions = .effectFade

	 private weak var tableView: NSTableView?
	 private let cellProvider: CellProvider
	 private let core = DiffableDataSourceCore<SectionIdentifierType, ItemIdentifierType>()

	 /// Creates a new data source.
	 ///
	 /// - Parameters:
	 ///   - tableView: A table view instance to be managed.
	 ///   - cellProvider: A closure to dequeue the cell for rows.
	 public init(tableView: NSTableView, cellProvider: @escaping CellProvider) {
		  self.tableView = tableView
		  self.cellProvider = cellProvider
		  super.init()

		  tableView.dataSource = self
		  tableView.delegate = self
	 }

	 /// Applies given snapshot to perform automatic diffing update.
	 ///
	 /// - Parameters:
	 ///   - snapshot: A snapshot object to be applied to data model.
	 ///   - animatingDifferences: A Boolean value indicating whether to update with
	 ///                           diffing animation.
	 ///   - completion: An optional completion block which is called when the complete
	 ///                 performing updates.
	 public func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
		  core.apply(
				snapshot,
				view: tableView,
				animatingDifferences: animatingDifferences,
				performUpdates: { tableView, changeset, setSections in
					 tableView.reload(using: changeset, with: self.defaultRowAnimation, setData: setSections)
		  },
				completion: completion
		  )
	 }

	 /// Returns a new snapshot object of current state.
	 ///
	 /// - Returns: A new snapshot object of current state.
	 public func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
		  return core.snapshot()
	 }

	 /// Returns an item identifier for given index path.
	 ///
	 /// - Parameters:
	 ///   - indexPath: An index path for the item identifier.
	 ///
	 /// - Returns: An item identifier for given index path.
	 public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
		  return core.itemIdentifier(for: indexPath)
	 }

	 /// Returns an index path for given item identifier.
	 ///
	 /// - Parameters:
	 ///   - itemIdentifier: An identifier of item.
	 ///
	 /// - Returns: An index path for given item identifier.
	 public func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
		  return core.indexPath(for: itemIdentifier)
	 }

	 /// Returns the number of rows in the data source.
	 ///
	 /// - Parameters:
	 ///   - tableView: A table view instance managed by `self`.
	 ///
	 /// - Returns: The number of rows in the data source.
	 public func numberOfRows(in tableView: NSTableView) -> Int {
		 return core.numberOfItems(inSection: 0)
	 }

	 /// Returns a cell for row at specified index path.
	 ///
	 /// - Parameters:
	 ///   - tableView: A table view instance managed by `self`.
	 ///   - tableColumn: The column to load the view for
	 ///   - row: The row of data within the data source
	 ///
	 /// - Returns: A cell for row at specified index path.

	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let column = tableColumn else {
			return nil
		}

		let indexPath = IndexPath(item: row, section: 0)

		let itemIdentifier = core.unsafeItemIdentifier(for: indexPath)
		guard let cell = cellProvider(tableView, column, row, itemIdentifier) else {
			universalError("NSTableView dataSource returned a nil cell view for row at index path: \(row), tableView: \(tableView), itemIdentifier: \(itemIdentifier), column: \(column)")
		}
		return cell
	}
}

#endif
