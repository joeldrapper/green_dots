# frozen_string_literal: true

module GreenDots::Matchers
	module ToReceive
		def to_receive(method_name, &expectation_block)
			__raise__ ::ArgumentError, "You can't use the `to_receive` matcher with a block expectation." if @block

			@result = "Expected #{@expression} to receive #{method_name}"

			interceptor = ::Module.new

			# Make these available from the block
			expectation = self
			context = @context

			interceptor.define_method(method_name) do |*args, **kwargs, &block|
				expectation.success!
				super_block = -> (*a, &b) { (a.length > 0) || b ? super(*a, &b) : super(*args, **kwargs, &block) }
				original_super = context.instance_variable_get(:@super)
				begin
					context.instance_variable_set(:@super, super_block)
					result = expectation_block&.call(*args, **kwargs, &block)
				ensure
					context.instance_variable_set(:@super, original_super)
				end

				interceptor.define_method(method_name) { |*a, **k, &b| super(*a, **k, &b) }
				result
			end

			@expression.singleton_class.prepend(interceptor)
		end
	end
end
