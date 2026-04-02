import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let baseURL = outputDirectory.appendingPathComponent("app-icon-base.png")

let size = CGSize(width: 1024, height: 1024)
let rect = CGRect(origin: .zero, size: size)

let image = NSImage(size: size)
image.lockFocus()

let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.16, alpha: 1.0),
    NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.10, alpha: 1.0)
])!
backgroundGradient.draw(in: rect, angle: -90)

let outerCircle = NSBezierPath(ovalIn: CGRect(x: 156, y: 156, width: 712, height: 712))
NSColor(calibratedRed: 0.23, green: 0.33, blue: 0.26, alpha: 0.9).setFill()
outerCircle.fill()

let innerCircle = NSBezierPath(ovalIn: CGRect(x: 220, y: 220, width: 584, height: 584))
NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.17, alpha: 0.95).setFill()
innerCircle.fill()

let configuration = NSImage.SymbolConfiguration(pointSize: 430, weight: .regular, scale: .large)
guard
    let symbolImage = NSImage(systemSymbolName: "figure.strengthtraining.traditional", accessibilityDescription: "LiftLog app icon")?
        .withSymbolConfiguration(configuration)
else {
    fputs("Failed to load SF Symbol.\n", stderr)
    exit(1)
}

let symbolBounds = CGRect(x: 212, y: 180, width: 600, height: 664)
let tintedSymbol = symbolImage.copy() as! NSImage
tintedSymbol.lockFocus()
NSColor(calibratedRed: 0.47, green: 0.89, blue: 0.58, alpha: 1.0).set()
NSRect(origin: .zero, size: tintedSymbol.size).fill(using: .sourceAtop)
tintedSymbol.unlockFocus()
tintedSymbol.draw(in: symbolBounds)

let glow = NSBezierPath(ovalIn: CGRect(x: 250, y: 250, width: 524, height: 524))
NSColor(calibratedRed: 0.47, green: 0.89, blue: 0.58, alpha: 0.08).setStroke()
glow.lineWidth = 18
glow.stroke()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to encode PNG.\n", stderr)
    exit(1)
}

try pngData.write(to: baseURL)
print(baseURL.path)
