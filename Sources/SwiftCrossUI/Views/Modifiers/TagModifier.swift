/// A view that associates a hashable value with its content.
///
/// Apply one with ``SwiftCrossUI/View/tag(_:)``. An enclosing ``Picker``
/// collects the tags of its content to work out which options it offers, and
/// writes the tag of the chosen option back to its selection binding.
///
/// ```swift
/// Picker("Kind", selection: $kind) {
///     Text("Alpha").tag(Kind.alpha)
///     Text("Beta").tag(Kind.beta)
/// }
/// ```
///
/// Outside of a picker the modifier is transparent; it renders its content
/// exactly as if the tag hadn't been applied.
public struct TagModifier<Content: View, Value: Hashable>: View {
    public var body: TupleView1<Content>

    /// The value associated with the content.
    private var value: Value

    /// Associates a value with a view.
    ///
    /// - Parameters:
    ///   - content: The view to tag.
    ///   - value: The value to associate with `content`.
    init(content: Content, value: Value) {
        body = TupleView1(content)
        self.value = value
    }
}

extension TagModifier: TaggedView {
    var tagValue: AnyHashable {
        AnyHashable(value)
    }

    var taggedContent: any View {
        body.view0
    }
}

extension View {
    /// Associates a value with the view, identifying it to an enclosing
    /// ``Picker``.
    ///
    /// The tag is what a picker writes to its selection binding when the user
    /// chooses this view's option, and what it compares the binding against to
    /// work out which option is currently selected. Tags therefore have to
    /// share the type of the picker's selection (an optional selection also
    /// accepts tags of its wrapped type).
    ///
    /// - Parameter tag: The value to associate with the view.
    /// - Returns: A view carrying the given tag.
    public func tag<Value: Hashable>(_ tag: Value) -> some View {
        TagModifier(content: self, value: tag)
    }
}

/// A view that carries a tag applied with ``SwiftCrossUI/View/tag(_:)``.
///
/// Lets ``PickerOptionCollector`` recognise tagged views without knowing the
/// type of the tag or of the view that carries it.
@MainActor
protocol TaggedView {
    /// The value that the view was tagged with.
    var tagValue: AnyHashable { get }

    /// The view that the tag was applied to.
    var taggedContent: any View { get }
}

/// A view that contributes its children, rather than itself, to an enclosing
/// ``Picker``'s options.
///
/// Every conformer here is a view that exists to hold other views together
/// without meaning anything by itself: the ``GroupingContainer``s that the
/// layout system already sees through (``ForEach``, and ``Group`` by way of
/// its content), the views that `ViewBuilder` produces for conditionals, and
/// ``AnyView``. Views whose `body` is their content don't need a conformance;
/// the collector walks into `body` for those.
@MainActor
protocol PickerContentContainer {
    /// The views that stand in for this view while a picker collects options.
    var pickerContentChildren: [any View] { get }
}

extension ForEach: PickerContentContainer where Child: View {
    var pickerContentChildren: [any View] {
        elements.map(child)
    }
}

extension Group: PickerContentContainer {
    var pickerContentChildren: [any View] {
        [body]
    }
}

extension EitherView: PickerContentContainer {
    var pickerContentChildren: [any View] {
        switch storage {
            case .a(let a):
                [a]
            case .b(let b):
                [b]
        }
    }
}

extension OptionalView: PickerContentContainer {
    var pickerContentChildren: [any View] {
        guard let view else {
            return []
        }
        return [view]
    }
}

extension AnyView: PickerContentContainer {
    var pickerContentChildren: [any View] {
        [child]
    }
}

/// Collects the options that a ``Picker``'s content describes.
///
/// The collector walks the content's view tree looking for views tagged with
/// ``SwiftCrossUI/View/tag(_:)``, pairing each tag with the text that the
/// tagged view displays. Untagged text becomes an option tagged with its own
/// string, so that a picker over strings doesn't need explicit tags.
///
/// ## Why this isn't a `ContainerChildLayout`
///
/// ``ContainerChildLayout`` solves the same shape of problem for layout — it's
/// how a ``LazyVGrid`` gets to see the items of a ``ForEach`` individually —
/// but it can't be reused here. It hands out
/// ``LayoutSystem/LayoutableChild``s, which are closures over already-created
/// view graph nodes: they can report a layout, but they can't say what view
/// they came from, and the only channel back out of them is
/// ``ViewLayoutResult/preferences``, whose ``PreferenceValues`` is a closed
/// struct. A picker also has nothing to lay out — backends render it as a
/// single leaf control that has to be handed its options as strings before any
/// of the content's widgets could exist. So the traversal here mirrors the
/// grouping-container idea at the view level, descending into exactly the view
/// types that the layout system treats as transparent.
struct PickerOptionCollector {
    /// How deep the collector walks into a picker's content before giving up.
    ///
    /// A view whose `body` eventually produces itself would otherwise recurse
    /// forever.
    private static let depthLimit = 64

    /// The options collected so far.
    private var options: [PickerOption] = []

    /// The environment that views are given before their bodies are read.
    ///
    /// The collector runs outside the view graph, so nothing else would
    /// install a view's `@Environment` values before its `body` reads them.
    private var environment: EnvironmentValues?

    /// Collects the options described by a picker's content.
    ///
    /// - Parameters:
    ///   - content: The picker's content.
    ///   - environment: The picker's environment. Pass it whenever one is
    ///     available: a view in the content whose `body` reads an
    ///     `@Environment` value (as ``Label`` does) can only be walked into
    ///     with its environment installed.
    /// - Returns: The picker's options, in the order that they appear.
    @MainActor
    static func options(
        of content: some View,
        environment: EnvironmentValues? = nil
    ) -> [PickerOption] {
        var collector = PickerOptionCollector()
        collector.environment = environment
        collector.collect(content, depth: 0)
        return collector.options
    }

    /// Collects the options described by a single view and its content.
    ///
    /// - Parameters:
    ///   - view: The view to collect from.
    ///   - depth: How far into the picker's content `view` sits.
    @MainActor
    private mutating func collect(_ view: any View, depth: Int) {
        guard depth <= Self.depthLimit else {
            logger.warning(
                "Picker content nested too deeply; some options were skipped",
                metadata: ["viewType": "\(type(of: view))"]
            )
            return
        }

        if let tagged = view as? any TaggedView {
            let tag = tagged.tagValue
            let title =
                title(of: tagged.taggedContent, depth: depth)
                ?? String(describing: tag.base)
            append(title: title, tag: tag)
            return
        }

        if let text = view as? Text {
            append(title: text.string, tag: AnyHashable(text.string))
            return
        }

        for child in children(of: view) {
            collect(child, depth: depth + 1)
        }
    }

    /// Records an option.
    ///
    /// - Parameters:
    ///   - title: The text to display for the option.
    ///   - tag: The value that identifies the option.
    private mutating func append(title: String, tag: AnyHashable) {
        options.append(PickerOption(title: title, tag: tag, index: options.count))
    }

    /// The text that a picker should display for a tagged view.
    ///
    /// - Parameters:
    ///   - view: The tagged view.
    ///   - depth: How far into the picker's content `view` sits.
    /// - Returns: The first piece of text found in the view, or `nil` if it
    ///   displays no text of its own.
    @MainActor
    private func title(of view: any View, depth: Int) -> String? {
        guard depth <= Self.depthLimit else {
            return nil
        }

        if let text = view as? Text {
            return text.string
        }

        for child in children(of: view) {
            if let title = title(of: child, depth: depth + 1) {
                return title
            }
        }
        return nil
    }

    /// The views that a view contributes to a picker's options.
    ///
    /// Views that know their picker-relevant parts (``Label``, ``ForEach``,
    /// ``Group`` and friends) hand them over directly through
    /// ``PickerContentContainer``, so their `body` is never evaluated. Any
    /// other view is walked into through its `body`, after its dynamic
    /// properties have been given the picker's environment so that an
    /// `@Environment` read inside the body doesn't trap.
    ///
    /// - Parameter view: The view to look inside.
    /// - Returns: The view's children, or an empty array if it has none.
    @MainActor
    private func children(of view: any View) -> [any View] {
        if view is EmptyView || view is Never {
            // Both of these have a `body` that traps when accessed.
            return []
        }

        if let container = view as? any PickerContentContainer {
            return container.pickerContentChildren
        }

        if view is any TupleView {
            // The generated tuple views store their children as `view0`,
            // `view1`, ... followed by an `EmptyView` body, which contributes
            // nothing.
            return Mirror(reflecting: view).children.compactMap { child in
                child.value as? any View
            }
        }

        if let environment {
            return [view.erasedBody(in: environment)]
        }
        return [view.erasedBody]
    }
}

extension View {
    /// This view's body with its concrete type erased.
    ///
    /// Lets ``PickerOptionCollector`` walk into an arbitrary view without
    /// knowing what its body is.
    ///
    /// - Warning: Accessing this on ``EmptyView`` or `Never` traps, just as
    ///   accessing their `body` directly does.
    fileprivate var erasedBody: any View {
        body
    }

    /// This view's body with its concrete type erased, evaluated with the
    /// view's dynamic properties (`@Environment`, `@State`, ...) installed
    /// from the given environment first, exactly as the view graph would do
    /// before reading `body`.
    ///
    /// - Parameter environment: The environment to install.
    /// - Returns: The body.
    @MainActor
    fileprivate func erasedBody(in environment: EnvironmentValues) -> any View {
        DynamicPropertyUpdater(for: self).update(
            self,
            with: environment,
            previousValue: nil
        )
        return body
    }
}
