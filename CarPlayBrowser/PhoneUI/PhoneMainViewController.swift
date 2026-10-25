//
//  PhoneMainViewController.swift
//  CarPlayBrowser
//
//  iPhone primary status screen displaying real-time CarPlay connection status,
//  active media playback info, and automotive usage instructions.
//

import UIKit

public class PhoneMainViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStackView = UIStackView()

    // Status Card Components
    private let statusCardView = UIView()
    private let statusIndicator = UIView()
    private let statusTitleLabel = UILabel()
    private let statusDescriptionLabel = UILabel()
    private let sessionRoleBadge = UILabel()

    // Active Media Card Components
    private let mediaCardView = UIView()
    private let mediaHeaderLabel = UILabel()
    private let mediaTitleLabel = UILabel()
    private let mediaSubtitleLabel = UILabel()
    private let playbackStateBadge = UILabel()
    private let mediaProgressLabel = UILabel()

    // Instructions Card Components
    private let instructionsCardView = UIView()
    private let instructionsTitleLabel = UILabel()
    private let instructionsBodyLabel = UILabel()

    // MARK: - State Properties
    public private(set) var isCarPlayConnected: Bool = false
    public private(set) var currentMediaTitle: String = "No Active Media"
    public private(set) var currentMediaURL: String = "Idle"
    public private(set) var isMediaPlaying: Bool = false

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
        updateCarPlayStatus(connected: false)
        updatePlaybackState(title: "Ready", channelOrURL: "Launch YouTube or Google from CarPlay", isPlaying: false, currentTime: 0, duration: 0)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    private func setupUI() {
        title = Constants.App.name
        view.backgroundColor = .systemGroupedBackground

        // Setup ScrollView and StackView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.pinToSafeArea(of: view)
        contentView.pinToEdges(of: scrollView)
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true

        mainStackView.axis = .vertical
        mainStackView.spacing = 16
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        contentView.addSubview(mainStackView)
        mainStackView.pinToEdges(of: contentView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16))

        // Build Cards
        setupStatusCard()
        setupMediaCard()
        setupInstructionsCard()

        mainStackView.addArrangedSubview(statusCardView)
        mainStackView.addArrangedSubview(mediaCardView)
        mainStackView.addArrangedSubview(instructionsCardView)
    }

    private func setupStatusCard() {
        statusCardView.backgroundColor = .secondarySystemGroupedBackground
        statusCardView.layer.cornerRadius = Constants.UI.cornerRadius
        statusCardView.layer.masksToBounds = true

        statusIndicator.layer.cornerRadius = 6
        statusIndicator.backgroundColor = .systemGray
        statusIndicator.setDimensions(width: 12, height: 12)

        statusTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        statusTitleLabel.textColor = .label

        statusDescriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusDescriptionLabel.textColor = .secondaryLabel
        statusDescriptionLabel.numberOfLines = 0

        sessionRoleBadge.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        sessionRoleBadge.textColor = .tertiaryLabel
        sessionRoleBadge.text = Constants.SceneSessionRoles.carPlayTemplate

        let headerStack = UIStackView(arrangedSubviews: [statusIndicator, statusTitleLabel, UIView()])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        let cardStack = UIStackView(arrangedSubviews: [headerStack, statusDescriptionLabel, sessionRoleBadge])
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.alignment = .fill
        statusCardView.addSubview(cardStack)
        cardStack.pinToEdges(of: statusCardView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    private func setupMediaCard() {
        mediaCardView.backgroundColor = .secondarySystemGroupedBackground
        mediaCardView.layer.cornerRadius = Constants.UI.cornerRadius
        mediaCardView.layer.masksToBounds = true

        mediaHeaderLabel.font = .systemFont(ofSize: 12, weight: .bold)
        mediaHeaderLabel.textColor = .secondaryLabel
        mediaHeaderLabel.text = "NOW PLAYING ON CARPLAY"

        mediaTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        mediaTitleLabel.textColor = .label
        mediaTitleLabel.numberOfLines = 2

        mediaSubtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        mediaSubtitleLabel.textColor = .secondaryLabel
        mediaSubtitleLabel.numberOfLines = 1

        playbackStateBadge.font = .systemFont(ofSize: 12, weight: .medium)
        playbackStateBadge.textAlignment = .center
        playbackStateBadge.layer.cornerRadius = 4
        playbackStateBadge.layer.masksToBounds = true
        playbackStateBadge.backgroundColor = .systemGray5
        playbackStateBadge.textColor = .secondaryLabel
        playbackStateBadge.text = " Idle "

        mediaProgressLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        mediaProgressLabel.textColor = .secondaryLabel
        mediaProgressLabel.text = "--:-- / --:--"

        let metaStack = UIStackView(arrangedSubviews: [playbackStateBadge, mediaProgressLabel, UIView()])
        metaStack.axis = .horizontal
        metaStack.spacing = 10
        metaStack.alignment = .center

        let cardStack = UIStackView(arrangedSubviews: [
            mediaHeaderLabel,
            mediaTitleLabel,
            mediaSubtitleLabel,
            metaStack
        ])
        cardStack.axis = .vertical
        cardStack.spacing = 6
        cardStack.alignment = .fill
        mediaCardView.addSubview(cardStack)
        cardStack.pinToEdges(of: mediaCardView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    private func setupInstructionsCard() {
        instructionsCardView.backgroundColor = .secondarySystemGroupedBackground
        instructionsCardView.layer.cornerRadius = Constants.UI.cornerRadius
        instructionsCardView.layer.masksToBounds = true

        instructionsTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        instructionsTitleLabel.textColor = .label
        instructionsTitleLabel.text = "In-Car Quick Guide"

        instructionsBodyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        instructionsBodyLabel.textColor = .secondaryLabel
        instructionsBodyLabel.numberOfLines = 0
        instructionsBodyLabel.text = """
        • Connect your iPhone to an Apple CarPlay-enabled vehicle or Xcode CarPlay Simulator.
        • Tap "YouTube" or "Google Search" on the car's display to begin browsing.
        • Steering wheel buttons (Play, Pause, Track Skip) directly control in-browser video playback.
        • Audio continues playing smoothly in the background when your phone screen turns off.
        """

        let cardStack = UIStackView(arrangedSubviews: [instructionsTitleLabel, instructionsBodyLabel])
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.alignment = .fill
        instructionsCardView.addSubview(cardStack)
        cardStack.pinToEdges(of: instructionsCardView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
    }

    // MARK: - Notifications & State Observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCarPlayDidConnect(_:)),
            name: Constants.Notifications.carPlayDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCarPlayDidDisconnect(_:)),
            name: Constants.Notifications.carPlayDidDisconnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateDidChange(_:)),
            name: Constants.Notifications.playbackStateDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActiveURLDidChange(_:)),
            name: Constants.Notifications.activeURLDidChange,
            object: nil
        )
    }

    // MARK: - Update Handlers
    @objc private func handleCarPlayDidConnect(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCarPlayStatus(connected: true)
        }
    }

    @objc private func handleCarPlayDidDisconnect(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCarPlayStatus(connected: false)
        }
    }

    @objc private func handlePlaybackStateDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let title = userInfo[Constants.UserInfoKeys.currentTitle] as? String ?? currentMediaTitle
        let channel = userInfo[Constants.UserInfoKeys.channelName] as? String ?? currentMediaURL
        let isPlaying = userInfo[Constants.UserInfoKeys.isPlaying] as? Bool ?? false
        let currentTime = userInfo[Constants.UserInfoKeys.currentTime] as? Double ?? 0
        let duration = userInfo[Constants.UserInfoKeys.duration] as? Double ?? 0

        DispatchQueue.main.async { [weak self] in
            self?.updatePlaybackState(
                title: title,
                channelOrURL: channel,
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
        }
    }

    @objc private func handleActiveURLDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let urlString = userInfo[Constants.UserInfoKeys.currentURL] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            self?.currentMediaURL = urlString
            self?.mediaSubtitleLabel.text = urlString
        }
    }

    public func updateCarPlayStatus(connected: Bool) {
        isCarPlayConnected = connected
        if connected {
            statusIndicator.backgroundColor = .systemGreen
            statusTitleLabel.text = "CarPlay Connected"
            statusDescriptionLabel.text = "In-car browsing session is active on the external vehicle screen."
        } else {
            statusIndicator.backgroundColor = .systemGray
            statusTitleLabel.text = "CarPlay Disconnected"
            statusDescriptionLabel.text = "Connect iPhone to your vehicle or CarPlay Simulator to activate."
        }
    }

    public func updatePlaybackState(
        title: String,
        channelOrURL: String,
        isPlaying: Bool,
        currentTime: Double,
        duration: Double
    ) {
        currentMediaTitle = title
        currentMediaURL = channelOrURL
        isMediaPlaying = isPlaying

        mediaTitleLabel.text = title
        mediaSubtitleLabel.text = channelOrURL

        if isPlaying {
            playbackStateBadge.text = " Playing "
            playbackStateBadge.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            playbackStateBadge.textColor = .systemGreen
        } else {
            playbackStateBadge.text = " Paused "
            playbackStateBadge.backgroundColor = .systemGray5
            playbackStateBadge.textColor = .secondaryLabel
        }

        if duration > 0 && duration.isFinite && currentTime.isFinite {
            mediaProgressLabel.text = String(
                format: "%02d:%02d / %02d:%02d",
                Int(currentTime) / 60,
                Int(currentTime) % 60,
                Int(duration) / 60,
                Int(duration) % 60
            )
        } else {
            mediaProgressLabel.text = (isPlaying && !duration.isFinite) ? "LIVE" : "--:-- / --:--"
        }
    }
}
