extension View {
    /// Presents an alert built from a piece of data, while a binding to a
    /// Boolean value is `true` and the data is non-`nil`.
    ///
    /// ```swift
    /// content.alert("Unable to Play", isPresented: $showsFailure, presenting: failure) { failure in
    ///     Button("Retry") { retry(failure) }
    ///     Button("Cancel", role: .cancel) {}
    /// } message: { failure in
    ///     Text(failure.message)
    /// }
    /// ```
    ///
    /// As in SwiftUI, the alert isn't shown while `data` is `nil`, even when
    /// `isPresented` is `true`, and its actions and message are built from
    /// the data as it was when the alert was shown.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - isPresented: A binding controlling whether the alert is presented.
    ///   - data: The data the alert presents.
    ///   - actions: The alert's action buttons, built from the data.
    ///   - message: An explanatory message built from the data. Only text can
    ///     be displayed.
    /// - Returns: A view that presents the described alert.
    public func alert<T, Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        presenting data: T?,
        @ViewBuilder actions: (T) -> Actions,
        @ViewBuilder message: (T) -> Message
    ) -> some View {
        let content = data.map(actions)
        return AlertModifierView(
            child: self,
            title: title,
            message: data.flatMap {
                ConfirmationDialogModifierView<Self>.string(ofMessage: message($0))
            },
            isPresented: Self.presentation(isPresented, while: data != nil),
            actions: content.map { AlertActions.actions(from: $0) } ?? [],
            textEntry: content.flatMap { AlertActions.textEntry(in: $0) },
            actionsType: Actions.self
        )
    }

    /// Presents an alert built from a piece of data, without a message. See
    /// ``View/alert(_:isPresented:presenting:actions:message:)``.
    ///
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - isPresented: A binding controlling whether the alert is presented.
    ///   - data: The data the alert presents.
    ///   - actions: The alert's action buttons, built from the data.
    /// - Returns: A view that presents the described alert.
    public func alert<T, Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        presenting data: T?,
        @ViewBuilder actions: (T) -> Actions
    ) -> some View {
        alert(title, isPresented: isPresented, presenting: data, actions: actions) { _ in
            EmptyView()
        }
    }

    /// Presents a confirmation dialog built from a piece of data, while a
    /// binding to a Boolean value is `true` and the data is non-`nil`.
    ///
    /// ```swift
    /// content.confirmationDialog(
    ///     "Remove these requests?",
    ///     isPresented: $isConfirming,
    ///     presenting: group
    /// ) { group in
    ///     Button("Remove \(group.count) Requests", role: .destructive) { remove(group) }
    /// } message: { group in
    ///     Text("This removes your requests for \(group.title).")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The dialog's title.
    ///   - isPresented: A binding controlling whether the dialog is presented.
    ///   - titleVisibility: Whether to display the title.
    ///   - data: The data the dialog presents.
    ///   - actions: The dialog's action buttons, built from the data.
    ///   - message: An explanatory message built from the data. Only text can
    ///     be displayed.
    /// - Returns: A view that presents the described dialog.
    public func confirmationDialog<T, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        presenting data: T?,
        @ConfirmationDialogActionsBuilder actions: (T) -> [ConfirmationDialogAction],
        @ViewBuilder message: (T) -> Message
    ) -> some View {
        ConfirmationDialogModifierView(
            child: self,
            title: title,
            titleVisibility: titleVisibility,
            message: data.flatMap {
                ConfirmationDialogModifierView<Self>.string(ofMessage: message($0))
            },
            isPresented: Self.presentation(isPresented, while: data != nil),
            actions: data.map(actions) ?? []
        )
    }

    /// Presents a confirmation dialog built from a piece of data, without a
    /// message. See
    /// ``View/confirmationDialog(_:isPresented:titleVisibility:presenting:actions:message:)``.
    ///
    /// - Parameters:
    ///   - title: The dialog's title.
    ///   - isPresented: A binding controlling whether the dialog is presented.
    ///   - titleVisibility: Whether to display the title.
    ///   - data: The data the dialog presents.
    ///   - actions: The dialog's action buttons, built from the data.
    /// - Returns: A view that presents the described dialog.
    public func confirmationDialog<T>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        presenting data: T?,
        @ConfirmationDialogActionsBuilder actions: (T) -> [ConfirmationDialogAction]
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: titleVisibility,
            presenting: data,
            actions: actions
        ) { _ in
            EmptyView()
        }
    }

    /// A presentation binding that reads `false` while there's nothing to
    /// present, and writes through to `isPresented`.
    static func presentation(
        _ isPresented: Binding<Bool>,
        while hasData: Bool
    ) -> Binding<Bool> {
        Binding {
            isPresented.wrappedValue && hasData
        } set: { newValue in
            isPresented.wrappedValue = newValue
        }
    }
}
