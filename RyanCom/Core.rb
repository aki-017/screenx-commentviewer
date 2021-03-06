module RyanCom
  @status="status"
  @channel="aki017"
  module Core
    def inits
      @inits ||= []
    end

    def init(&block)
      inits << block
    end

    def _init
      inits.each{|b|
        class_eval(&b)
      }
    end

    def comment(data)
      data.each do |d|
        dispatchEvent "comment",d
        write Comment.new(d["name"],d["message"])
      end
    end

    def viewer(data)
      data.each do |d|
        dispatchEvent "viewer",d
        @status="( #aki017 #{d["viewer"]} / #{d["total_viewer"]} )"

        print "\e[1F"
        print "\e[1M"
        write_status
        Readline.refresh_line
      end
    end


    def connect(c)
      uri = URI("http://screenx.tv")
      uri.port = 8800
      @c = SocketIO.connect( uri, {sync: true}) do
        before_start do
          on_message {|message| puts message}
          on_event('chat'){ |data| RyanCom::comment data}
          on_event('viewer'){ |data| RyanCom::viewer data}
          on_disconnect {puts "I GOT A DISCONNECT"}
        end

        after_start do
          emit("init", {channel: c})
        end

      end

      write Comment.new("System","#{c}に接続しました"),{:refresh=>false,:line=>0}
    end


    def start(channel)
      _init
      @channel = channel || @channel
      puts "ScreenX.tv Comment Viewer".center(detect_terminal_size()[0])
      puts "=" * detect_terminal_size()[0]
      write Comment.new("System","#{@channel}に接続します"),{:refresh=>false,:line=>0}
      connect @channel
      @token = get_token_and_chats


      trap("INT") { puts "end"; system "stty", stty_save; exit }
      while buf = Readline.readline("\e[48;5;247m\e[48;5;238m\e[38;5;254m" + "myname >\e[0m ")
        exit if(buf == "/q")
        post buf unless buf[0]==":"
        write Comment.new("System","#{buf}"),{:refresh=>false,:line=>2}
        if buf[0]==":" then
          begin
            comment [{"name"=>"System","message"=>eval(buf[1..-1])}]
          rescue => exc
            comment [{"name"=>"System","message"=>exc.inspect}]
          end
        end
        # post buf
      end
    end
  end

  extend Core
end
