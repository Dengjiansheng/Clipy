//
//  CPYPreferenceWindowController.swift
//  Clipy
//
//  Created by 古林俊佑 on 2015/06/28.
//  Copyright (c) 2015年 Shunsuke Furubayashi. All rights reserved.
//

import Cocoa

class CPYPreferenceWindowController: DBPrefsWindowController, NSWindowDelegate {

    // MARK: - Propertis
    // Views
    @IBOutlet var generalPreferenceView: NSView!
    @IBOutlet var menuPreferenceView: NSView!
    @IBOutlet var typePreferenceView: NSView!
    @IBOutlet var shortcutPreferenceView: NSView!
    @IBOutlet var updatePreferenceView: NSView!
    @IBOutlet weak var versionTextField: NSTextField!
    // Hot Keys
    @IBOutlet weak var mainShortcutRecorder: SRRecorderControl!
    @IBOutlet weak var historyShortcutRecorder: SRRecorderControl!
    @IBOutlet weak var snippetsShortcutRecorder: SRRecorderControl!
    private var shortcutRecorders = [SRRecorderControl]()
    var storeTypes: NSMutableDictionary!
    private let defaults = NSUserDefaults.standardUserDefaults()

    // MARK: - Init
    override init(window: NSWindow?) {
        super.init(window: window)
        if let types = defaults.objectForKey(Constants.UserDefaults.storeTypes)?.mutableCopy() as? NSMutableDictionary {
            storeTypes = types
        } else {
            storeTypes = NSMutableDictionary()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if let window = window {
            window.delegate = self
            window.center()
            window.releasedWhenClosed = false
        }
        prepareHotKeys()
        versionTextField.stringValue = "v\(NSBundle.mainBundle().appVersion ?? "")"
    }

    // MARK: - Override Methods
    override func showWindow(sender: AnyObject?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }

    override func setupToolbar() {
        if let image = NSImage(named: NSImageNamePreferencesGeneral) {
            addView(generalPreferenceView, label: LocalizedString.TabGeneral.value, image: image)
        }
        if let image = NSImage(assetIdentifier: .Menu) {
            addView(menuPreferenceView, label: LocalizedString.TabMenu.value, image: image)
        }
        if let image = NSImage(assetIdentifier: .IconApplication) {
            addView(typePreferenceView, label: LocalizedString.TabType.value, image: image)
        }
        if let image = NSImage(assetIdentifier: .IconKeyboard) {
            addView(shortcutPreferenceView, label: LocalizedString.TabShortcuts.value, image: image)
        }
        if let image = NSImage(assetIdentifier: .IconSparkle) {
            addView(updatePreferenceView, label: LocalizedString.TabUpdates.value, image: image)
        }

        crossFade = true
        shiftSlowsAnimation = false
    }

    // MARK: - Private Methods
    private func prepareHotKeys() {
        shortcutRecorders = [mainShortcutRecorder, historyShortcutRecorder, snippetsShortcutRecorder]

        let hotKeyMap = CPYHotKeyManager.sharedManager.hotkeyMap
        if let hotKeyCombos = defaults.objectForKey(Constants.UserDefaults.hotKeys) as? [String: AnyObject] {
            for (identifier, keyCombo) in hotKeyCombos {
                if let keyComboPlist = keyCombo as? [String: AnyObject], let keyCode = keyComboPlist["keyCode"] as? Int, let modifiers = keyComboPlist["modifiers"] as? UInt {
                    if let keys = hotKeyMap[identifier] as? [String: AnyObject], let index = keys[Constants.Common.index] as? Int {
                        let recorder = shortcutRecorders[index]
                        let keyCombo = KeyCombo(flags: recorder.carbonToCocoaFlags(modifiers), code: keyCode)
                        recorder.keyCombo = keyCombo
                        recorder.animates = true
                    }
                }
            }
        }
    }

    private func changeHotKeyByShortcutRecorder(aRecorder: SRRecorderControl!, keyCombo: KeyCombo) {
        let newKeyCombo = PTKeyCombo(keyCode: keyCombo.code, modifiers: aRecorder.cocoaToCarbonFlags(keyCombo.flags))

        var identifier = ""
        if aRecorder == mainShortcutRecorder {
            identifier = Constants.Menu.clip
        } else if aRecorder == historyShortcutRecorder {
            identifier = Constants.Menu.history
        } else if aRecorder == snippetsShortcutRecorder {
            identifier = Constants.Menu.snippet
        }

        let hotKeyCenter = PTHotKeyCenter.sharedCenter()
        let oldHotKey = hotKeyCenter.hotKeyWithIdentifier(identifier)
        hotKeyCenter.unregisterHotKey(oldHotKey)

        if var hotKeyPrefs = defaults.objectForKey(Constants.UserDefaults.hotKeys) as? [String: AnyObject] {
            hotKeyPrefs.updateValue(newKeyCombo.plistRepresentation(), forKey: identifier)
            defaults.setObject(hotKeyPrefs, forKey: Constants.UserDefaults.hotKeys)
            defaults.synchronize()
        }
    }

    // MARK: - SRRecoederControl Delegate
    func shortcutRecorder(aRecorder: SRRecorderControl!, keyComboDidChange newKeyCombo: KeyCombo) {
        if shortcutRecorders.contains(aRecorder) {
            changeHotKeyByShortcutRecorder(aRecorder, keyCombo: newKeyCombo)
        }
    }

    func windowWillClose(notification: NSNotification) {
        defaults.setObject(storeTypes, forKey: Constants.UserDefaults.storeTypes)

        if let window = window {
            if !window.makeFirstResponder(window) {
                window.endEditingFor(nil)
            }
        }
        NSApp.deactivate()
    }

}
