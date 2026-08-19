/// The layout metrics that the built-in form styles lay forms and sections
/// out with.
///
/// ``Section`` reads these from the ``FormStyle`` in the environment so that
/// it matches the form around it, even when it's used on its own. A style that
/// SwiftCrossUI doesn't ship has no metrics to report, so sections fall back
/// to ``FormMetrics/automatic``.
package struct FormMetrics: Hashable, Sendable {
    /// The vertical spacing that a ``Form`` leaves between its top-level rows.
    package var formRowSpacing: Int

    /// The padding that a ``Form`` leaves around its content.
    package var formPadding: Int

    /// The vertical spacing that a ``Section`` leaves between its rows.
    package var sectionRowSpacing: Int

    /// The vertical spacing that a ``Section`` leaves between its header, its
    /// content, and its footer.
    package var sectionHeaderSpacing: Int

    /// Whether a ``Section`` draws a container behind its content.
    package var groupsSectionContent: Bool

    /// The padding inside a grouped ``Section``'s container.
    package var sectionContentPadding: Int

    /// The corner radius of a grouped ``Section``'s container.
    package var sectionContentCornerRadius: Int

    /// The metrics used by ``AutomaticFormStyle`` and ``ColumnsFormStyle``.
    ///
    /// Lays a form out as a plain vertical stack of rows, leaving the
    /// surrounding view hierarchy in charge of insetting it.
    package static let automatic = FormMetrics(
        formRowSpacing: 10,
        formPadding: 0,
        sectionRowSpacing: 8,
        sectionHeaderSpacing: 8,
        groupsSectionContent: false,
        sectionContentPadding: 12,
        sectionContentCornerRadius: 8
    )

    /// The metrics used by ``GroupedFormStyle``.
    ///
    /// Insets the form's content and draws a container behind each section's
    /// rows, which is the closest match to the grouped forms that macOS uses
    /// for settings windows and inspectors.
    package static let grouped = FormMetrics(
        formRowSpacing: 18,
        formPadding: 16,
        sectionRowSpacing: 10,
        sectionHeaderSpacing: 6,
        groupsSectionContent: true,
        sectionContentPadding: 12,
        sectionContentCornerRadius: 8
    )
}
