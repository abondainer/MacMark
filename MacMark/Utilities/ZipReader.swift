import Foundation
import Compression

/// Minimal ZIP file reader using Apple's Compression framework.
/// Reads individual entries from ZIP archives without external dependencies.
enum ZipReader {

    enum ZipError: Error {
        case fileNotFound
        case invalidArchive
        case decompressionFailed
    }

    /// Read a specific file entry from a ZIP archive.
    static func readFile(at zipURL: URL, entryName: String) throws -> Data {
        let fileData = try Data(contentsOf: zipURL)

        // Find the entry in the ZIP central directory
        guard let entry = findEntry(named: entryName, in: fileData) else {
            throw ZipError.fileNotFound
        }

        return try extractEntry(entry, from: fileData)
    }

    // MARK: - ZIP Structures

    private struct LocalFileHeader {
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let compressionMethod: UInt16
        let dataOffset: Int
    }

    private struct CentralDirectoryEntry {
        let fileName: String
        let localHeaderOffset: UInt32
    }

    // MARK: - Parsing

    private static func findEntry(named name: String, in data: Data) -> CentralDirectoryEntry? {
        // Find End of Central Directory (EOCD) record — search from end
        let eocdSignature: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        var eocdOffset = -1

        for i in stride(from: data.count - 22, through: max(0, data.count - 65557), by: -1) {
            if data[i] == eocdSignature[0] && data[i+1] == eocdSignature[1]
                && data[i+2] == eocdSignature[2] && data[i+3] == eocdSignature[3] {
                eocdOffset = i
                break
            }
        }

        guard eocdOffset >= 0 else { return nil }

        // Read central directory offset from EOCD
        let cdOffset = data.readUInt32(at: eocdOffset + 16)
        let cdEntryCount = data.readUInt16(at: eocdOffset + 10)

        // Walk central directory entries
        var offset = Int(cdOffset)
        for _ in 0..<cdEntryCount {
            guard offset + 46 <= data.count else { break }

            // Verify CD signature
            guard data[offset] == 0x50, data[offset+1] == 0x4B,
                  data[offset+2] == 0x01, data[offset+3] == 0x02 else { break }

            let nameLen = Int(data.readUInt16(at: offset + 28))
            let extraLen = Int(data.readUInt16(at: offset + 30))
            let commentLen = Int(data.readUInt16(at: offset + 32))
            let localHeaderOff = data.readUInt32(at: offset + 42)

            let nameData = data.subdata(in: (offset + 46)..<(offset + 46 + nameLen))
            let fileName = String(data: nameData, encoding: .utf8) ?? ""

            if fileName == name {
                return CentralDirectoryEntry(fileName: fileName, localHeaderOffset: localHeaderOff)
            }

            offset += 46 + nameLen + extraLen + commentLen
        }

        return nil
    }

    private static func extractEntry(_ entry: CentralDirectoryEntry, from data: Data) throws -> Data {
        let offset = Int(entry.localHeaderOffset)
        guard offset + 30 <= data.count else { throw ZipError.invalidArchive }

        // Verify local file header signature
        guard data[offset] == 0x50, data[offset+1] == 0x4B,
              data[offset+2] == 0x03, data[offset+3] == 0x04 else {
            throw ZipError.invalidArchive
        }

        let method = data.readUInt16(at: offset + 8)
        let compressedSize = Int(data.readUInt32(at: offset + 18))
        let uncompressedSize = Int(data.readUInt32(at: offset + 22))
        let nameLen = Int(data.readUInt16(at: offset + 26))
        let extraLen = Int(data.readUInt16(at: offset + 28))
        let dataStart = offset + 30 + nameLen + extraLen

        guard dataStart + compressedSize <= data.count else { throw ZipError.invalidArchive }

        let compressedData = data.subdata(in: dataStart..<(dataStart + compressedSize))

        switch method {
        case 0: // Stored (no compression)
            return compressedData
        case 8: // Deflate
            return try decompress(compressedData, uncompressedSize: uncompressedSize)
        default:
            throw ZipError.decompressionFailed
        }
    }

    private static func decompress(_ data: Data, uncompressedSize: Int) throws -> Data {
        let bufferSize = max(uncompressedSize, 65536)
        var decompressed = Data(count: bufferSize)

        let result = data.withUnsafeBytes { srcPtr -> Int in
            decompressed.withUnsafeMutableBytes { dstPtr -> Int in
                guard let src = srcPtr.baseAddress,
                      let dst = dstPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                return compression_decode_buffer(
                    dst, bufferSize,
                    src.assumingMemoryBound(to: UInt8.self), data.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }

        guard result > 0 else { throw ZipError.decompressionFailed }
        return decompressed.prefix(result)
    }
}

// MARK: - Data Helpers

private extension Data {
    func readUInt16(at offset: Int) -> UInt16 {
        var value: UInt16 = 0
        _ = Swift.withUnsafeMutableBytes(of: &value) { ptr in
            self.copyBytes(to: ptr, from: offset..<(offset + 2))
        }
        return UInt16(littleEndian: value)
    }

    func readUInt32(at offset: Int) -> UInt32 {
        var value: UInt32 = 0
        _ = Swift.withUnsafeMutableBytes(of: &value) { ptr in
            self.copyBytes(to: ptr, from: offset..<(offset + 4))
        }
        return UInt32(littleEndian: value)
    }
}
