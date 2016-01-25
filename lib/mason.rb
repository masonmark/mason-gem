require 'mason/command_wrapper'

module Mason

  class Mason

    def install_ruby_on_this_mac
      brew = HomebrewWrapper

      doc = brew.doctor
        # If it says "Your system is ready to brew." then we are good

      update = brew.update
        # E.g.:
        #
        #   Updated Homebrew from 84d78f3 to de06b0b.
        #       ==> New Formulae
        #   xcv
        #   ==> Updated Formulae
        #   bazel                    gst-plugins-bad          gstreamer                privoxy
        #   dynamodb-local           gst-plugins-base         minimodem                pulseaudio
        #   efl                      gst-plugins-good         node-build               slackcat
        #   gst-libav                gst-plugins-ugly         nodenv                   sourcekitten

      install_rbenv




    end



    def boogie
      puts "Sorry, the boogie feature has been removed in this new version."
    end


  end
  
end
