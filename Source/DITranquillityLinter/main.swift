import Commandant
import Dispatch
import DITranquillityLinterFramework
import DITranquillity

let container: DIContainer = {
	DISetting.Log.level = .info
	let container = DIContainer()
	container.append(part: LinterDIPart.self)
	container.register(LintCommand.init)
	container.register(EmitInfoCommand.init)
	container.register(ProjectFileExtractor.init)
	container.register(FileCollector.init)
	
	assert(container.validate(checkGraphCycles: true))
	
	return container
}()

DispatchQueue.global().async {
	let registry = CommandRegistry<CommandantError<()>>()
	let lintCommand: LintCommand = container.resolve()
	let emitInfoCommand: EmitInfoCommand = container.resolve()
	registry.register(lintCommand)
	registry.register(emitInfoCommand)
	registry.register(HelpCommand(registry: registry))
	
	registry.main(defaultVerb: lintCommand.verb) { error in
		Log.error(String(describing: error))
	}
}

dispatchMain()
