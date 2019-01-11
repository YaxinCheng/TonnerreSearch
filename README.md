# TonnerreSearch ![icon](https://user-images.githubusercontent.com/13768613/41316616-35a65846-6e69-11e8-8687-d9f3b31fc921.png)

## Intro

A complete file indexing and search toolkit. Based on Apple's [SearchKit](https://developer.apple.com/documentation/coreservices/search_kit) and [File System Events](https://developer.apple.com/documentation/coreservices/file_system_events), TonnerreSearch provides a complete and concise way to build a **File Search Engine**. 

TonnerreSearch provides pure Swift interface, with C code running underneath it (from SearchKit and File System Events). It is the best way to combine the concise APIs and efficiency.

## Platform

- macOS (with Swift version after 4.0)
  - Tested on High Sierra and Mojave

## Installation

- Manually
  - git clone this repo, and compile. Then add the compiled `TonnerreSearch.framework` to your project
- Carthage
  - Add `github "YaxinCheng/TonnerreSearch"` to your *cartfile*
  - Run `carthage update`
  - After compiling, add the built `TonnerreSearch.framework` to your project

## Features

- Support aggregated search with keywords: `AND`, `OR`, and wildcard `*` 
- Fast for indexing and search
- Complementary indexing with listening to File System Events
- Light weighted

## User Manual:

Import `TonnerreSearch` in a file

```swift
import TonnerreSearch
```
### Index Part

This part introduces the basic index interfaces, and things need to be warned

#### TonnerreIndex.swift

Following APIs are provided:

```swift
static func create(path: String) throws -> TonnerreIndex
static func create(path: URL) throws -> TonnerreIndex
static func open(path: String, mode: OpenMode) throws -> TonnerreIndex
static func open(path: URL, mode: OpenMode) throws -> TonnerreIndex
func addDocument(atPath path: String, contentType: ContentType, additionalNote: String) throws -> Bool
func addDocument(atPath path: URL, contentType: ContentType, additionalNote: String) throws -> Bool
func removeDocument(atPath path: String) -> Bool
func removeDocument(atPath path: URL) -> Bool
func search(query: String, limit: Int, options: SearchOptions, timeLimit: Double) -> [URL]
```

When user firstly initialize an instance of `TonnerreIndex` with `create(path:)`, it creates an index file at the given `path`. If the path is missing, a fatal error will occur. The second time, with the same `path`, `TonnerreIndex` can initialize with the existing index file with `open(path:mode:)` function, instead of write over the original one.

> Note: one index file cannot have more than 1 writable instance. Otherwise, it will crash

Only **writable** instances can `addDocument` or `removeDocument` from the index file, however, `TonnerreIndex` is thread-safe. The search behaviour would not interfere the adding/removing process.

#### TonnerreIndex+Types.swift

```swift
// Used during a search, one or more options may be selected
public struct TonnerreSearchOptions: OptionSet {
    public static let `default`// Most default behaviour, space means AND, with relevance score
    public static let noRelevanceScore// Search without relevance score
    public static let spaceMeansOR// Space means OR instead of AND
    public static let findSimilar// Finds documents similar to the query, ignoring all search operators like AND OR
}
// A swifty wrapper for SKSearchOptions. For more details, see (https://developer.apple.com/documentation/coreservices/sksearchoptions)
```

```swift
// Open an existing index file
public enum OpenMode {
    case readOnly
    case writeAndRead
}
```

```swift
// Used when creaing an index
public enum ContentType {
  case fileName // index file only keeps file names as the index contents
  case fileContent // index file imports the content extractor from Spotlight, and keeps the document contents in the file
}
// Only one of them can be chosen
```

TonnerreIndexType.metadata uses the default spotlight extractor to read document contents, users have no control of how the content should be read or what should be read. 

> WARNING: Using metadata mode to load huge PDF files would consume a large amount of memory.

#### TonnerreIndexError.swift

Throw out an error when the file to index does not exist

```swift
public enum TonnerreIndexError: Error {
    case fileCreateError// occured during create method
    case fileOpenError// occured dur
    case fileNotExist(atPath: String)
}
```



### File System Event Part

This part introduces the File System Event Monitoring

#### TonnerreFSDetector.swift

An efficient way to listen to file events in the File System

```swift
typealias event = (path: String, flags: [TonnerreFSEvent])
convenience init(pathes: String..., callback: @escaping ([event])->Void)
init(pathes: [String], callback: @escaping ([event])->Void)
func start()
func stop()
```

Really straightforward, users need to pass a few path and a callback function to initialize one instance of `TonnerreFSDetector`. Once the `start()` is called, the detector starts to work. Once events happen, the detector calls the callback function, with a list of events. 

`stop()` will stop the detection

#### TonnerreFSEvent.swift

```swift
public struct TonnerreFSEvent: OptionSet {// Different types of File System Event
  public static let created       
  public static let removed       
  public static let inodeModified 
  public static let renamed       
  public static let modified      
  public static let finderModified
  public static let changeOwner   
  public static let XattrModified 
  public static let isFile        
  public static let isDirectory   
  public static let isSymlink     
}
```

## License

TonnerreSearch is released under the GPL license. See LICENSE for details.
