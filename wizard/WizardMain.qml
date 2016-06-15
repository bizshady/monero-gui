// Copyright (c) 2014-2015, The Monero Project
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.2
import Qt.labs.settings 1.0

import "../components"

Rectangle {
    id: wizard
    property alias nextButton : nextButton
    property var settings : ({})
    property int currentPage: 0

    property var paths: {
        "create_wallet" : [welcomePage, optionsPage, createWalletPage, passwordPage, donationPage, finishPage ],
        "recovery_wallet" : [welcomePage, optionsPage, recoveryWalletPage, passwordPage, donationPage, finishPage ]
    }
    property string currentPath: "create_wallet"
    property var pages: paths[currentPath]

    signal useMoneroClicked()
    border.color: "#DBDBDB"
    border.width: 1
    color: "#FFFFFF"

    function switchPage(next) {
        // save settings for current page;
        if (next && typeof pages[currentPage].onPageClosed !== 'undefined') {
            if (pages[currentPage].onPageClosed(settings) !== true) {
                print ("Can't go to the next page");
                return;
            };

        }
        print ("switchpage: start: currentPage: ", currentPage);

        if (currentPage > 0 || currentPage < pages.length - 1) {
            pages[currentPage].opacity = 0
            var step_value = next ? 1 : -1
            currentPage += step_value
            pages[currentPage].opacity = 1;

            if (next && typeof pages[currentPage].onPageOpened !== 'undefined') {
                pages[currentPage].onPageOpened(settings)
            }
            handlePageChanged();
        }
    }

    function handlePageChanged() {
        var nextButtonVisible = pages[currentPage] !== optionsPage;
        nextButton.visible = nextButtonVisible;
        print ("next button visible: " + nextButtonVisible);
        switch (pages[currentPage]) {
        case passwordPage:
            // disable "next" button until passwords match
            nextButton.enabled = passwordPage.passwordValid;
            if (currentPath === "create_wallet") {
                passwordPage.titleText = qsTr("Now that your wallet has been created, please set a password for the wallet")
            } else {
                passwordPage.titleText = qsTr("Now that your wallet has been restored, please set a password for the wallet")
            }
            break;
        case finishPage:
            // display settings summary
            finishPage.updateSettingsSummary();
            nextButton.visible = false;
            break;
        case recoveryWalletPage:
            // TODO: disable "next button" until 25 words private key entered
            nextButton.enabled = false
            break
        default:
            nextButton.enabled = true

        }
    }


    function openCreateWalletPage() {
        print ("show create wallet page");
        pages[currentPage].opacity = 0;
        createWalletPage.opacity = 1
        currentPath = "create_wallet"
        pages = paths[currentPath]
        currentPage = pages.indexOf(createWalletPage)
        createWalletPage.createWallet(settings)
        handlePageChanged()

    }

    function openRecoveryWalletPage() {
        print ("show recovery wallet page");
        pages[currentPage].opacity = 0
        recoveryWalletPage.opacity = 1
        currentPath = "recovery_wallet"
        pages = paths[currentPath]
        currentPage = pages.indexOf(recoveryWalletPage)
        handlePageChanged()
    }

    //! actually writes the wallet
    function applySettings() {
        print ("Here we apply the settings");
        // here we need to actually move wallet to the new location
        // put wallet files to the subdirectory with the same name as
        // wallet name
        var new_wallet_filename = settings.wallet_path + "/"
                + settings.account_name + "/"
                + settings.account_name;

        // moving wallet files to the new destination, if user changed it
        if (new_wallet_filename !== settings.wallet_filename) {
            // using previously saved wallet;
            settings.wallet.store(new_wallet_filename);
            //walletManager.moveWallet(settingsObject.wallet_filename, new_wallet_filename);
        }

        // saving wallet_filename;
        settings['wallet_filename'] = new_wallet_filename;

        // persist settings
        persistentSettings.language = settings.language
        persistentSettings.account_name = settings.account_name
        persistentSettings.wallet_path = settings.wallet_path
        persistentSettings.allow_background_mining = settings.allow_background_mining
        persistentSettings.auto_donations_enabled = settings.auto_donations_enabled
        persistentSettings.auto_donations_amount = settings.auto_donations_amount
    }

    // reading settings from persistent storage
    Component.onCompleted: {
        settings['allow_background_mining'] = persistentSettings.allow_background_mining
        settings['auto_donations_enabled'] = persistentSettings.auto_donations_enabled
        settings['auto_donations_amount'] = persistentSettings.auto_donations_amount
    }


    Settings {
        id: persistentSettings

        property string language
        property string account_name
        property string wallet_path
        property bool   auto_donations_enabled : true
        property int    auto_donations_amount : 50
        property bool   allow_background_mining : true
    }

    Rectangle {
        id: nextButton
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 50
        visible: wizard.currentPage !== 1 && wizard.currentPage !== 6
        width: 50; height: 50
        radius: 25
        color: enabled ? nextArea.containsMouse ? "#FF4304" : "#FF6C3C" : "#DBDBDB"


        Image {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 3
            source: "qrc:///images/nextPage.png"
        }

        MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: wizard.switchPage(true)
        }
    }


    WizardWelcome {
        id: welcomePage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }

    WizardOptions {
        id: optionsPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
        onCreateWalletClicked: wizard.openCreateWalletPage()
        onRecoveryWalletClicked: wizard.openRecoveryWalletPage()
    }

    WizardCreateWallet {
        id: createWalletPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }

    WizardRecoveryWallet {
        id: recoveryWalletPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }



    WizardPassword {
        id: passwordPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }

    WizardDonation {
        id: donationPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }

    WizardFinish {
        id: finishPage
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: nextButton.left
        anchors.left: prevButton.right
        anchors.leftMargin: 50
        anchors.rightMargin: 50
    }

    Rectangle {
        id: prevButton
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 50
        visible: parent.currentPage > 0

        width: 50; height: 50
        radius: 25
        color: prevArea.containsMouse ? "#FF4304" : "#FF6C3C"

        Image {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -3
            source: "qrc:///images/prevPage.png"
        }

        MouseArea {
            id: prevArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: wizard.switchPage(false)
        }
    }

    StandardButton {
        id: sendButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 50
        width: 110
        text: qsTr("USE MONERO")
        shadowReleasedColor: "#FF4304"
        shadowPressedColor: "#B32D00"
        releasedColor: "#FF6C3C"
        pressedColor: "#FF4304"
        visible: parent.paths[currentPath][currentPage] === finishPage
        onClicked: {
            wizard.applySettings();
            wizard.useMoneroClicked()
        }
    }
}
