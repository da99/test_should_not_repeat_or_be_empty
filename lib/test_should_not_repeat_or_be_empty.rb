
module Should_Not_Repeat
  
  def old_names
    @must_methods ||= {}
  end

  def should(name, &block)
    test_name = "test_#{name.gsub(/[^a-z0-9\_]+/i,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      super(test_name, &block)
      must_methods[test_name] = caller[0]
    else
      super(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end

end

class Test::Unit::TestCase
  
  extend Should_Not_Repeat
  
  # Used to fix a minor minitest/unit incompatibility in flexmock
  # AssertionFailedError = Class.new(StandardError)
  

  # Since I am not smart enough to figure out how to right a 
  # custom Test::Unit::UI to catch empty tests, the following 
  # hack will do.
  # The following will raise a RuntimeError if an empty test, ( do...end ),
  # is found. If there was an error or failure, it will *not*
  # raise a RuntimeError.
  alias :run_wo_raise_on_empty_test :run
  def run *args, &blok
    
    get_vals = lambda { |runner| [ runner.assertion_count, runner.error_count, runner.failure_count ] }
    orig     = get_vals.call(args.first)
    result   = run_wo_raise_on_empty_test(*args, &blok)
    latest   = get_vals.call(args.first)

    if orig == latest  
      msg = "Empty test: :#{method_name} in file: #{self.class.must_methods[method_name.to_sym]}"
      raise msg
    end
    
    result 
  end
  
end # ===
