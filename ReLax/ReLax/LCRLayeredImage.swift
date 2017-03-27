import Foundation
import CoreGraphics

enum LayerPrefix {
    case normal(index: Int)
    case flattened
    case radiosity
    
    func data() -> Data {
        let index: Int
        let type: Int
        
        switch self {
        case .normal(let layerIndex):
            index = layerIndex
            type = 0xB5
        case .flattened:
            index = 0
            type = 0xD0
        case .radiosity:
            index = 0
            type = 0xD1
        }
        
        let unknown1 = int16Data(0x55)
        let unknown2 = int16Data(type)
        let layerIndexData = int16Data(index)
        let unknown3 = int32Data(1)
        
        return concatData([unknown1, unknown2, zeroPadding(6), layerIndexData, zeroPadding(10), unknown3, zeroPadding(2)])
    }
}

struct BomTableEntry {
    let offset: Int
    let length: Int
    
    func byAddingOffset(additionalOffset: Int) -> BomTableEntry {
        return BomTableEntry(offset: offset + additionalOffset, length: length)
    }
    
    func data() -> Data {
        return concatData([byteSwappedInt32Data(offset), byteSwappedInt32Data(length)])
    }
}

struct LCRLayeredImage {
    let layers: [LCRLayer]
    private let imageName = "LayeredImage-" + uuidHexString()
    private let flattenedImage: LCRFlattenedRendition
    private let csiHeader: CoreStructuredImage

    init(layers: [LCRLayerSource], size: CGSize) {
        self.layers = layers.reversed().map { LCRLayer(layer: $0) }
        flattenedImage = LCRFlattenedRendition(images: self.layers, size: size)
        let csiImageSize = CGSize(width: self.layers[0].imageWidth, height: self.layers[0].imageHeight)
        csiHeader = CoreStructuredImage.layeredImage(imageName: imageName, imageSize: csiImageSize)
    }
    
    struct LayerData {
        let data: Data
        let bomEntries: [BomTableEntry]
    }
    
    func layerData() -> LayerData {
        var data = Data()
        var bomEntries = [BomTableEntry]()
        let tmfkFormatKeysData = tmfk()
        data.append(tmfkFormatKeysData.data)
        
        tmfkFormatKeysData.keys.forEach {
            bomEntries.append($0.nameEntry)
            bomEntries.append($0.dataEntry)
        }
        
        let layeredImagePrefix = concatData([int16Data(0x55), int16Data(0xB5), zeroPadding(18), int16Data(0x01), zeroPadding(4)])
        let prefix = BomTableEntry(offset: data.count, length: layeredImagePrefix.count)
        data.append(layeredImagePrefix)
        
        let ctsi = layeredImageCTSI()
        let dwar = "DWAR".data(using: String.Encoding.ascii)!
        let rawDataLength = int32Data(0)
        let preLayerData = concatData([ctsi, dwar, zeroPadding(4), rawDataLength])
        let dataEntry = BomTableEntry(offset: data.count, length: preLayerData.count)
        data.append(preLayerData)
        
        bomEntries.append(prefix)
        bomEntries.append(dataEntry)
        
        var layerIndex = 1
        layers.forEach {
            let prefix = LayerPrefix.normal(index: layerIndex).data()
            let prefixEntry = BomTableEntry(offset: data.count, length: prefix.count)
            data.append(prefix)
            
            let imageData = $0.data()
            let dataEntry = BomTableEntry(offset: data.count, length: imageData.count)
            data.append(imageData)
            
            bomEntries.append(prefixEntry)
            bomEntries.append(dataEntry)
            
            layerIndex += 1
        }
        
        let preFlattenedLayerData = LayerPrefix.flattened.data()
        bomEntries.append(BomTableEntry(offset: data.count, length: preFlattenedLayerData.count))
        data.append(preFlattenedLayerData)
        
        let flattenedImageData = flattenedImage.data()
        bomEntries.append(BomTableEntry(offset: data.count, length: flattenedImageData.count))
        data.append(flattenedImageData)

        let preRadiosityLayerData = LayerPrefix.radiosity.data()
        bomEntries.append(BomTableEntry(offset: data.count, length: preRadiosityLayerData.count))
        data.append(preRadiosityLayerData)
        
        let tempRadiosity = try! Data(contentsOf: ReLaxResource.radiosityURL)
        bomEntries.append(BomTableEntry(offset: data.count, length: tempRadiosity.count))
        data.append(tempRadiosity)
        
        // TODO: Generate Radiosity
        
        return LayerData(data: data, bomEntries: bomEntries)
    }
    
    private struct FormatKeyData {
        let data: Data
        let nameEntry: BomTableEntry
        let dataEntry: BomTableEntry
    }
    
    private struct FormatKeysData {
        let data: Data
        let prefixLength: Int
        let keys: [FormatKeyData]
    }
    
    private func tmfk() -> FormatKeysData {
        let tmfk = "tmfk".data(using: String.Encoding.ascii)!
        
        let tmfkPrefixData = try! Data(contentsOf: ReLaxResource.tmfkPrefixData)
        let prefixLength = tmfk.count + tmfkPrefixData.count
        var offset = prefixLength
        
        let lcrName = imageName.data(using: String.Encoding.ascii)!
        let nameEntry = BomTableEntry(offset: prefixLength, length: lcrName.count)
        offset += lcrName.count
        
        let tmfkLayerData = try! Data(contentsOf: ReLaxResource.tmfkLayerData)
        let lcrLayerIndex = int16Data(0)
        
        let dataEntry = BomTableEntry(offset: offset, length: tmfkLayerData.count + 2)
        offset += tmfkLayerData.count + 2
        
        let preLayerData = concatData([tmfk, tmfkPrefixData, lcrName, tmfkLayerData, lcrLayerIndex])
        let entry = FormatKeyData(data: preLayerData, nameEntry: nameEntry, dataEntry: dataEntry)
        
        var layerIndex = 1
        let layers: [FormatKeyData] = self.layers.map {
            let nameData = $0.imageName.data(using: String.Encoding.ascii)!
            let data = concatData([nameData, tmfkLayerData, int16Data(layerIndex)])
            let nameOffset = offset
            let nameLength = nameData.count
            offset += nameLength
            let layerDataOffset = offset
            let layerDataLength = tmfkLayerData.count + 2
            offset += layerDataLength
            
            layerIndex += 1
            return FormatKeyData(data: data, nameEntry: BomTableEntry(offset: nameOffset, length: nameLength), dataEntry: BomTableEntry(offset: layerDataOffset, length: layerDataLength))
        }
        
        let entries = [entry] + layers
        let data = concatData(entries.map { $0.data })
        
        return FormatKeysData(data: data, prefixLength: prefixLength, keys: entries)
    }
    
    private func layeredImageCTSI() -> Data {
        let structuredInfo = infoList()
        return concatData([csiHeader.data(structuredInfoDataLength: structuredInfo.count, payloadDataLength: 0), structuredInfo])
    }
    
    private func infoList() -> Data {
        return concatData([
            StructuredInfo.themeInformation(layers: layers).data(),
            StructuredInfo.composition.data(),
            StructuredInfo.universalTypeIdentifier(type: UTIType.layeredImage).data(),
            StructuredInfo.exifOrientation.data()
            ])
    }
}
