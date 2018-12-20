![License](https://img.shields.io/github/license/ivlevAstef/DITranquillity.svg?maxAge=2592000)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/DITranquillity.svg?style=flat)](http://cocoapods.org/pods/DITranquillity)
[![Swift Version](https://img.shields.io/badge/Swift-3.0--4.2-F16D39.svg?style=flat)](https://developer.apple.com/swift)

# DITranquillityLinter
Dependency graph validator for [DITranquillity](https://github.com/ivlevAstef/DITranquillity) library. Developed for compillation-time validation of DI-related code. Should be used in XCode target build phases step.

## Features
* iOS/macOS/tvOS platforms supporting

### Not implemented features
* Circular dependencies validation
* Several DI containers
* Containers in Unit tests
* Foundation types injection

## Usage
* Add repository, using Cocoapods or Carthage.
* Move to build phases.

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/buildPhases.png)

* Add new 'Run Script' phase 

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/newRunScript.png)

* Add path to script in shell window after compilation phase

**Cocoapods:**

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/pathToScript.png)

**Carthage:**
Add path to script placed in framework bundle based on your target (iOS, macOS, tvOS)

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/pathToScriptCarthage.png)

*Note:* at first launch of script or target change several heavy operations will be performed. Result will be cached and reused. **That heavy launch may take up to 3 minutes.** Keep calm and make yourself a coffee :)

### I've found a bug, or have a feature request
For runtime DI errors raise a main project [issue page](https://github.com/ivlevAstef/DITranquillity/issues).
For compilation time validation raise [GitHub issue](https://github.com/Nekitosss/DITranquillityLinter/issues). here.
**Important** Unfourtanently, for proper issue resolving we need your source code interface. For faster error resolving, plase send code directly in issue or send zipped failable code to patskovn@gmail.com with link to created issue. Your private code 100% will not be stored anywhere and will be deleted after issue will be resolved. Note, that method bodies (instead of DI code) are not nessessary and can be obfuscated or deleted.

### I've found a defect in documentation, or thought up how to improve it
Please help library development and create [pull requests](https://github.com/Nekitosss/DITranquillityLinter/pulls)

### Question?
You can feel free to ask the question at e-mail: 
ivlev.stef@gmail.com
patskovn@gmail.com
