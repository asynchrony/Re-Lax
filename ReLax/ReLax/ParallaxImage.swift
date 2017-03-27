import Foundation
import CoreGraphics

public struct LCRLayerSource {
    public let origin: CGPoint
    public let image: CGImage
    
    public init(origin: CGPoint = CGPoint.zero, image: CGImage) {
        self.origin = origin
        self.image = image
    }
}

public struct ParallaxImage {
    private let layeredImage: LCRLayeredImage
    private let renditionCount: Int
    private let facetCount: Int
    private let carHeader: CARHeader
    
    public init(images: [UIImage]) {
        let layerSources = images.map { LCRLayerSource(image: $0.cgImage!) }
        let maxSize = images.reduce(CGSize.zero) { CGSize(width: max($0.width, $1.size.width), height: max($0.height, $1.size.height)) }
        self.init(layerSources: layerSources, size: maxSize)
    }
    
    public init(layerSources: [LCRLayerSource], size: CGSize) {
        layeredImage = LCRLayeredImage(layers: layerSources, size: size)
        renditionCount = 3 + layeredImage.layers.count // number of layers + flattened + radiosity + layeredImage?
        facetCount = 1 + layeredImage.layers.count // number of layers + layeredImage?
        carHeader = CARHeader(renditionCount: renditionCount)
    }
    
    public func image() -> UIImage? {
        return UIImage(data: imageData())
    }
    
    public func imageData() -> Data {
        let carHeaderData = carHeader.data()
        let (bomTreeIndex, facetsTree) = bomFacetsTree()
        let renditionsTree = bomRenditionsTree(bomTreeIndex)
        
        let imageLayerData = layeredImage.layerData()
        let imageData = imageLayerData.data
        let bomTableStart = try! Data(contentsOf: ReLaxResource.bomTableStart)
        
        let preImageData = concatData([bomHeader(carHeaderData.count + renditionsTree.count + facetsTree.count + imageData.count), carHeaderData, renditionsTree, facetsTree])

        let imageDataOffset = preImageData.count
        let bomEntries = imageLayerData.bomEntries.map { $0.byAddingOffset(additionalOffset: imageDataOffset) }
        
        let postImageData = concatData([bomTableStart, bomTable(bomEntries)])
        
        return concatData([preImageData, imageData, postImageData])
    }
    
    private func bomTable(_ layerEntries: [BomTableEntry]) -> Data {
        let unknown1 = byteSwappedInt32Data(0xAAA)
        let unknown2 = byteSwappedInt32Data(0)
        let unknown3 = byteSwappedInt32Data(0)
        let carHeaderEntry = BomTableEntry(offset: 0x200, length: 0x1B4)
        let renditionsTreeHeaderEntry = BomTableEntry(offset: 0x3B4, length: 0x15)
        let renditionsTreePayloadEntry = BomTableEntry(offset: 0x3C9, length: 0x1000)
        let facetsTreeHeaderEntry = BomTableEntry(offset: 0x13C9, length: 0x15)
        let facetsTreePayloadEntry = BomTableEntry(offset: 0x13DE, length: 0x1000)
        let keyFormatHeaderEntry = BomTableEntry(offset: 0x23DE, length: 0x44)
        
        let unknownEntries = [unknown1, unknown2, unknown3]
        let fixedEntries = [carHeaderEntry, renditionsTreeHeaderEntry, renditionsTreePayloadEntry, facetsTreeHeaderEntry, facetsTreePayloadEntry, keyFormatHeaderEntry]
        let tableEntryData = (fixedEntries + layerEntries).map { $0.data() }
        
        let tableData = concatData(unknownEntries + tableEntryData)
        
        return tableData.padded(count: 0x5568)
    }
    
    private func bomHeader(_ payloadLength: Int) -> Data {
        let bomHeaderSize = 512
        
        let bomstore = "BOMStore".data(using: String.Encoding.ascii)!
        let version = byteSwappedInt32Data(1) //(0x01000000)
        let numberOfNonNullBlocks = byteSwappedInt32Data(14 + layeredImage.layers.count * 4) // not entirely sure how many blocks there will be
        let indexOffset = byteSwappedInt32Data(61 + bomHeaderSize + payloadLength)
        let indexLength = byteSwappedInt32Data(0x5568)//length of index
        let varsOffset = byteSwappedInt32Data(bomHeaderSize + payloadLength)//length of all data before vars
        let varsLength = byteSwappedInt32Data(61)//length of vars
        
        return concatData([bomstore, version, numberOfNonNullBlocks, indexOffset, indexLength, varsOffset, varsLength]).padded(count: bomHeaderSize)
    }
    
    private func bomRenditionsTree(_ nextBomTableIndex: Int) -> Data {
        let tree = "tree".data(using: String.Encoding.ascii)!
        let version = byteSwappedInt32Data(1)
        let child = byteSwappedInt32Data(3) // index of renditions
        let blockSize = byteSwappedInt32Data(4096)
        let pathCount = byteSwappedInt32Data(renditionCount)
        let reservedByte = zeroPadding(1)
        
        let isLeaf = byteSwappedInt16Data(1)
        let count = byteSwappedInt16Data(renditionCount)
        let forwardBranch = byteSwappedInt32Data(0) // There are no branches in this tree
        let backwardBranch = byteSwappedInt32Data(0)
        
        var bomTableIndex = nextBomTableIndex
        let renditions: [Data] = (0..<renditionCount).map { _ in
            let renditionHeaderBOMTableIndex = byteSwappedInt32Data(bomTableIndex)
            let renditionPrefixBOMTableIndex = byteSwappedInt32Data(bomTableIndex - 1)
            bomTableIndex += 2
            return concatData([renditionHeaderBOMTableIndex, renditionPrefixBOMTableIndex])
        }
        
        let contents = concatData([isLeaf, count, forwardBranch, backwardBranch, concatData(renditions)])
        
        return concatData([tree, version, child, blockSize, pathCount, reservedByte, contents.padded(count: 4096)])
    }
    
    private func bomFacetsTree() -> (Int, Data) {
        let tree = "tree".data(using: String.Encoding.ascii)!
        let version = byteSwappedInt32Data(1)
        let child = byteSwappedInt32Data(5) // index of facets
        let blockSize = byteSwappedInt32Data(4096)
        let pathCount = byteSwappedInt32Data(facetCount)
        let reservedByte = zeroPadding(1)
        
        let isLeaf = byteSwappedInt16Data(1)
        let count = byteSwappedInt16Data(facetCount)
        let forwardBranch = byteSwappedInt32Data(0) // There are no branches in this tree
        let backwardBranch = byteSwappedInt32Data(0)
        
        var bomTableIndex = 0x08
        var facets: [Data] = (0..<facetCount).map { _ in
            let facetDataBOMTableIndex = byteSwappedInt32Data(bomTableIndex)
            let facetNameBOMTableIndex = byteSwappedInt32Data(bomTableIndex - 1)
            bomTableIndex += 2
            return concatData([facetDataBOMTableIndex, facetNameBOMTableIndex])
        }
        let firstNameAndData = facets.removeFirst()
        facets.append(firstNameAndData)
        
        let contents = concatData([isLeaf, count, forwardBranch, backwardBranch, concatData(facets)])
        
        return (bomTableIndex,  concatData([tree, version, child, blockSize, pathCount, reservedByte, contents.padded(count: 4096)]))
    }
}
