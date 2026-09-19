extension View {
    /// Hides the separate labels of controls within this view.
    ///
    /// Picker options, button content and text-field placeholders stay visible.
    /// Labelled content also removes the space reserved for its hidden label.
    /// Textual labels remain available to backends that support accessibility;
    /// supply an explicit `accessibilityLabel` for an arbitrary custom label.
    public func labelsHidden() -> some View {
        environment(\.labelsHidden, true)
    }

    /// Keeps a textual control label on its containing group when hidden.
    /// Apply to the label/control stack, not the control itself, so a custom
    /// style's own accessibility metadata remains intact. This transparent
    /// wrapper stays in place when visibility changes without replacing the
    /// underlying native control or its editing state.
    func retainingHiddenControlLabel<Label: View>(_ label: Label, hidden: Bool) -> some View {
        AccessibilityView(self, properties: .init(
            label: hidden ? controlLabelText(label) : nil
        ))
    }
}

extension EnvironmentValues {
    /// Whether controls omit their separate visual labels.
    ///
    /// The default preserves labels. `labelsHidden()` sets this for a subtree;
    /// an inner environment override can restore labels in that subtree.
    @Entry public var labelsHidden = false
}

/// Extracts the textual forms supplied by the standard control initializers.
/// Do not evaluate an arbitrary label's body just to synthesize metadata.
@MainActor
func controlLabelText<Label: View>(_ label: Label) -> String? {
    if let text = label as? Text {
        return text.string
    }
    if let tuple = label as? TupleView1<Text> {
        return tuple.view0.string
    }
    return nil
}
