@_spi(Backends) import SwiftCrossUI

extension DummyBackend: BackendFeatures.AttachedMenus, BackendFeatures.ViewLabelMenus {
    public class Menu {
        public var content: ResolvedMenu

        public init() {
            content = ResolvedMenu(items: [])
        }
    }

    public func createPopoverMenu() -> Menu {
        Menu()
    }

    public func updatePopoverMenu(
        _ menu: Menu,
        content: ResolvedMenu,
        environment: EnvironmentValues
    ) {
        menu.content = content
    }

    public func updateButton(
        _ button: Widget,
        label: String,
        menu: Menu,
        environment: EnvironmentValues
    ) {
        updateSimpleButton(button, label: label, environment: environment, action: {})
        (button as! SimpleButton).menu = menu
    }

    public func attachMenu(_ menu: Menu, toButton button: Widget) {
        (button as! Button).menu = menu
    }
}
