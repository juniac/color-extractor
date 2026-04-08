import Foundation

/// Color space conversion utilities
@available(macOS 13.0, iOS 16.0, *)
public struct ColorSpaceConverter {

    // MARK: - RGB to Linear RGB

    private static func sRGBToLinear(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }

    private static func linearToSRGB(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return value * 12.92
        }
        return 1.055 * pow(value, 1.0 / 2.4) - 0.055
    }

    // MARK: - RGB to XYZ (D65 illuminant)

    public static func rgbToXYZ(r: Double, g: Double, b: Double) -> (x: Double, y: Double, z: Double) {
        // Convert to linear RGB
        let rLinear = sRGBToLinear(r)
        let gLinear = sRGBToLinear(g)
        let bLinear = sRGBToLinear(b)

        // Convert to XYZ using D65 matrix
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041

        return (x, y, z)
    }

    // MARK: - XYZ to RGB

    public static func xyzToRGB(x: Double, y: Double, z: Double) -> (r: Double, g: Double, b: Double) {
        // Convert XYZ to linear RGB using D65 matrix inverse
        var r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
        var g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
        var b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

        // Convert to sRGB
        r = linearToSRGB(r)
        g = linearToSRGB(g)
        b = linearToSRGB(b)

        // Clamp values
        r = max(0, min(1, r))
        g = max(0, min(1, g))
        b = max(0, min(1, b))

        return (r, g, b)
    }

    // MARK: - XYZ to LAB

    private static func labFunction(_ t: Double) -> Double {
        let delta = 6.0 / 29.0
        if t > pow(delta, 3) {
            return pow(t, 1.0 / 3.0)
        }
        return t / (3 * delta * delta) + 4.0 / 29.0
    }

    private static func labFunctionInverse(_ t: Double) -> Double {
        let delta = 6.0 / 29.0
        if t > delta {
            return pow(t, 3)
        }
        return 3 * delta * delta * (t - 4.0 / 29.0)
    }

    public static func xyzToLAB(x: Double, y: Double, z: Double) -> (l: Double, a: Double, b: Double) {
        // D65 white point
        let xn = 0.95047
        let yn = 1.00000
        let zn = 1.08883

        let fx = labFunction(x / xn)
        let fy = labFunction(y / yn)
        let fz = labFunction(z / zn)

        let l = 116 * fy - 16
        let a = 500 * (fx - fy)
        let b = 200 * (fy - fz)

        return (l, a, b)
    }

    // MARK: - LAB to XYZ

    public static func labToXYZ(l: Double, a: Double, b: Double) -> (x: Double, y: Double, z: Double) {
        // D65 white point
        let xn = 0.95047
        let yn = 1.00000
        let zn = 1.08883

        let fy = (l + 16) / 116
        let fx = a / 500 + fy
        let fz = fy - b / 200

        let x = xn * labFunctionInverse(fx)
        let y = yn * labFunctionInverse(fy)
        let z = zn * labFunctionInverse(fz)

        return (x, y, z)
    }

    // MARK: - LAB to LCH

    public static func labToLCH(l: Double, a: Double, b: Double) -> (l: Double, c: Double, h: Double) {
        let c = sqrt(a * a + b * b)
        var h = atan2(b, a) * 180 / .pi
        if h < 0 {
            h += 360
        }
        return (l, c, h)
    }

    // MARK: - LCH to LAB

    public static func lchToLAB(l: Double, c: Double, h: Double) -> (l: Double, a: Double, b: Double) {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)
        return (l, a, b)
    }

    // MARK: - RGB to OKLAB

    public static func rgbToOKLAB(r: Double, g: Double, b: Double) -> (l: Double, a: Double, b: Double) {
        // Convert to linear RGB
        let rLinear = sRGBToLinear(r)
        let gLinear = sRGBToLinear(g)
        let bLinear = sRGBToLinear(b)

        // Convert to LMS using OKLAB matrix
        let l_ = 0.4122214708 * rLinear + 0.5363325363 * gLinear + 0.0514459929 * bLinear
        let m_ = 0.2119034982 * rLinear + 0.6806995451 * gLinear + 0.1073969566 * bLinear
        let s_ = 0.0883024619 * rLinear + 0.2817188376 * gLinear + 0.6299787005 * bLinear

        // Apply cube root
        let l = cbrt(l_)
        let m = cbrt(m_)
        let s = cbrt(s_)

        // Convert to OKLAB
        let L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

        return (L, a, b)
    }

    // MARK: - OKLAB to RGB

    public static func oklabToRGB(l: Double, a: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        // Convert OKLAB to LMS
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        // Cube the values
        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_

        // Convert to linear RGB
        var r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        var g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        var b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        // Convert to sRGB
        r = linearToSRGB(r)
        g = linearToSRGB(g)
        b = linearToSRGB(b)

        // Clamp values
        r = max(0, min(1, r))
        g = max(0, min(1, g))
        b = max(0, min(1, b))

        return (r, g, b)
    }

    // MARK: - OKLAB to OKLCH

    public static func oklabToOKLCH(l: Double, a: Double, b: Double) -> (l: Double, c: Double, h: Double) {
        let c = sqrt(a * a + b * b)
        var h = atan2(b, a) * 180 / .pi
        if h < 0 {
            h += 360
        }
        return (l, c, h)
    }

    // MARK: - OKLCH to OKLAB

    public static func oklchToOKLAB(l: Double, c: Double, h: Double) -> (l: Double, a: Double, b: Double) {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)
        return (l, a, b)
    }

    // MARK: - RGB to HWB

    public static func rgbToHWB(r: Double, g: Double, b: Double) -> (h: Double, w: Double, b: Double) {
        // First convert to HSL to get hue
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        var h: Double = 0

        if delta != 0 {
            if maxVal == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxVal == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h *= 60
            if h < 0 {
                h += 360
            }
        }

        let w = minVal
        let bl = 1 - maxVal

        return (h, w, bl)
    }

    // MARK: - HWB to RGB

    public static func hwbToRGB(h: Double, w: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        // Normalize whiteness and blackness
        var w = w
        var b = b
        let sum = w + b
        if sum > 1 {
            w /= sum
            b /= sum
        }

        // Convert hue to RGB
        let hue = h / 360
        let value = 1 - b

        let hi = Int(hue * 6)
        let f = hue * 6 - Double(hi)

        let v = value
        let n = w
        let k = v - (v - n) * f
        let j = v - (v - n) * (1 - f)

        switch hi % 6 {
        case 0: return (v, j, n)
        case 1: return (k, v, n)
        case 2: return (n, v, j)
        case 3: return (n, k, v)
        case 4: return (j, n, v)
        case 5: return (v, n, k)
        default: return (0, 0, 0)
        }
    }
}
