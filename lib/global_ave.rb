#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
#
# require "/home/ishioka/ruby/dcpam_rb/lib/global_ave.rb"
# GlobalAverage::TableVal.new("omega_all_MTlocal_global-ave.dat")

require File.expand_path(File.dirname(__FILE__)+"/make_figure.rb")
include MKfig



module GlobalAverage
  class TableVal
    def initialize(list)
      @@list = list
      @data = {}
      @@refnum = list.refnum
    end

    def create(varlist)
      varlist.each do |varname|
        self.add(varname)
      end
      self
    end

    def load_file
      read_file
    end
    
    def add(varname)
      @data[varname] = global_dataset(varname)
    end

    def add_rotation_rate
      @data = @data.merge(rotation_rate(@@list))
    end

    def variable(varname)
      val = self.data[varname]
      result = []
      val.each_index do |n|
#        if val[n] == -999
#          result[n] = -999 
#        else
          result[n] = (val[n].to_f-val[@@refnum].to_f)/val[@@refnum].to_f
#        end
      end
      return result 
    end

    private
    def read_file
      File::open(@@file) do |f|
        f.each_line do |line|
          next if line.strip == -999
          parse_line(line.chop)
        end
      end
    end
    
    def write_file(file_path)
      File.open(file_path) do |file|
        print_header(file)
        @data.keys.each do |varname|
          file.print varname, "\t"
          file.print @data[varname].join("\t") ,"\n"
        end
      end
      puts "#{file_path} created\n"
    end
    
    def print_header(file)
      file.print <<-EOS
        ##########################
        # 全球平均値              
        ##########################
      EOS
    end

    def parse_line(line)
      line = line.split("\t")
      @data[line[0]] = line[1..-1]
    end    

    def global_dataset(varname) 
      ary = []
      @@list.dir.each do |dir|
        ary << global_mean_data(varname,dir)  
      end
      return ary
    end

    def rotation_rate(list) # 自転角速度
      omega = []
      list.name.each do |name|
        omega << Utiles_spe.omega_ratio(name)
      end
      return {"Rotaion"=>omega}
    end

    def global_mean_data(varname,dir)
      # データの取得
      gp = gpopen dir + varname +".nc"
      return "None" if gp.nil?
      
      # 大気最下層切り出し
      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
      gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")
      
      # 降水量の単位変換
      gp = Utiles_spe.wm2mmyr(gp) if varname.include? "Rain"
      
      # 全球平均
      result = Utiles_spe.glmean(gp) if gp.rank != 1  
      return result
    end  
    public

    attr_reader :data
  end
end
