import AppKit

extension NSAlert {
    /// Recursively centers all NSTextField labels within the given view hierarchy
    /// and updates their paragraph style alignment to `.center`.
    public static func centerTextFields(in view: NSView) {
        if let tf = view as? NSTextField {
            tf.alignment = .center
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .center
            let mutable = NSMutableAttributedString(attributedString: tf.attributedStringValue)
            if mutable.length > 0 {
                mutable.addAttribute(.paragraphStyle, value: pStyle, range: NSRange(location: 0, length: mutable.length))
                tf.attributedStringValue = mutable
            }
        }
        for subview in view.subviews {
            centerTextFields(in: subview)
        }
    }

    /// Horizontally centers title and informative text labels within the alert.
    /// Hooks into the main runloop before presentation to override default AppKit `.natural` alignment.
    @discardableResult
    @MainActor
    public func centered() -> Self {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window, let contentView = window.contentView else { return }
            Self.centerTextFields(in: contentView)
        }
        return self
    }
}
