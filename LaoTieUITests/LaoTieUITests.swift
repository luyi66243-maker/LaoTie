import XCTest

@MainActor
final class LaoTieUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testLaunchScreenAppears() throws {
        // The app should show either the launch screen or login view
        let exists = app.staticTexts["唠嗑小馆"].waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "App title should appear on launch")
    }
}
