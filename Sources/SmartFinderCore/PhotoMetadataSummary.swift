import Foundation

public struct PhotoMetadataSummary: Equatable, Sendable {
    public let captureDate: String?
    public let camera: String?
    public let lens: String?
    public let pixelDimensions: String?
    public let resolution: String?
    public let iso: String?
    public let focalLength: String?
    public let aperture: String?
    public let shutterSpeed: String?
    public let exposureCompensation: String?
    public let whiteBalance: String?
    public let colorSpace: String?
    public let gpsCoordinate: String?
    public let mapsURL: URL?

    public init(properties: [String: Any]) {
        let tiff = properties["{TIFF}"] as? [String: Any] ?? [:]
        let exif = properties["{Exif}"] as? [String: Any] ?? [:]
        let gps = properties["{GPS}"] as? [String: Any] ?? [:]

        captureDate = [
            Self.stringValue(exif["DateTimeOriginal"]),
            Self.stringValue(exif["DateTimeDigitized"]),
            Self.stringValue(tiff["DateTime"])
        ]
        .compactMap { $0?.nilIfEmpty }
        .first

        let make = Self.stringValue(tiff["Make"])
        let model = Self.stringValue(tiff["Model"])
        camera = [make, model]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .nilIfEmpty

        lens = Self.stringValue(exif["LensModel"])?.nilIfEmpty

        if let width = Self.integerValue(properties["PixelWidth"]),
           let height = Self.integerValue(properties["PixelHeight"]) {
            pixelDimensions = "\(width) x \(height)"
        } else {
            pixelDimensions = nil
        }

        if let xResolution = Self.doubleValue(tiff["XResolution"]),
           let yResolution = Self.doubleValue(tiff["YResolution"]) {
            resolution = "\(Self.shortNumber(xResolution)) x \(Self.shortNumber(yResolution)) dpi"
        } else {
            resolution = nil
        }

        if let isoValue = Self.isoValue(exif["ISOSpeedRatings"]) {
            iso = "ISO \(isoValue)"
        } else {
            iso = nil
        }

        if let value = Self.doubleValue(exif["FocalLength"]) {
            focalLength = "\(Self.shortNumber(value)) mm"
        } else {
            focalLength = nil
        }

        if let value = Self.doubleValue(exif["FNumber"]) {
            aperture = "f/\(Self.shortNumber(value))"
        } else {
            aperture = nil
        }

        if let exposureTime = Self.doubleValue(exif["ExposureTime"]) {
            shutterSpeed = Self.shutterSpeedString(for: exposureTime)
        } else {
            shutterSpeed = nil
        }

        if let value = Self.doubleValue(exif["ExposureBiasValue"]) {
            exposureCompensation = "\(Self.signedShortNumber(value)) EV"
        } else {
            exposureCompensation = nil
        }

        if let value = Self.integerValue(exif["WhiteBalance"]) {
            switch value {
            case 0:
                whiteBalance = "Auto"
            case 1:
                whiteBalance = "Manual"
            default:
                whiteBalance = nil
            }
        } else {
            whiteBalance = nil
        }

        if let value = Self.integerValue(exif["ColorSpace"]) {
            switch value {
            case 1:
                colorSpace = "sRGB"
            case 65535:
                colorSpace = "Uncalibrated"
            default:
                colorSpace = nil
            }
        } else {
            colorSpace = Self.stringValue(properties["ProfileName"])?.nilIfEmpty
        }

        if let coordinate = Self.gpsCoordinate(from: gps) {
            gpsCoordinate = Self.coordinateString(latitude: coordinate.latitude, longitude: coordinate.longitude)
            mapsURL = URL(string: "http://maps.apple.com/?ll=\(Self.coordinateURLString(latitude: coordinate.latitude, longitude: coordinate.longitude))")
        } else {
            gpsCoordinate = nil
            mapsURL = nil
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        value as? String
    }

    private static func integerValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }
        if let value = value as? NSNumber {
            return value.doubleValue
        }
        return nil
    }

    private static func isoValue(_ value: Any?) -> Int? {
        if let values = value as? [Int] {
            return values.first
        }
        if let values = value as? [NSNumber] {
            return values.first?.intValue
        }
        return integerValue(value)
    }

    private static func shortNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private static func signedShortNumber(_ value: Double) -> String {
        let formatted = shortNumber(value)
        return value > 0 ? "+\(formatted)" : formatted
    }

    private static func shutterSpeedString(for exposureTime: Double) -> String {
        guard exposureTime > 0 else {
            return ""
        }
        if exposureTime < 1 {
            let denominator = Int((1 / exposureTime).rounded())
            return "1/\(denominator) s"
        }
        return "\(shortNumber(exposureTime)) s"
    }

    private static func gpsCoordinate(from gps: [String: Any]) -> (latitude: Double, longitude: Double)? {
        guard
            var latitude = doubleValue(gps["Latitude"]),
            var longitude = doubleValue(gps["Longitude"])
        else {
            return nil
        }

        if stringValue(gps["LatitudeRef"])?.uppercased() == "S" {
            latitude *= -1
        }
        if stringValue(gps["LongitudeRef"])?.uppercased() == "W" {
            longitude *= -1
        }

        return (latitude, longitude)
    }

    private static func coordinateString(latitude: Double, longitude: Double) -> String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }

    private static func coordinateURLString(latitude: Double, longitude: Double) -> String {
        String(format: "%.6f,%.6f", latitude, longitude)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
