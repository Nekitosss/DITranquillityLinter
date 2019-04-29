require 'xcodeproj'

path_to_project = "DITranquillityLinter.xcodeproj"
project = Xcodeproj::Project.open(path_to_project)
target = project.targets.select { |t| t.name == 'DITranquillityLinterTests' }.first
puts target.name
phase = target.new_copy_files_build_phase()
phase.dst_subfolder_spec = "16"

fileRef = project.new(Xcodeproj::Project::Object::PBXFileReference)
fileRef.path = 'TestFiles.bundle'

phase.add_file_reference(fileRef)
project.save