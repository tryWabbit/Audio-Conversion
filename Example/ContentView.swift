//
//  ContentView.swift
//  Example
//
//  Created by Andrey on 20.11.2020.
//

import SwiftUI
import lame
import AudioToolbox
struct ContentView: View {

    @State var progress = ""

    var body: some View {
        VStack {
            Button("convert") {
                convertM4aToWav()
            }.padding()
            Text(progress)
                .padding()
        }
    }
    
    func convertM4aToWav() {
        let input = Bundle.main.path(forResource: "trimmed", ofType: "m4a")!
        let output = FileManager.default.temporaryFileURL(fileName: "\(UUID().uuidString).wav")!
        print(input)
        print(output)
        convertAudio(URL(string: input)!, outputURL: output)
        convert(input: output)
    }

    private func convert(input: URL) {
        //let input = Bundle.main.path(forResource: "file_example_WAV_10MG", ofType: "wav")!
        let output = FileManager.default.temporaryFileURL(fileName: "\(UUID().uuidString).mp3")!

        AudioConverter.encodeToMp3(
            inPcmPath: input.path,
            outMp3Path: output.path,
            onProgress: {
                progress = "Progress: \(Int(100 * $0))"
            }, onComplete: {
                print(output.path)
                progress = "Complete"
            })
    }
    
    
    
    func convertAudio(_ url: URL, outputURL: URL) {
        var error : OSStatus = noErr
        var destinationFile : ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil

        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()

        ExtAudioFileOpenURL(url as CFURL, &sourceFile)

        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))

        ExtAudioFileGetProperty(sourceFile!,
            kExtAudioFileProperty_FileDataFormat,
            &thePropertySize, &srcFormat)
        
        dstFormat.mSampleRate = 44100  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked |
        kAudioFormatFlagIsSignedInteger


        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileWAVEType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        reportError(error: error)

        error = ExtAudioFileSetProperty(sourceFile!,
                kExtAudioFileProperty_ClientDataFormat,
                thePropertySize,
                &dstFormat)
        reportError(error: error)

        error = ExtAudioFileSetProperty(destinationFile!,
                                         kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        reportError(error: error)

        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0

        while(true){
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: UInt32(srcBuffer.count),
                    mData: &srcBuffer
                )
            )
            var numFrames : UInt32 = 0

            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }

            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            reportError(error: error)

            if(numFrames == 0){
                error = noErr;
                break;
            }
            
            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            reportError(error: error)
        }
        
        error = ExtAudioFileDispose(destinationFile!)
        reportError(error: error)
        error = ExtAudioFileDispose(sourceFile!)
        reportError(error: error)
    }

    func reportError(error: OSStatus) {
        // Handle error
        print(error)
    }
}


extension FileManager {

    func temporaryFileURL(fileName: String = UUID().uuidString) -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
