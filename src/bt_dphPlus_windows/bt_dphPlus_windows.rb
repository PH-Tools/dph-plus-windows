=begin

Copyright 2019, bldgtyp, llc
All Rights Reserved

Permission to use, copy, modify, and distribute this software for
any purpose and without fee is hereby granted, provided that the above
copyright notice appear in all copies.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Name:         bt_dphPlus_windows.rb
Author:       Ed May, bldgtyp, llc, Updated by Sustainable Engineering Ltd NZ to work on any designPH version
Description:  DesignPH Window Component Colorizor
Usage:        menu Window → dPH+ Window
Version:      2.0.0
Date:         Oct 6, 2025

=end

require 'sketchup.rb'

module BT

	module DPH_Plus_windows
		
		mod = Sketchup.active_model
		ents = mod.entities
		sel = mod.selection
		defs = mod.definitions
		mats = mod.materials

		def self.is_number(input)
			#for quick test to see if a value is numeric or not
			#returns true if numeric, false if not
			return input.to_f.to_s == input.to_s || input.to_i.to_s == input.to_s
		end

		def self.percent_to_hex(percent, start, stop)
			# Example input: percent_to_hex(25, "abcdef", "ffffff") => "c0daf3"
			color_start = Sketchup::Color.new(start)
			color_stop = Sketchup::Color.new(stop)
			
			return color_start.blend(color_stop, percent).to_i
		end

		def self.getCSVdata(_defs)
			#Get the file path from the user
			filename = UI.openpanel("Select CSV file", "", "")

			#This gets 'mapping' info for the input CSV
			prompts = ["WinterColumn?", "SummerColumn?"]
			defaults = ["1", "2"]
			inputValue = UI.inputbox(prompts, defaults, "Map CSV (0 is the 'name' column)")
			heatingCSVcolumn = inputValue[0].chomp.to_i
			coolingCSVcolumn = inputValue[1].chomp.to_i

			#Read the input CSV file and make use of it
			f = File.new(filename, "r");
			lines = f.readlines(); #This makes an array of each line - each line comes in as a string
			f.close();

			#This part splits the imported lines into a hash for each window object
			imported_data_hash = {}
			lines.each { |r|
					line_array = []
					line_array = r.split(',')
					imported_data_hash[line_array[0]] = { "winter" => line_array[heatingCSVcolumn], "summer" => line_array[coolingCSVcolumn] }
					}

			#apply the new data to all the DesignPH window definitions in the scene
			puts "Applying the CSV data to the DesignPH window definitions..."
			addDataToCompos(_defs, imported_data_hash)
			puts 'success'
		end

		def self.addDataToCompos(_defs, _csvData)
			#used to find DesignPH windows and add net energy data to them
			#data comes from a CSV, output from the PHPP usually.
			
			#go through all the component definitions in the scene
			_defs.each do |d|
				if d.name.include? "designPH_Window_Simple" #do for only the DesignPH window component....
					d.instances.each do |i|  #for each instance of the window definition....
						begin
							#Set up the dynamic_attr dictionary with the net energy data from the CSV
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_access', 'VIEW')
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_label', 'netWinter') #Shows in 'Compo Attrbutes'
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_formlabel', 'Net kWh Lost: Winter') #Shows in 'Compo Options'
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_units', 'FLOAT')
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_formatversion', 1.0.to_f)
							i.definition.set_attribute('dynamic_attributes', '_netenergywinter_hasbehaviors', 1.0.to_f)
							i.definition.set_attribute('dynamic_attributes', 'netenergywinter', _csvData[i.name]['winter']) #actual value

							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_access', 'VIEW')
							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_label', 'netSummer') #Shows in 'Compo Attrbutes'
							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_formlabel', 'Net kWh Lost: Summer') #Shows in 'Compo Options'
							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_units', 'FLOAT')
							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_formatversion', 1.0.to_f)
							i.definition.set_attribute('dynamic_attributes', '_netenergysummer_hasbehaviors', 1.0.to_f)
							i.definition.set_attribute('dynamic_attributes', 'netenergysummer', _csvData[i.name]['summer']) #actual value
						
							puts " '#{d.name}::#{i.name}' definition edited successfully"
						rescue
							puts " '#{d.name}::#{i.name}' component not found, might be a ghost entity. #{d.count_instances} instance found in the active model"
						end
					end
				end
			end
				return "Added data to the DesignPH window component attribute dictionaries"
		end

		def self.colorWindows(_defs, _mats)
			#should add a check to see if there is data in the attr dictionary
			
			
			#creates a color ramp and apply colors to all window objects 
			
			########## SET SEASON TO DISPLAY ##########
			#Get user input for which season to display (or none)
			prompts = ["Select State:"]
			defaults = ["Default"]
			list = ["Default|Winter|Summer"]
			stateToDisplay = UI.inputbox(prompts, defaults, list, title="Select Season to View")[0]
			
			
			########## MATERIAL / COLOR SETUP ##########
			defaultColor = "ffffff"
			highColor = "ff0000"
			midColor = "ffffff"
			lowColor = "0061ff"

			#find if the designPH glass material if it exists and deletes it if so.
			#By removing, it'll apply the 'default' material to the glass so it can be colored correctly later
			begin
				#Note, Sketchup API says this will break if version < Sketchup 2014....
				_mats.remove("[Translucent_Glass_Blue]")
			rescue
				puts "No DesignPH 'Glass' material to delete."
			end
			
			#Create the color scale to use
			#pull out the winter and summer values from each of the DesignPH window objects in the scene
			winterValues = []
			summerValues = []
			begin
				_defs.each do |d|
					if d.name.include? "designPH_Window_Simple" #do for only the DesignPH window component....
						winterValues << d.get_attribute('dynamic_attributes', 'netenergywinter').to_f
						summerValues << d.get_attribute('dynamic_attributes', 'netenergysummer').to_f
					end
				end
			rescue
				puts 'Is not a DesignPH Component'
			end

			#Find the realtive scale of values in the CSV data
			winterMax = winterValues.max.abs
			summerMin = summerValues.min.abs
			
			########## USER DETERMINED SCALE TO USE ##########
			#Get user input for the scale to use to blend colors
			prompts = ["Winter(kWh):", "Summer(kWh):"]
			defaults = ["#{winterMax.round(2)}", "#{summerMin.round(2)}" ]
			input =  UI.inputbox(prompts, defaults, title="Set Max Value for Color Scale")   
			winterMax = input[0].to_f
			summerMin =  input[1].to_f	


			########## COLOR THE COMPOS ##########
			_defs.each do |d|
				if d.name.include? "designPH_Window_Simple" #do for only the DesignPH window component....
					begin
						#get the net energy value from the component and find its relative value compared to max / min
						winterVal = d.get_attribute('dynamic_attributes', 'netenergywinter').to_f
						summerVal = d.get_attribute('dynamic_attributes', 'netenergysummer').to_f 
						
						winterPercent = (winterVal / winterMax )
						summerPercent = (summerVal / summerMin )
						
						#Calc the % value for each window object and pass to the 'Percent to Hex' color function
						if winterPercent > 1
							winterColor = lowColor
						elsif winterPercent >= 0
							winterColor = percent_to_hex(winterPercent, lowColor, midColor)
						elsif winterPercent >= -1
							winterColor = percent_to_hex(winterPercent.abs, highColor, midColor)
						else
							winterColor = highColor
						end

						if summerPercent > 1
							summerColor = lowColor
						elsif summerPercent >= 0
							summerColor = percent_to_hex(summerPercent, lowColor, midColor)
						elsif summerPercent >= -1
							summerColor = percent_to_hex(summerPercent.abs, highColor, midColor)
						else
							summerColor = highColor
						end

						#applies the color to the window component instances
						d.instances.each do |i|
							puts i.material
							if stateToDisplay == "Winter"
									i.material = winterColor 
									#i.material.name = _mats.unique_name('Winter')
									puts "- Winter: " + "#{winterVal.round(1)} / #{winterMax} = #{winterPercent.round(2)}% " + winterColor.to_s
							elsif stateToDisplay == "Summer"
									i.material = summerColor
									#i.material.name = _mats.unique_name('Summer')
									puts "- Summer: " + "#{summerVal.round(1)} / #{summerMin} = #{summerPercent.round(2)}% " + summerColor.to_s
							elsif stateToDisplay == "Default"
									i.material = defaultColor
							end
						end
					rescue
						puts 'Something went wrong applying colors to the window instances.'
					end
				end
			end
			
			#Clear out all the old materials before finishing
			puts 'Clearing out old materials....'
			_mats.purge_unused
		end

		def self.removeMaterials(_defs, _mats)
			#Remove all materials from all the window objects
			_defs.each do |d|
				if d.name.include? "designPH_Window_Simple" #do for only the DesignPH window component....
					d.instances.each do |i|
						i.material = nil
					end
				end	
			end
			
			#Remove all the now unused materials
			puts _mats.length
			_mats.purge_unused
			puts _mats.length
		
		end

	end # module DPHPlus_windows

end # module BT

######---------------------########
##### UI and toolbar Stuff ########
######---------------------########

unless file_loaded?(__FILE__)
	# Commands
	cmd_load_CSV = UI::Command.new("Load Window CSV from PHPP")   		   { BT::DPH_Plus_windows.getCSVdata(Sketchup.active_model.definitions) }
	cmd_color_windows = UI::Command.new("Color Windows by Energy Balance") { BT::DPH_Plus_windows.colorWindows(Sketchup.active_model.definitions, Sketchup.active_model.materials) }
	cmd_remove_mats = UI::Command.new("Remove all Window Materials")       { BT::DPH_Plus_windows.removeMaterials(Sketchup.active_model.definitions, Sketchup.active_model.materials)  }

	# Menu
	new_menu = UI.menu("Window").add_submenu("dPH+ Windows")
	new_menu.add_item(cmd_load_CSV)
	new_menu.add_item(cmd_color_windows)
	new_menu.add_item(cmd_remove_mats)

	# Toolbar
	# ---none---

	file_loaded(__FILE__)
end