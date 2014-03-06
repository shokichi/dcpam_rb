#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
=begin
    class Explist
      def initialize(file_list=nil)
      def create(name,dir)
      def refnum
      attr_reader :dir, :name, :legend,:id, :ref
---str_add(str,add_str)
---self.array2gp(x_var,y_var)  
    GPhysオブジェクトの簡単作成
---self.glmean(gp)  #
    全球平均
---self.latmean(gp)  #
    南北平均
---self.std_error(narray,blocknum=nil) # 
    標準偏差
---self.virtical_integral(gp)  #
    鉛直積分
---calc_press(ps,sig) #
---sig2press_save(dir,var_name) 
    鉛直座標変換(sig -> press)
---self.sig2press(gp,ps) # 
    鉛直座標変換(sig -> press)
---self.local_time(gphys,hr_in_day) #
---sub_sig2sigm(gp,sigm) #
---diff_sig(gp,sigm) #
---skip_num(gp,delnum) #
---skip_time(gp,skip,hr_in_day=24.0) #
---gpopen(file,name=nil)
=end

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/constants.rb")
include NumRu
include Math
include NMath
include ConstShk

module AnalyDCPAM
  module Utiles   
    class Explist
      # 実験ファイルリストの読み込み
      def initialize(file_list=nil)
        @@filelist = file_list
        if !file_list.nil? then
          read_file
          get_exp_id
        else
          default
        end
      end
      
      def create(legend,dir)
        @name = [name]
        @legend = [legend]
        @dir = [dir]
        self  
      end
      
      def refnum
        result = @name.index(@ref)
        return result
      end
      
      private
      
      def read_file
        begin
          fin = File.open(@@filelist,"r")
        rescue
          default
          error_msg
          return
        end
        parse_file(fin)
      end
      
      def parse_file(fin)
        name = []
        dir = []
        fin.each do |char|
          next if char[0..0] == "#" # コメントアウト機能
          char = char.chop.split(",")
          if char[0][0..0] == "!" # 基準実験
            char[0] = char[0].sub("!","")
            @ref = char[0]
          end    
          name << char[0]
          dir << char[1]
          dir << char[1].split(":") if char[1].include?(":") == true 
        end
        fin.close
        @dir = dir 
        @name = name
        @legend = name
      end
      
      def get_exp_id
        @id = @@filelist.split("/")[-1].sub(".list","")
      end
      
      def default
        @name = [""]
        @legend = [""] 
        @dir  = ["./"]
        @id  = "none"
        @ref = @legend
      end
      
      def error_msg
        print "[#{@@filelist}] No Such file \n"
        print "[#{@dir[0]}] Set current directory \n"
      end
      
      public  
      attr_reader :dir, :name, :legend,:id, :ref
    end  
    #----------------------
    def str_add(str,add_str)
      result = []
      if str.class == Array then
        str.each_index do |n|
          if add_str.class == Array then
            result[n] = str[n] + add_str[n]
          else
            result[n] = str[n] + add_str
          end
        end
      elsif add_str.class == Array and str.class != Array then
        add_str.each_index do |n|
          result[n] = str + add_str[n]
        end
      else
        result = str + add_str
      end
      return result
    end 
    #-----------------------
    def self.array2gp(x_var,y_var)  # GPhysオブジェクトの簡単作成
      x_coord = Axis.new
      x_coord.name = "x_coord"
      x_coord.set_pos(VArray.new( NArray.to_na(x_var)))
      grid = Grid.new(x_coord)
      gp = GPhys.new(grid,VArray.new( NArray.to_na(y_var)))
      gp.name = "y_coord"
      return gp
    end    
    #---------------------- 
    def self.glmean(gp)  # 全球平均
      return gp.mean(0) if !gp.axnames.include?("lat")
      cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
      fact = cos_phi / cos_phi.mean
      gp_mean = (gp * fact).mean("lon","lat")
      return gp_mean
    end
    #---------------------- 
    def self.latmean(gp)  # 南北平均
      cos_phi = ( gp.axis("lat").to_gphys * (Math::PI/180.0) ).cos
      fact = cos_phi / cos_phi.mean
      gp_mean = (gp * fact).mean("lat")
      return gp_mean
    end
    #------------------------
    def self.std_error(narray,blocknum=nil) # 標準偏差
      blocknum = narray.length if blocknum.nil?
      ave = narray.mean
      var = NArray.sfloat(blocknum)
      range1 = 0
      delrange = narray.length/blocknum
      
      for n in 0..blocknum-1 
        range2 = range1 + delrange.to_i
        var[n] = narray[range1..range2-1].mean
        range1 = range2
      end
      
      std = (((var-ave)**2).mean)**0.5
      return std
    end    
    #---------------------- 
    def self.local_time(gphys,hr_in_day)
      
      lon = gphys.axis('lon')
      local = lon.pos
      local = lon.pos*hr_in_day/360
      local.long_name = "local time"
      
      lon = lon.to_gphys
      local_time = lon.copy
      nlon = lon.length
      
      gp_local_converted = GPhys.each_along_dims(gphys,"time"){ |gp|
        nowtime = gp.axis("time").to_gphys
        gp_local = gp.copy
        # 時間の単位を[day]に変更
        nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
        nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
        # 日付が変わる経度を検出
        local_time.val = nowtime.val + lon.val/360
        local_time.val = (local_time.val - local_time.val.to_i)*hr_in_day
        local_min_index = local_time.val.to_a.index(local_time.val.min)
        # データの並び替え
        if local_min_index != 0 then
          gp_local[0..nlon-1-local_min_index,false].val = gp[local_min_index..-1,false].val
          gp_local[nlon-local_min_index..-1,false].val = gp[0..local_min_index-1,false].val
        end
        # lon -> localtime 変換
        gp_local.axis("lon").set_pos(local)
        return gp_local 
      } 
      return gp_local_converted
    end 
    # ---------------------------------------
    def mirror_lat(gp) # 折り返し(緯度)
      lat = gp.axis("lat").to_gphys
      if lat.max != -lat.min then
        print "Can not mirror [#{gp.name}]\n"
        return gp
      end
      mirror = gp.cut("lat"=>0..90).copy
      mirror[false] = 0
      (0..lat.length/2-1).each{|n|
        mirror.cut("lat"=>lat.val).val = 
        (gp.cut("lat"=>lat.val).val + gp.cut("lat"=>-lat.val).val)/2}  
      return mirror
    end
    # ---------------------------------------
    def omega_ratio(name)# 名前解析 nameからomega/omega_Eを抽出
      if name[0..4] == "omega" or name[0..4] == "Omega" then
        var = name.sub("omega","").sub("Omega","")
        if var.include?("-")
          var = var.split("-")
          var = var[1].to_f/var[0].to_f
        elsif var.include?("/")
          var = var.split("/") 
          var = var[0].to_f/var[1].to_f
        end
        ratio = var.to_f
      else
        print "ERROR: [#{name}] can't decode\n"
        ratio = 1.0
      end
      return ratio
    end
    # ---------------------------------------
    def gpopen(file,name=nil)
      name = File.basename(file,".nc").split("_")[-1] if name.nil?
      if defined?(Flag_rank) and Flag_rank == true then
        gp = gpopen_rank(file,name)
        gp = gpopen_nomal(file,name) if gp.nil?
      else
        gp = gpopen_nomal(file,name)
        gp = gpopen_rank(file,name) if gp.nil?
      end
      print "[#{name}](#{File.dirname(file)}) is not exist \n" if gp.nil?
      return gp
    end
    # ---------------------------------------
    def gpopen_nomal(file,name)
      begin
        gp = GPhys::IO.open file,name
      rescue
        gp = nil
      end
      return gp
    end
    # ---------------------------------------
    def gpopen_rank(file,name)
      begin
        if !file.include?(name)
          gp = GPhys::IO.open(file.sub(".nc","_rank000000.nc"), name)
        else
          gp = GPhys::IO.open(Dir.glob(file.sub(".nc","_rank*.nc")), name)     #<=読み込みに時間がかかりすぎる
        end
      rescue
        gp = nil
      end 
      return gp
    end
    # ---------------------------------------
  end
end
