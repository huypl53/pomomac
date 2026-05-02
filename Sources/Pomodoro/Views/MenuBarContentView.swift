import AppKit

protocol MenuBarContentViewDelegate: AnyObject {
    func menuBarTogglePlay()
    func menuBarSkip()
    func menuBarReset()
    func menuBarLabelClicked()
    func menuBarRightClicked()
    func menuBarContentSizeDidChange()
}

/// AppKit view hosted inside the NSStatusBarButton. Pure AppKit (no SwiftUI)
/// so hover detection and layout are synchronous — important because the
/// status item width must follow the visible content with zero lag.
final class MenuBarContentView: NSView {
    weak var delegate: MenuBarContentViewDelegate?

    private let labelButton = NSButton()
    private let pauseButton = NSButton()
    private let skipButton = NSButton()
    private let resetButton = NSButton()
    private let divider = NSBox()
    private let stack = NSStackView()

    private static let controlSize: CGFloat = 18

    private var hovering = false
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    init() {
        super.init(frame: .zero)
        configureSubviews()
        applyHoverState()
    }
    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func configureSubviews() {
        configureControl(pauseButton, symbol: "play.fill", action: #selector(togglePlay))
        configureControl(skipButton, symbol: "forward.end.fill", action: #selector(skip))
        configureControl(resetButton, symbol: "arrow.counterclockwise", action: #selector(reset))

        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        labelButton.font = NSFont.menuBarFont(ofSize: 0)
        labelButton.isBordered = false
        labelButton.bezelStyle = .recessed
        (labelButton.cell as? NSButtonCell)?.imagePosition = .noImage
        labelButton.target = self
        labelButton.action = #selector(labelClicked)
        labelButton.translatesAutoresizingMaskIntoConstraints = false
        labelButton.setButtonType(.momentaryChange)
        setLabelTitle("🍅 00:00")

        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(pauseButton)
        stack.addArrangedSubview(skipButton)
        stack.addArrangedSubview(resetButton)
        stack.addArrangedSubview(divider)
        stack.addArrangedSubview(labelButton)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            divider.heightAnchor.constraint(equalToConstant: 12),
            divider.widthAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func configureControl(_ button: NSButton, symbol: String, action: Selector) {
        button.image = Self.symbolImage(symbol)
        button.imagePosition = .imageOnly
        button.bezelStyle = .recessed
        button.isBordered = false
        button.contentTintColor = .labelColor
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setButtonType(.momentaryChange)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.controlSize),
            button.heightAnchor.constraint(equalToConstant: Self.controlSize),
        ])
    }

    // MARK: - External updates

    func setLabel(_ text: String) {
        setLabelTitle(text)
        invalidateIntrinsicContentSize()
        delegate?.menuBarContentSizeDidChange()
    }

    private func setLabelTitle(_ text: String) {
        let font = labelButton.font ?? NSFont.menuBarFont(ofSize: 0)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
        labelButton.attributedTitle = NSAttributedString(string: text, attributes: attrs)
    }

    func setPauseSymbol(isRunning: Bool) {
        currentPauseSymbol = isRunning ? "pause.fill" : "play.fill"
        pauseButton.image = Self.symbolImage(currentPauseSymbol)
    }

    private static func symbolImage(_ name: String) -> NSImage? {
        let base = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let palette = NSImage.SymbolConfiguration(paletteColors: [.labelColor])
        let cfg = base.applying(palette)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
    }

    // MARK: - Hover

    /// `NSStatusBarButton` swallows mouse events meant for our subview, so we
    /// check the cursor position against the status item's window frame using
    /// a global + local NSEvent monitor instead of relying on tracking areas.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        teardownMouseMonitors()
        guard window != nil else { return }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.updateHoverFromCursor()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateHoverFromCursor()
            return event
        }
    }

    deinit { teardownMouseMonitors() }

    private func teardownMouseMonitors() {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseMonitor { NSEvent.removeMonitor(m) }
        globalMouseMonitor = nil
        localMouseMonitor = nil
    }

    private func updateHoverFromCursor() {
        guard let window else { return }
        let inside = NSPointInRect(NSEvent.mouseLocation, window.frame)
        if inside != hovering {
            hovering = inside
            applyHoverState()
        }
    }

    private func applyHoverState() {
        pauseButton.isHidden = !hovering
        skipButton.isHidden = !hovering
        resetButton.isHidden = !hovering
        divider.isHidden = !hovering
        invalidateIntrinsicContentSize()
        delegate?.menuBarContentSizeDidChange()
    }

    // MARK: - Sizing

    override var intrinsicContentSize: NSSize {
        // NSButton.intrinsicContentSize / fittingSize misreport for borderless
        // bezel-styled buttons, so measure the title text directly.
        let attrs: [NSAttributedString.Key: Any] = [.font: labelButton.font ?? NSFont.menuBarFont(ofSize: 0)]
        let labelWidth = ceil((labelButton.title as NSString).size(withAttributes: attrs).width) + 6
        var width = labelWidth + 8 // outer padding
        if hovering {
            width += (Self.controlSize * 3) + 1 + (6 * 4) // 3 controls + divider + 4 spacings
        }
        return NSSize(width: width, height: NSStatusBar.system.thickness)
    }

    // MARK: - Right-click

    override func rightMouseDown(with event: NSEvent) {
        delegate?.menuBarRightClicked()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            guard let self else { return }
            self.skipButton.image = Self.symbolImage("forward.end.fill")
            self.resetButton.image = Self.symbolImage("arrow.counterclockwise")
            self.pauseButton.image = Self.symbolImage(self.currentPauseSymbol)
            self.setLabelTitle(self.labelButton.title)
        }
    }

    private var currentPauseSymbol = "play.fill"

    @objc private func togglePlay() { delegate?.menuBarTogglePlay() }
    @objc private func skip() { delegate?.menuBarSkip() }
    @objc private func reset() { delegate?.menuBarReset() }
    @objc private func labelClicked() { delegate?.menuBarLabelClicked() }
}
