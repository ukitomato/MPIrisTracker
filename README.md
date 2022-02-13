MPIrisTracker
====
- An iOS Framework that enables developers to use iris detection & capturing face mesh based on [MediaPipe](https://mediapipe.dev/).

## Key Features
- enable to use [MediaPipe Iris Detection](https://google.github.io/mediapipe/solutions/iris.html) in Swift App
- Acquire iris tracking from front camera image
    - face mesh
    - iris landmark

## Example Projects
To try the example project, simply clone this repository and open the `examples` folder 

### Develop Environment
- Language: [Swift](https://developer.apple.com/jp/swift/)
- Xcode: Xcode version 12.5
- Using Libralies:
  - MPIrisTracker
  - [Resolver](https://github.com/hmlongco/Resolver) for DI
 
## Get Started
### Installation

1. Add `MPIrisTracker.framwork` in `./output` folder to your App Xcode Project on Xcode.
2. In Xcode, select File > New > File...
3. Create temporary Objective-C File (this file will be deleted after creating bridging header file).
4. (Xcode automatically creates `xxx-Bridging-Header.h`)
5. Append `#import <MPIrisTracker/MPIrisTracker.h>` into `xxx-Bridging-Header.h`
6. (if needed) Select `Embed & Sign` at MPIrisTracker.framework
    <details>
    <img width="1245" alt="スクリーンショット 2021-06-01 22 01 44" src="https://user-images.githubusercontent.com/20383656/120327724-08932780-c325-11eb-8a3e-454dc398baf3.png">
7. (if needed) Select `No` at Enable Bitcode
    <details>
    <img width="1247" alt="スクリーンショット 2021-06-01 22 04 27" src="https://user-images.githubusercontent.com/20383656/120328010-59a31b80-c325-11eb-8477-a64072fbd81f.png">


### Permission Settings
1. Make sure you add the usage description of the `camera` in the app's `Info.plist`.
```
<key>NSCameraUsageDescription</key>
<string>MPIrisTracker</string>
```

## How to compile framework
### Install MediaPipe
1. Follow [official MediaPipe documents](https://google.github.io/mediapipe/getting_started/install.html)

### Compile
1. Copy files in `./source` folder to MediaPipe installation path (e.g. `MEDIAPIPE_PATH`/mediapipe/MPIrisTracker/).
2. `cd MEDIAPIPE_PATH`
3. `bazel build -c opt --config=ios_arm64 mediapipe/MPIrisTracker:MPIrisTracker`

## Reference
- [MediaPipe](https://google.github.io/mediapipe/)

## Licence
[MIT](https://github.com/ukitomato/MPIrisTracker/blob/master/LICENSE)

## Author
Yuki Yamato [[ukitomato](https://github.com/ukitomato)]
