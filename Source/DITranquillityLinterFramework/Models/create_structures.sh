cd /Users/nikita/development/DITranquillityLinter/Source/DITranquillityLinterFramework/Models
protoc --swift_out=. Models.proto
# mv *.swift `dirname $0`
