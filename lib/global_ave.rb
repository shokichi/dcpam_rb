#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
#

require File.expand_path(File.dirname(__FILE__)+"/make_figure.rb")
include MKfig


module GlobalAverage
  class GLmean
    def initialize(list=nil)
      if list.class == Explist
        @@list = list
      else
        @@list = Explist.new(list)
      end
      @data = {}
      @@units = {}
      @@long_name = {}
      @@refnum = @@list.refnum
    end

    def create(varlist)
      varlist = [varlist] if varlist.class != Array
      varlist.each do |varname|
        self.add(varname)
      end
      self
    end

    def load(file_path)
      @@infile = file_path
      read_file
      return self
    end

    def prints(file_path)
      @@outfile = file_path
      write_file
    end
    
    def add(varname)
      @data[varname] = global_dataset(varname)
    end

    def delete(varname)
      @data.delete(varname)
    end

    def set_axis(varname)
      @axis_name = varname
      @axis = @data[varname]
    end

    def [](arg)
      return @data[arg]
    end

    def []=(*arg)
      val = arg.pop
      key = arg[0]
      val = [val] if !val.class.to_s.include? "Array"
      @data[key] = val
    end

    def units_of(varname)
      return @@units[varname]
    end

    def units=(*arg)
      arg = arg[0]
      unit = arg.pop
      varname = arg[0]
      @@units[varname] = unit
    end

    def anomaly(varname)
      val = self.data[varname]
      result = []
      val.each_index do |n|
        if val[n] == -999
          result[n] = -999 
        else
          result[n] = (val[n].to_f-val[@@refnum].to_f)/val[@@refnum].to_f
        end
      end
      return result 
    end

    def to_gphys
      if !defined? @axis
        print "Axis is not defined."
        return
      end
      result = self.clone
      result.data.keys.each do |varname|
        result.data[varname] = convert_gphys(varname)
      end
      result.delete(@axis_name)
      return result
    end

    private
    def read_file
      File::open(@@infile) do |f|
        f.each_line do |line|
          next if line.strip == -999
          parse_line(line.chop)
        end
      end
    end
    
    def write_file
      File.open(@@outfile,"w") do |file|
        # print_header(file)
        @data.keys.each do |varname|
          varname += ","+@@units[varname] if !@@units[varname].nil?
          file.print varname, "\t"
          file.print @data[varname].join("\t") ,"\n"
        end
      end
      puts "#{@@outfile} created\n"
    end
    
    def print_header(file)
      file.print <<-EOS               
      EOS
    end

    def parse_line(line)
      line = line.split("\t")
      varname = line[0].split(",")[0]
      @@units[varname] = line[0].split(",")[1]   
      @data[varname] = ary_s2f(line[1..-1])
    end    

    def ary_s2f(ary)
      result = []
      ary.each do |s|
        result << s.to_f if !s.empty?
      end
      return result
    end

    def global_dataset(varname) 
      ary = []
      @@list.dir.each do |dir|
        ary << global_mean_data(varname,dir).to_f  
      end
      return ary
    end


    def global_mean_data(varname,dir)  
      gp = gpopen dir + varname +".nc"
      return -999.9 if gp.nil?

      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
      gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")

#      if defined? AngSolar && varname == "H2OLiqIntP"
#        gp = gp*cos_ang(gp)
#      end      

      if varname != "SurfTemp" && varname != "Albedo"
        gp = gp.mask_diurnal*mask_day_fix(gp) if defined? DayTime
        gp = gp.mask_night*mask_day_fix(gp) if defined? NightTime
      end
      gp = gp.wm2mmyr if varname.include? "Rain"
      @@units[varname] = gp.units
      @@long_name[varname] = gp.long_name
      
      gp = gp.glmean if gp.rank != 1
      return gp
    end

    def convert_gphys(varname)
      gp = Utiles.array2gp(@axis,@data[varname])
      axis = gp.axis(0).pos
      axis.name = @axis_name
      axis.long_name = @@long_name[@axis_name]
      axis.units = @@units[@axis_name]
      gp.axis(0).set_pos(axis)
      gp.name = varname
      gp.units = @@units[varname]
      gp.long_name = @@long_name[varname]
      return gp
    end
    public

    attr_reader :data, :axis, :axis_name
  end
  # -------------------------------------------------
  def mask_day_fix(gp) # for glmean
    nlon = gp.axis(0).length.to_f
    return nlon/(nlon/2+1)/2
  end
  
  def mask_night_fix(gp) # for glmean
    nlon = gp.axis(0).length.to_f
    return nlon/(nlon/2-1)/2    
  end
end


module GlobalAverage
  class GLmean

    def add_rotation_rate
      @data = @data.merge(rotation_rate(@@list))
      @@long_name["Rotation"] = "Normalized rotation rate"
    end

    def add_planetary_albedo
      @data = @data.merge(planetary_albedo)
      @@long_name["Albedo"] = "planetary albedo"
    end

    def add_greenhouse_effect
      @data = @data.merge(greenhouse_effect)
      @@long_name["Greenhouse"] = "greenhouse effect coef"
    end

    private
    def rotation_rate(list) # 自転角速度
      omega = []
      list.name.each do |name|
        omega << Utiles.omega_ratio(name)
      end
      return {"Rotation"=>omega}
    end

    def planetary_albedo
      alb = []
      @@list.dir.each do |dir|
        gp = gpopen dir + "OSRA.nc"
        alb << calc_planetary_albedo(gp)
      end
      return {"Albedo"=>alb}
    end

    def greenhouse_effect
      green = []
      @@list.dir.each do |dir|
        osr = gpopen dir + "OSRA.nc"
        stemp = gpopen dir + "SurfTemp.nc"
        green << calc_greenhouse_effect(osr,stemp)
      end
      return {"Greenhouse"=>green}
    end

  end
end
