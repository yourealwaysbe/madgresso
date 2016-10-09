# A class for providing a slightly nicer terminal experience (including filename
# completion), as well as an each_line method

require 'readline'

class Interactive
    def initialize
        @items = Queue.new

        puts "Please enter claim below."

        # Read items into queue ending with 'nil' poison
        Thread.new do
            Readline.completion_proc = Readline::FILENAME_COMPLETION_PROC
            while line = Readline.readline('', true)
                @items.push line
            end
            @items.push nil
        end
    end

    def each_line
        while line = @items.pop
            yield line
        end
    end
end
