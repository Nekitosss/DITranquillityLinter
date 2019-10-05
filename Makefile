# Copyright Vadim Eisenberg 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

UNAME = ${shell uname}

# set EXECUTABLE_DIRECTORY according to your specific environment
# run swift build and see where the output executable is created

ifeq ($(UNAME), Darwin)
PLATFORM = x86_64-apple-macosx
EXECUTABLE_DIRECTORY = ./.build/${PLATFORM}/debug
TEST_RESOURCES_DIRECTORY = ./.build/${PLATFORM}/debug/DITranquillityLinterPackageTests.xctest/Contents/Resources
else ifeq ($(UNAME), Linux)
PLATFORM = x86_64-unknown-linux
EXECUTABLE_DIRECTORY = ./.build/${PLATFORM}/debug
TEST_RESOURCES_DIRECTORY = ${EXECUTABLE_DIRECTORY}
endif

RUN_RESOURCES_DIRECTORY = ${EXECUTABLE_DIRECTORY}

createBuildResources:
	carthage update --platform macOS
	rsync -a Carthage/Build TestFiles.bundle

build: copyRunResources
	swift build

copyRunResources:
	mkdir -p ${RUN_RESOURCES_DIRECTORY}
	cp -r TestFiles.bundle ${RUN_RESOURCES_DIRECTORY}

copyTestResources: createBuildResources
	mkdir -p ${TEST_RESOURCES_DIRECTORY}
	cp -r TestFiles.bundle ${TEST_RESOURCES_DIRECTORY}

run: build
	${EXECUTABLE_DIRECTORY}/ResourceHandlingSample

test: copyTestResources
	swift test

clean:
	rm -rf .build

.PHONY: run build test copyRunResources copyTestResources clean
