# Load support files.
require 'sketchup.rb'
require 'extensions.rb'

module BT

    module DPH_Plus_windows
    # Info
      EXTVERSION            = "2"
      EXTTITLE              = "dPH+ Windows"
      EXTNAME               = "bt_dphPlus_windows"
      EXTDESCRIPTION        = "Allows you to apply color gradient to Design PH windows based on window net energy from PHPP model"
      
      @extdir = File.dirname(__FILE__)
      @extdir.force_encoding('UTF-8') if @extdir.respond_to?(:force_encoding)
      EXTDIR = @extdir
      
      loader = File.join( EXTDIR , EXTNAME , "bt_dphPlus_windows.rb" )
      puts loader
      # Create extension
      extension             = SketchupExtension.new( EXTTITLE , loader )
      extension.copyright   = "Copyright 2019-#{Time.now.year} Ed May"
      extension.creator     = "Ed May, bldgtyp, llc, Updated by Sustainable Engineering Ltd NZ to work on any designPH version"
      extension.version     = EXTVERSION
      extension.description = EXTDESCRIPTION
      
      Sketchup.register_extension( extension , true )
           
    end  # module DPH+Windows
    
  end  # module BT