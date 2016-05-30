# Internal class, for making CLI interactions testable.

module Mason

  class FakeInput

    def initialize(inputs = [])
      # The inputs param should be array of strings. '' means 'user just pressed Return '

      @enumerator = inputs.each
    end


    def next()
      # Return next input in the sequence, or nil if no more exist.

      begin
        "#{@enumerator.next}"
      rescue StopIteration
        nil
      end
    end

  end

end
