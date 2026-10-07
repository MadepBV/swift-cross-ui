/// A view that behaves like a spacer on certain device classes, and in a ``Form`` on every one, for
/// `HStack`-based controls like ``ColorPicker``, switch-style ``Toggle`` and a labelled ``Picker``.
///
/// A desktop control follows its label, but a form row puts its label at the leading edge and its
/// control at the trailing one, as SwiftUI's grouped form does on a Mac.
struct HorizontalControlSpacer: View {
    @Environment(\.deviceClass) private var deviceClass
    @Environment(\.isInsideForm) private var isInsideForm

    var body: some View {
        if deviceClass != .desktop || isInsideForm {
            HStack { // workaround for #728
                Spacer()
            }
        }
    }
}
