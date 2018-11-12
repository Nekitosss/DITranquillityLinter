![License](https://img.shields.io/github/license/ivlevAstef/DITranquillity.svg?maxAge=2592000)

# DITranquillityLinter
Dependency graph validator for [DITranquillity](https://github.com/ivlevAstef/DITranquillity) library. Developed for compillation-time validation of DI-related code. Should be used in XCode target build phases step.

## Features
* iOS/macOS/tvOS platforms supporting

### Not implemented features
* Circular dependencies validation
* Several DI containers
* Containers in Unit tests

## Usage
* Add repository, using Cocoapods or Carthage.
* Move to build phases.

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/buildPhases.png)

* Add new 'Run Script' phase 

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/newRunScript.png)

* Add path to script in shell window

**Cocoapods:**

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/pathToScript.png)

**Carthage:**
Add path to script placed in framework bundle based on your target (iOS, macOS, tvOS)

![](https://github.com/Nekitosss/DITranquillityLinter/blob/feature/prepare-for-beta/Img/pathToScriptCarthage.png)

*Note:* at first launch of script or target change several heavy operations will be performed. Result will be cached and reused. **That heavy launch may take up to 3 minutes.** Keep calm and make yourself a coffee :)

## Known issues
* Nothing here yet...
