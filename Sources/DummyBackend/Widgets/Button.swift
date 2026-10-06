import SwiftCrossUI

extension DummyBackend {
    public class Button: Widget {
        public var label: Widget?
        public var action: (() -> Void)?
        public var buttonStyle: any ButtonStyle = .bordered
        /// The menu the button shows, when it is a menu drawn with a label view.
        public var menu: Menu?
    }
}
