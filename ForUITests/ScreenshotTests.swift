import XCTest

final class ScreenshotTests: XCTestCase {

    let app = XCUIApplication()
    var screenshotDir: String {
        let subdir: String
        if let content = try? String(contentsOfFile: "/tmp/screenshot_subdir.txt", encoding: .utf8),
           !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subdir = content.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            subdir = "Screenshots"
        }
        return "/Users/sadygsadygov/Desktop/new_dom/For/\(subdir)"
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let data = screenshot.pngRepresentation
        let url = URL(fileURLWithPath: "\(screenshotDir)/\(name).png")
        try? data.write(to: url)
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        try? FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)

        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()
        sleep(3)
        saveScreenshot("01-onboarding-welcome")

        let letsGoBtn = app.buttons["Let's Go"]
        if letsGoBtn.waitForExistence(timeout: 3) {
            letsGoBtn.tap()
            sleep(2)
            saveScreenshot("02-onboarding-genres")

            let window = app.windows.firstMatch
            window.swipeUp()
            sleep(1)
            saveScreenshot("03-onboarding-genres-scroll")
        }

        app.terminate()
        app.launchArguments = ["-hasCompletedOnboarding", "YES"]
        app.launch()
        sleep(3)
        saveScreenshot("04-home-hero")

        let window = app.windows.firstMatch

        window.swipeUp()
        sleep(1)
        saveScreenshot("05-home-streak-cards")

        window.swipeDown()
        window.swipeDown()
        sleep(1)
        let addBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'plus'")).firstMatch
        if addBtn.waitForExistence(timeout: 3) {
            addBtn.tap()
            sleep(2)
            saveScreenshot("06-add-book-sheet")

            let titleField = app.textFields["Title"]
            if titleField.waitForExistence(timeout: 2) {
                titleField.tap()
                titleField.typeText("The Great Gatsby")
            }
            let authorField = app.textFields["Author"]
            if authorField.waitForExistence(timeout: 2) {
                authorField.tap()
                authorField.typeText("F. Scott Fitzgerald")
            }
            let pagesField = app.textFields["Total Pages"]
            if pagesField.waitForExistence(timeout: 2) {
                pagesField.tap()
                pagesField.typeText("180")
            }

            let readingSegment = app.buttons["Reading"]
            if readingSegment.waitForExistence(timeout: 2) {
                readingSegment.tap()
                sleep(1)
            }

            saveScreenshot("07-add-book-filled")

            let saveBtn = app.buttons["Save"]
            if saveBtn.waitForExistence(timeout: 2) {
                saveBtn.tap()
                sleep(3)
            }
        }

        saveScreenshot("08-home-with-book")

        let bookLink = app.staticTexts["The Great Gatsby"]
        if bookLink.waitForExistence(timeout: 3) {
            bookLink.tap()
            sleep(2)
            saveScreenshot("09-book-detail")

            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.waitForExistence(timeout: 2) {
                backBtn.tap()
                sleep(1)
            }
        }

        let libraryBtn = app.staticTexts["Library"]
        if libraryBtn.waitForExistence(timeout: 3) {
            libraryBtn.tap()
            sleep(2)
            saveScreenshot("10-library")
            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.waitForExistence(timeout: 2) {
                backBtn.tap()
                sleep(1)
            }
        }

        window.swipeUp()
        sleep(1)
        let statsBtn = app.staticTexts["Stats"]
        if statsBtn.waitForExistence(timeout: 3) {
            statsBtn.tap()
            sleep(2)
            saveScreenshot("11-stats")
            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.waitForExistence(timeout: 2) {
                backBtn.tap()
                sleep(1)
            }
        }

        let goalsBtn = app.staticTexts["Goals"]
        if goalsBtn.waitForExistence(timeout: 3) {
            goalsBtn.tap()
            sleep(2)
            saveScreenshot("12-goals")
            let backBtn = app.navigationBars.buttons.firstMatch
            if backBtn.waitForExistence(timeout: 2) {
                backBtn.tap()
                sleep(1)
            }
        }

        window.swipeDown()
        window.swipeDown()
        sleep(1)
        let settingsBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'gearshape' OR label CONTAINS[c] 'Settings'")).firstMatch
        if settingsBtn.waitForExistence(timeout: 3) {
            settingsBtn.tap()
            sleep(2)
            saveScreenshot("13-settings")
        }
    }
}
