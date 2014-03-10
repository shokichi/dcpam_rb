#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# アルベドの計算
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/dcpam.rb")
include Utiles
include NumRu
include Math

def albedo(dir,name)
  data_name = "Albedo"
  # file open
  osr = gpopen(dir+"OSRA.nc")
  tsw = gpopen(dir+"RadSDWFLXA.nc")
  return if osr.nil? and tsw.nil?

  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles.omega_ratio(name)
  end

  nlon = osr.axis("lon").length

  # 計算
  ofile = NetCDF.create(dir + "local_" + data_name + '.nc')
  if tsw.nil? then
    GPhys::NetCDF_IO.each_along_dims_write(osr, ofile,'time') { 
      |sw|

      # 太陽直下点の計算
#      time = Utiles.min2day(sw,hr_in_day).axis("time").to_gphys
#      slon = (time - time.to_i)*360
#      slon = UNumeric[slon[0].val,"degree"]    # 太陽直下点経度
      slon = UNumeric[0,"degree"]    # 太陽直下点経度

      
      # 大気上端下向きのSW
      tsw = osr[false,0].copy
      tsw[false] = -1.0
      tsw.units = "1"
      tsw = tsw*SolarConst*((tsw.axis("lon").to_gphys+slon)*PI/180.0).cos
      tsw = tsw*(tsw.axis("lat").to_gphys*PI/180.0).cos
    
      # albedo
      sw = local_time(sw,hr_in_day)
      albedo = 1.0 + sw/(tsw+1e-10)
      albedo = albedo[nlon/4+1..nlon*3/4-2,false]
      albedo.name = data_name
      albedo.units = "1"
      albedo.long_name = "planetary albedo"
      [albedo]
    }
  else
    tsw = tsw.cut("sigm"=>0)
    GPhys::NetCDF_IO.each_along_dims_write([osr,tsw], ofile,'time') { 
      |sw,top|
      albedo = 1.0 + sw/(top+1e-10)
      albedo = local_time(albedo,hr_in_day)
      albedo = albedo[nlon/4+1..nlon*3/4-2,false]
      albedo.name = data_name
      albedo.units = "1"
      albedo.long_name = "planetary albedo"
      [albedo]
    }
  end
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)
list = Utiles::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis") && !defined? HrInDay

list.dir.each_index{|n| albedo(list.dir[n],list.name[n]) } 

