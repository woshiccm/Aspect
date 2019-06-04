
<p align="center"><img src ="./Images/aspect.png" /></p>


[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![badge-pms](https://img.shields.io/badge/languages-Swift-orange.svg)
[![Swift Version](https://img.shields.io/badge/Swift-4.0--5.0.x-F16D39.svg?style=flat)](https://developer.apple.com/swift)


Aspect is a lightweight, pure-Swift library for for aspect oriented programming. This project is heavily inspired by the popular [Aspects](https://github.com/steipete/Aspects). It provides you a chance to use a pure-Swift alternative in your next app.

## Features

- [x] Hook object selector
- [x] Provide a more friendly Swift interface

## Usage
### Hook object selector with OC block

```
public class Test: NSObject {
   @objc dynamic func test(id: Int, name: String) {
        print(id)
        print(name)
    }
}

let test = Test()

let wrappedBlock: @convention(block) (AspectInfo, Int, String) -> Void = { aspectInfo, id, name in

}
let block: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
test.hook(selector: #selector(Test.test(id:name:)), strategy: .before, block: )
```


### Hook object selector with Swift block

```
test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (aspectInfo: AspectInfo, id: Int, name: String) in

}

```


## Requirements

- iOS 8.0+
- Swift 4.0-5.x


## Next Steps


* Support hook class selector
* Improve detail
* Support Cocopods install


## Installation

#### Carthage
Add the following line to your [Cartfile](https://github.com/carthage/carthage)

```
git "https://github.com/woshiccm/Aspect.git" "master"
```



## Contributors




## Backers




### License

Aspect is released under the MIT license. See LICENSE for details.


