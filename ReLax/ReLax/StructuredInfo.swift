import Foundation

enum UTIType: String {
    case layeredImage = "public.layeredimage"
}

enum CSIInfoMagic: Int {
    case sliceRects = 0x03E9
    case metrics = 0x03EB
    case composition = 0x03EC
    case utiType = 0x03ED
    case imageMetadata = 0x03EE
    case bytesPerRow = 0x03EF
    case internalReference = 0x03F2
    case alphaCropped = 0x03F3
    case themeInformation = 0x03F4
}

enum StructuredInfo {
    case slices(width: Int, height: Int)
    case metrics(width: Int, height: Int)
    case composition
    case exifOrientation
    case bytesPerRow(width: Int)
    case universalTypeIdentifier(type: UTIType)
    case themeInformation(layers: [LCRLayer])
    
    private var infoMagic: Int {
        switch self {
        case .slices(_, _):
            return CSIInfoMagic.sliceRects.rawValue
        case .metrics(_, _):
            return CSIInfoMagic.metrics.rawValue
        case .composition:
            return CSIInfoMagic.composition.rawValue
        case .exifOrientation:
            return CSIInfoMagic.imageMetadata.rawValue
        case .bytesPerRow(_):
            return CSIInfoMagic.bytesPerRow.rawValue
        case .universalTypeIdentifier(_):
            return CSIInfoMagic.utiType.rawValue
        case .themeInformation(_):
            return CSIInfoMagic.themeInformation.rawValue
        }
    }
    
    func data() -> Data {
        switch self {
        case .slices(let width, let height):
            let numberOfSlices = int32Data(1)
            let sliceX = int32Data(0)
            let sliceY = int32Data(0)
            return structuredInfo(with: [numberOfSlices, sliceX, sliceY, int32Data(width), int32Data(height)])
            
        case .metrics(let width, let height):
            let numberOfMetrics = int32Data(1)
            let topInset = int32Data(0)
            let rightInset = int32Data(0)
            let bottomInset = int32Data(0)
            let leftInset = int32Data(0)
            return structuredInfo(with: [numberOfMetrics, topInset, rightInset, bottomInset, leftInset, int32Data(width), int32Data(height)])
            
        case .composition:
            let blendMode = int32Data(0)
            let opacity = int32Data(0x3F800000) // 1.0
            return structuredInfo(with: [blendMode, opacity])
            
        case .exifOrientation:
            let orientation = int32Data(1)
            return structuredInfo(with: orientation)
            
        case .bytesPerRow(let width):
            let bytesPerRow = int32Data(width * 4)
            return structuredInfo(with: bytesPerRow)
        
        case .universalTypeIdentifier(let type):
            let utiLength = int32Data(0x14)
            return structuredInfo(with: [utiLength, zeroPadding(4), type.rawValue.data(using: String.Encoding.ascii)!, zeroPadding(1)])
        
        case .themeInformation(let layers):
            let layerCount = int32Data(layers.count)
            let random = uint32Data(0xED0DEC0D) // DEC0DED (identifier)
            var layerIndex = 1
            var layerInfoData = Data()
            layers.forEach {
                let x = int32Data(Int($0.imageRect.minX))
                let y = int32Data(Int($0.imageRect.minY))
                let width = int32Data($0.imageWidth)
                let height = int32Data($0.imageHeight)
                let padding1 = zeroPadding(6)
                let unknown1 = int16Data(0x3F80)
                let unknown2 = int32Data(0x14)
                let unknown3 = int16Data(0x01)
                let unknown4 = int16Data(0x55)
                let unknown5 = int16Data(0x02)
                let unknown6 = int16Data(0xB5)
                let unknown7 = int16Data(0x0C)
                let unknown8 = int16Data(0x01)
                let unknown9 = int16Data(0x11)
                let layerIndexData = int32Data(layerIndex)
                let padding2 = zeroPadding(2)
                layerIndex += 1
                
                layerInfoData.append(concatData([random, x, y, width, height, padding1, unknown1, unknown2, unknown3, unknown4, unknown5, unknown6, unknown7, unknown8, unknown9, layerIndexData, padding2]))
            }
            return structuredInfo(with: [layerCount, zeroPadding(4), layerInfoData])
        }
    }
    
    private func structuredInfo(with data: [Data]) -> Data {
        return structuredInfo(with: concatData(data))
    }
    
    private func structuredInfo(with data: Data) -> Data {
        let infoMagicSize = 4
        let infoMagicData = int32Data(infoMagic)
        
        var structuredInfoData = Data(capacity: infoMagicSize + data.count)
        structuredInfoData.append(infoMagicData)
        structuredInfoData.append(int32Data(data.count))
        structuredInfoData.append(data)
        return structuredInfoData
    }
}
