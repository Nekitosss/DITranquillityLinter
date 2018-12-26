import Commandant
import Dispatch
import Foundation
import DITranquillityLinterFramework

DispatchQueue.global().async {
	let registry = CommandRegistry<CommandantError<()>>()
	registry.register(LintCommand())
	registry.register(HelpCommand(registry: registry))
	
	registry.main(defaultVerb: LintCommand().verb) { error in
		Log.error(String(describing: error))
	}
}

dispatchMain()
