import Foundation
import Testing
@testable @_spi(Backends) import SwiftCrossUI

@Suite("Windows wheel units")
struct WindowsScrollWheelTests {
    @Test(arguments: [Int32(-240), -121, -120, -119, -60, -40, -1, 0, 1, 40, 60, 119, 120, 121, 240])
    func verticalPacketsRetainFractionalNotches(_ raw: Int32) {
        let event = WindowsScrollWheel.event(
            rawDelta: raw, isHorizontal: false, location: .zero)
        #expect(event.deltaX == 0)
        #expect(event.deltaY == Double(raw) / 120)
        #expect(!event.isPrecise)
        #expect(event.phase == .changed)
    }

    @Test(arguments: [Int32(-120), -40, -1, 0, 1, 40, 120])
    func horizontalPacketsPreserveAxisAndSign(_ raw: Int32) {
        let event = WindowsScrollWheel.event(
            rawDelta: raw, isHorizontal: true, location: .zero)
        #expect(event.deltaX == Double(raw) / 120)
        #expect(event.deltaY == 0)
        #expect(!event.isPrecise)
    }

    @Test func packetSplittingDoesNotChangeConsumerResponse() {
        // A consumer must be able to distinguish points from notches without
        // assigning a different total movement to a device's packet sizes.
        func movement(_ packets: [Int32]) -> Double {
            packets.reduce(0) { sum, raw in
                let event = WindowsScrollWheel.event(
                    rawDelta: raw, isHorizontal: false, location: .zero)
                return sum + event.deltaY * (event.isPrecise ? 1 : 20)
            }
        }
        for packets: [Int32] in [
            [120], [60, 60], [40, 40, 40], [119, 1],
            [240, -120], [121, -1], Array(repeating: 1, count: 120),
        ] {
            #expect(abs(movement(packets) - movement([120])) < 1e-10)
            #expect(abs(movement(packets.map { -$0 }) - movement([-120])) < 1e-10)
        }
    }

    @Test func eventMetadataSurvivesNormalization() {
        let location = CGPoint(x: -123.5, y: 98.25)
        let time = Date(timeIntervalSince1970: 42)
        let modifiers: PointerModifiers = [.control, .shift, .option]
        let event = WindowsScrollWheel.event(
            rawDelta: 60, isHorizontal: false, location: location,
            modifiers: modifiers, time: time)
        #expect(event.location == location)
        #expect(event.modifiers == modifiers)
        #expect(event.time == time)
    }
}
