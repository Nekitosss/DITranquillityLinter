
import Foundation
import DITranquillity


public final class LinterDIPart: DIPart {
	
	public static func load(container: DIContainer) {
		container.register(DependencyTokenCacher.init)
		container.register(FileContainer.init)
		container.register(ResultCacher.init)
		container.register1(ImplicitFrameworkDependencyTypesResolver.init)
		container.register(TypeFinder.init)
		container.register(BinaryFrameworkParser.init)
		container.register(Composer.init)
		container.register(ModuleParser.init)
		container.register { TimeRecorder.common }
		container.register(Tokenizer.init)
		container.register(ContainerInfoEmitter.init)
		container.register(GraphValidator.init)
		container.register(JSONEncoder.init)
		container.register(JSONDecoder.init)
    container.register1(ASTEmitter.init)
		
		// isTestEnvironment
		container.register { false }
	}
}
