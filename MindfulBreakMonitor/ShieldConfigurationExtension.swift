//
//  ShieldConfigurationExtension.swift
//  MindfulBreakMonitor
//
//  Custom shield screen with challenge
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Custom shield configuration for blocked apps
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.shield.fill"),
            title: ShieldConfiguration.Label(
                text: "Time Limit Reached",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete the challenge below to unlock for 1 minute",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return ShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return ShieldConfiguration()
    }
}
