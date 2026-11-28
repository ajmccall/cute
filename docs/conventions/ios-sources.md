# iOS convention reference: sources

The sources, quotations and observations behind the rules in `ios.md`, keyed by the same rule numbers. A builder doesn't need it to follow a rule: read it when a rule is questioned, unclear or being changed. A rule with nothing behind it but its own text has no entry.

## How the rules are sourced

- These rules are guidance. A rule gives its source where that helps: developer.apple.com (documentation, the Human Interface Guidelines and WWDC sessions) or swift.org, or a first-party tool's own help output, for example `xcrun simctl help` or `xcodebuild -help`, cited as the command that prints it, with the Xcode version it was read on. A new rule needn't have a source, and the sources already given stay. Samples and blogs may illustrate a rule.
- Quoted words are copied exactly from the cited page. A rule claims no more than its source says; anything it adds is labelled **Framework choice**.
- A rule that settles something Apple leaves open, or that departs from Apple's guidance, is labelled **Framework choice**: a judgement call this reference makes, which a project departs from as `ios.md` says (How to read this reference). A rule isn't labelled only because it gives no source. Where Apple offers more than one current option, the Framework choice names the alternative, and a project that uses the alternative isn't departing from the rule, so it records no deviation.
- These are rules, not tutorials. Follow the source for detail.

## Assumes

The current stable toolchain on 2026-10-02: Xcode 27, with Swift 6.4 and the iOS 27 SDK ([Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)).

## 1. Project structure

**1.1.** Source: [Adding tests to your Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project#Overview).

**1.2.** Source: [App](https://developer.apple.com/documentation/swiftui/app), [App organization](https://developer.apple.com/documentation/swiftui/app-organization).

**1.3.** Source for the asset catalog: [Managing assets with asset catalogs](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs). The single Icon Composer file is a **Framework choice** between Apple's two current options ([Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer), [Adopting Liquid Glass: App icons](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass#App-icons)). The alternative is an app icon set in the asset catalog.

**1.4.** Source: [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog).

**1.5.** Source: [API Design Guidelines: Naming](https://www.swift.org/documentation/api-design-guidelines/#naming).

**1.6.** Source: [WWDC25: Embracing Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/268/), [Build settings reference: Default Actor Isolation](https://developer.apple.com/documentation/xcode/build-settings-reference#Default-Actor-Isolation).

**1.7.** **Framework choice**: the mode is opt-in ([Swift 6 migration guide](https://www.swift.org/migration/documentation/migrationguide/)). The alternative is Swift 5 mode with complete concurrency checking.

**1.8.** **Framework choice**: Apple doesn't prescribe a folder layout.

## 2. Architecture layers and state holders

**2.1.** Apple doesn't prescribe layers or a pattern such as MVVM. **Framework choice**: keep three parts. The alternative is views that read model data directly, as in Apple's samples, with no screen-level model. Context: Apple says a data model separates the data from the views, which "improves testability" ([Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app#Overview)).

**2.2.** Source: [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app#Make-model-data-observable), [Observation](https://developer.apple.com/documentation/observation).

**2.3.** Source: [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).

**2.4.** Source: [State: Share state with subviews](https://developer.apple.com/documentation/swiftui/state#Share-state-with-subviews), [Binding](https://developer.apple.com/documentation/swiftui/binding).

**2.5.** Source: [task(name:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(name:priority:file:line:_:)).

**2.6.** Source: [MainActor](https://developer.apple.com/documentation/swift/mainactor), [WWDC25: Embracing Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/268/).

**2.7.** Source: [VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema), [SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan). A `VersionedSchema` is "an interface for describing a specific version of a schema, including the models it contains", and a `SchemaMigrationPlan` is "an interface for describing the evolution of a schema and how to migrate between specific versions". **Framework choice** to version from the start. Apple doesn't document what SwiftData does with a store written by a later schema, or why a store won't open. On the iOS 27.0 Simulator, a store written by a later schema version opened without error under the earlier schema and its plan, and was migrated down, losing what the later version had added. A store whose main file wasn't a database threw only `SwiftDataError.loadIssueModelContainer`, with no underlying error. So a ticket that must keep such stores checks an existing store before opening it: Core Data's [`metadataForPersistentStore(type:at:options:)`](https://developer.apple.com/documentation/coredata/nspersistentstorecoordinator/metadataforpersistentstore(type:at:options:)) "returns the metadata of a specific type of persistent store at the provided location", and [`isConfiguration(withName:compatibleWithStoreMetadata:)`](https://developer.apple.com/documentation/coredata/nsmanagedobjectmodel/isconfiguration(withname:compatiblewithstoremetadata:)) checks it against each version in the plan. This check reads the store's metadata only, so damaged pages further in pass it, and the open then fails. The check is also a **Framework choice**.

## 3. Building UI

**3.1.** Source: [HIG: Components](https://developer.apple.com/design/human-interface-guidelines/components).

**3.2.** Source: [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass#Visual-refresh), [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials#Liquid-Glass).

**3.3.** Source: [HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color#Best-practices), [HIG: Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode#Dark-Mode-colors).

**3.4.** Source: [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text#Apply-a-font-supporting-dynamic-sizing), [custom(_:fixedSize:)](https://developer.apple.com/documentation/swiftui/font/custom(_:fixedsize:)) ("does not scale with Dynamic Type").

**3.5.** Source: [ScaledMetric](https://developer.apple.com/documentation/swiftui/scaledmetric), [Applying custom fonts to text: Scale padding using scaled metric](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text#Scale-padding-using-scaled-metric) ("a scaled value that changes automatically with accessibility settings").

**3.6.** **Framework choice** of mechanism; the API is at [Entry()](https://developer.apple.com/documentation/swiftui/entry()) and [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues). The alternative is a static constants type.

**3.7.** Source: [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle), [ViewModifier](https://developer.apple.com/documentation/swiftui/viewmodifier).

**3.8.** Source: [HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

**3.10.** **Framework choice**, based on an iOS 27.0 Simulator observation: accept stock SwiftUI behaviour unless the design source requires otherwise; a retained action needs a custom control or UIKit alternative and is a decision for the product owner. Source for the stock API: [swipeActions(edge:allowsFullSwipe:content:)](https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:).

## 4. Navigation and back behaviour

**4.1.** Source: [NavigationStack: Manage navigation state](https://developer.apple.com/documentation/swiftui/navigationstack#Manage-navigation-state), [navigationDestination(for:destination:)](https://developer.apple.com/documentation/swiftui/view/navigationdestination(for:destination:)), [NavigationView](https://developer.apple.com/documentation/swiftui/navigationview) ("Use NavigationStack and NavigationSplitView instead").

**4.2.** Source: [TabView](https://developer.apple.com/documentation/swiftui/tabview), [Tab](https://developer.apple.com/documentation/swiftui/tab), [HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars).

**4.3.** Source: [HIG: Toolbars, Navigation](https://developer.apple.com/design/human-interface-guidelines/toolbars#Navigation) ("Use the standard Back and Close buttons… If you create a custom version of either, make sure it still looks the same, behaves as people expect, and matches the rest of your interface"), [HIG: Designing for iOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios#Best-practices), [HIG: Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures#Custom-gestures).

**4.4.** Source: [HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets#iOS-iPadOS) ("The Done button dismisses a sheet after completing a task or explicitly saving changes"), [HIG: Modality](https://developer.apple.com/design/human-interface-guidelines/modality#Best-practices), [interactiveDismissDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)), [confirmationDialog(_:isPresented:titleVisibility:actions:)](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:)-87n66). **Framework choice, a known gap against the HIG.** The HIG asks for the confirmation when people begin swiping to dismiss a sheet with unsaved changes. SwiftUI before iOS 27 documents no way to detect that attempt, so under this rule the swipe simply stops. UIKit's [`presentationControllerDidAttemptToDismiss(_:)`](https://developer.apple.com/documentation/uikit/uiadaptivepresentationcontrollerdelegate/presentationcontrollerdidattempttodismiss(_:)) would close the gap, but `AGENTS.md` makes the UI SwiftUI, so this reference doesn't use it. iOS 27 adds [`dismissalConfirmationDialog(_:shouldPresent:actions:)`](https://developer.apple.com/documentation/swiftui/view/dismissalconfirmationdialog(_:shouldpresent:actions:)), whose page speaks of dismissing "the window for this view" and doesn't say whether that includes a sheet. It is untested here, and isn't part of this rule.

**4.5.** Source: [HIG: Modality](https://developer.apple.com/design/human-interface-guidelines/modality#Best-practices) ("Always give people an obvious way to dismiss a modal view"), [fullScreenCover(isPresented:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)), [AccessibilityActionKind.escape](https://developer.apple.com/documentation/swiftui/accessibilityactionkind/escape) ("dismisses a modal view or cancels an operation"). **Framework choice**: keeping the control on screen while the content scrolls.

## 5. Accessibility

**5.1.** Source: [HIG: Typography, Supporting Dynamic Type](https://developer.apple.com/design/human-interface-guidelines/typography#Supporting-Dynamic-Type).

**5.2.** Source: [HIG: Accessibility, Mobility](https://developer.apple.com/design/human-interface-guidelines/accessibility#Mobility).

**5.3.** Source: [View accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility), [Image init(decorative:bundle:)](https://developer.apple.com/documentation/swiftui/image/init(decorative:bundle:)) ("SwiftUI ignores this image for accessibility purposes"), [accessibilityElement(children:)](https://developer.apple.com/documentation/swiftui/view/accessibilityelement(children:)), [HIG: VoiceOver, Descriptions](https://developer.apple.com/design/human-interface-guidelines/voiceover#Descriptions). The label that says a clock time in words is a **Framework choice**, from a review where VoiceOver read a saved place as a time of day.

**5.4.** Source: [HIG: Accessibility, Vision](https://developer.apple.com/design/human-interface-guidelines/accessibility#Vision), [HIG: Color, Inclusive color](https://developer.apple.com/design/human-interface-guidelines/color#Inclusive-color).

**5.5.** Source: [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion), [HIG: Accessibility, Cognitive](https://developer.apple.com/design/human-interface-guidelines/accessibility#Cognitive).

**5.6.** **Framework choice** to require it; the API and its use are at [performAccessibilityAudit(for:_:)](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:)), [WWDC23: Perform accessibility audits for your app](https://developer.apple.com/videos/play/wwdc2023/10035/).

## 6. Unit testing

**6.1.** Source: [Swift Testing](https://developer.apple.com/documentation/testing), [Defining test functions](https://developer.apple.com/documentation/testing/definingtests), [Expectations and confirmations](https://developer.apple.com/documentation/testing/expectations), [WWDC24: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/).

**6.2.** Source: [Testing](https://developer.apple.com/documentation/xcode/testing) ("Xcode continues to include XCTest to facilitate writing UI tests"), [WWDC24: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/) ("continue using XCTest for … UI automation APIs … or performance testing APIs").

**6.3.** Source: [Testing](https://developer.apple.com/documentation/xcode/testing) (test pyramid), [Adding tests: Write a unit test](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project#Write-a-unit-test).

**6.4.** Source: [Implementing parameterized tests](https://developer.apple.com/documentation/testing/parameterizedtesting).

**6.5.** Source: [Testing asynchronous code](https://developer.apple.com/documentation/testing/testing-asynchronous-code#Confirm-that-an-event-happens).

**6.6.** Unit tests run inside the app: "The app process hosts the execution of your tests; tests are executed after receiving the applicationDidFinishLaunching notification" ([Running Tests and Viewing Results](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/05-running_tests.html), archived). That the ticket's pull request says how the tests keep away from the app's real data is a **Framework choice**.

**6.7.** **Framework choice**, from reviews where stubs passed and the store disagreed.

**6.8.** **Framework choice**.

**6.9.** **Framework choice**.

**6.10.** On the Simulator, a seed container released before the damage was written put the database's pages back over it. **Framework choice**; Apple doesn't document when a container checkpoints.

## 7. Command-line build

**7.1.** Source: [Running tests and interpreting results](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results#Run-tests-from-a-test-plan) (`xcodebuild test -scheme`), `xcodebuild -help` (`-destination`, "a comma-separated set of key=value pairs describing the destination to use"; Xcode 27), [TN2339: Building from the command line with Xcode](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) (the Simulator keys `name`, `id` and `OS`, in Table 3 and Listing 15; archived, but still Apple's only page for the keys).

**7.2.** Source: `xcrun simctl help list`, `xcrun simctl help create` and `xcrun simctl help getenv` (Xcode 27), and TN2339 for the `OS` and `id` keys (rule 7.1). **Framework choice** to record the device type, OS version and runtime build.

**7.3.** **Framework choice**.

**7.4.** Source: [Organizing tests to improve feedback: Run tests from the command line](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback#Run-tests-from-the-command-line).

**7.5.** **Framework choice**, from a review where the builder's tests all passed in an incremental build and the clean build of the test target failed.

**7.6.** Source: `xcrun xcresulttool help get test-results summary` and `xcodebuild -help` (Xcode 27). **Framework choice**, from sessions where a mistyped filter and a stale binary each reported success.

**7.7.** Source: `xcodebuild -help` (Xcode 27). **Framework choice**, the serial run from a review where a parallel run failed 16 of 284 tests, each from a 41-second stall, and the serial rerun passed them all.

## 8. Command-line Simulator screenshots

**8.1.** Apple documents `simctl` for starting simulated devices and points to `xcrun simctl help` for the rest ([Interacting with devices using the command line: Start simulated devices](https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line#Start-simulated-devices)). `install` and `launch` are in `xcrun simctl help install` and `xcrun simctl help launch` (Xcode 27). **Framework choice** between Apple's two command-line routes. Alternative: `devicectl device install app` and `devicectl device process launch` ([#Install-apps-on-devices](https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line#Install-apps-on-devices), [#Launch-apps-on-devices](https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line#Launch-apps-on-devices)). The launch section covers "a simulated or physical device", but neither the install section nor `xcrun devicectl help device install app` says that install works on a simulated device, so try it on one before relying on it.

**8.2.** Source: [Simulator User Guide: Taking a screenshot or recording a video using the command line](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/InteractingwiththeiOSSimulator/InteractingwiththeiOSSimulator.html) (retired guide), and `xcrun simctl help io` ("Save a screenshot of the booted device to screenshot.png: simctl io booted screenshot screenshot.png"; Xcode 27).

**8.3.** Source: [WWDC20: Become a Simulator expert](https://developer.apple.com/videos/play/wwdc2020/10647/).

**8.4.** Source: `xcrun simctl help ui` (`appearance [light | dark]` and `content_size`; Xcode 27). The relaunch after changing the text size is a **Framework choice**, and so is building in-memory state at the default text size and changing the text size while the test waits. Building the state at the largest accessibility size instead stalled the test on Xcode 27: with an alert's keyboard up, each step waited 60 seconds for app animations to finish. Apple documents the same settings in Device Hub ([Configuring the environment of a simulated device](https://developer.apple.com/documentation/xcode/configuring-the-environment-of-a-simulated-device)).

**8.5.** **Framework choice**. Source for the alternative, `XCTAttachment` screenshots from the UI test: [Adding attachments to tests, activities, and issues](https://developer.apple.com/documentation/xctest/adding-attachments-to-tests-activities-and-issues).

**8.6.** Source: [tap()](https://developer.apple.com/documentation/xcuiautomation/xcuielement/tap()), [typeText(_:)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/typetext(_:)), [waitForExistence(timeout:)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/waitforexistence(timeout:)), [swipeUp(velocity:)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/swipeup(velocity:)), [screenshot()](https://developer.apple.com/documentation/xcuiautomation/xcuiscreenshotproviding/screenshot()), [XCTAttachment init(screenshot:)](https://developer.apple.com/documentation/xctest/xctattachment/init(screenshot:)), [Attachment Lifetime](https://developer.apple.com/documentation/xctest/adding-attachments-to-tests-activities-and-issues#Attachment-Lifetime), `xcodebuild -help` (`-parallel-testing-enabled`, `-only-testing`) and `xcrun xcresulttool help export attachments` (Xcode 27). **Framework choice** of maintained stable scenarios and `-parallel-testing-enabled NO`, which keeps appearance/text-size/status-bar setup on the named device rather than a test clone.

**8.7.** The Simulator has no network of its own: "it has access to the computer's resources, including the CPU, memory, and network connection" ([Simulator User Guide: Testing and Debugging in Simulator](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/TestingontheiOSSimulator/TestingontheiOSSimulator.html), retired guide). **Framework choice**.

**8.8.** `booted` doesn't name a device: "If multiple devices are booted when the "booted" device is selected, simctl will choose one of them" (`xcrun simctl help`, Xcode 27). That `xcrun simctl create` prints the new device's UDID was seen on Xcode 27. Source: `xcrun simctl help` ("you may specify a device UDID or the special "booted" string"), `xcrun simctl help create` and `xcrun simctl help delete` (Xcode 27), and [Interacting with devices using the command line](https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line). **Framework choice** of one device per session.

## 9. Dependencies

**9.1.** **Framework choice**; for the route of adding a package with Swift Package Manager: [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#Add-a-package-dependency).

**9.2.** **Framework choice**; source: [Adding package dependencies to your app: Coordinate package versions across your team](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#Coordinate-package-versions-across-your-team). `Package.resolved` "lists the specific Git commits to which each package dependency resolves".

**9.3.** Source: [Managing model data in your app: Create the source of truth](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app#Create-the-source-of-truth-for-model-data) ("You can also create a state object in your top-level App instance"), [environment(_:)](https://developer.apple.com/documentation/swiftui/view/environment(_:)), [Environment: Get an observable object](https://developer.apple.com/documentation/swiftui/environment#Get-an-observable-object).

**9.4.** Source: [Adding tests: Write a unit test](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project#Write-a-unit-test) ("Replace complex dependencies with stubs"), [The Swift Programming Language: Protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/).
