# A class for providing a slightly nicer terminal experience (including filename
# completion), as well as an each_line method

require 'readline'

class Interactive
    # Param:
    #   +save_file+:: a file to mirror all input commands to, nil
    #   means don't mirror
    def initialize(save_file = nil)
        @items = Queue.new

        puts "Please enter claim below."

        # Read items into queue ending with 'nil' poison
        # Mirror items to file if requested
        Thread.new do
            Readline.completion_proc = Readline::FILENAME_COMPLETION_PROC
            while line = Readline.readline('', true)
                @items.push line
                if not save_file.nil?
                    save_file.puts line
                end
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
