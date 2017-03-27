import Foundation

func uint32Data(_ int: UInt) -> Data {
    let intData = UnsafeMutablePointer<UInt>.allocate(capacity: 4)
    defer {
        intData.deinitialize()
        intData.deallocate(capacity: 4)
    }
    intData.initialize(to: int)
    return Data(bytes: intData, count: 4)
}

func int32Data(_ int: Int) -> Data {
    let intData = UnsafeMutablePointer<Int>.allocate(capacity: 4)
    defer {
        intData.deinitialize()
        intData.deallocate(capacity: 4)
    }
    intData.initialize(to: int)
    return Data(bytes: intData, count: 4)
}

func byteSwappedInt32Data(_ int: Int) -> Data {
    let intData = UnsafeMutablePointer<UInt32>.allocate(capacity: 4)
    defer {
        intData.deinitialize()
        intData.deallocate(capacity: 4)
    }
    intData.initialize(to: UInt32(int).byteSwapped)
    return Data(bytes: intData, count: 4)
}

func byteSwappedInt16Data(_ int: Int) -> Data {
    let intData = UnsafeMutablePointer<UInt16>.allocate(capacity: 2)
    defer {
        intData.deinitialize()
        intData.deallocate(capacity: 2)
    }
    intData.initialize(to: UInt16(int).byteSwapped)
    return Data(bytes: intData, count: 2)
}

func int16Data(_ int: Int) -> Data {
    let intData = UnsafeMutablePointer<UInt16>.allocate(capacity: 2)
    defer {
        intData.deinitialize()
        intData.deallocate(capacity: 2)
    }
    intData.initialize(to: UInt16(int))
    return Data(bytes: intData, count: 2)
}

func zeroPadding(_ count: Int) -> Data {
    let data = calloc(count, 1)!
    defer {
        free(data)
    }
    return Data(bytes: data, count: count)
}

func concatData(_ data: [Data]) -> Data {
    var concatenatedData = Data()
    data.forEach { concatenatedData.append($0) }
    return concatenatedData
}

func uuidData() -> Data {
    let uuid = NSUUID()
    let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    defer {
        uuidBytes.deinitialize()
        uuidBytes.deallocate(capacity: 16)
    }
    uuid.getBytes(uuidBytes)
    let data = Data(bytes: uuidBytes, count: 16)
    return data
}

func uuidHexString() -> String {
    let uuid = uuidData()
    
    let byteArray = uuid.withUnsafeBytes {
        return [UInt8](UnsafeBufferPointer(start: $0, count: uuid.count/MemoryLayout<UInt8>.stride))
    }
    
    let hexString: String = byteArray.reduce("") {
        return $0 + String(format: "%02x", $1)
    }
    
    return hexString
}

extension String {
    func padded(count: Int) -> Data {
        return data(using: .ascii)!.padded(count: count)
    }
}

extension Data {
    func padded(count: Int) -> Data {
        var paddedData = Data(count: count)
        paddedData.replaceSubrange(Range(uncheckedBounds: (0, self.count)), with: self)
        return paddedData
    }
}
