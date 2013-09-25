#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 絶対角運動量の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math

def albedo(dir,name)
  data_name = "Albedo"
  # file open
  osr = gpopen dir+"OSRA.nc"
  tsw = gpopen dir+"RadSDWFLXA.nc"
  return if osr.nil? or tsw.nil?


  if defined?(HrInDay) and !HrInDay.nil? then
    hr_in_day = HrInDay
  else
    hr_in_day = 24 / Utiles_spe.omega_ratio(name)
  end

  nlon = osr.axis("lon").length

#  if tsw.nil? then
    # 太陽直下点の計算
#    time = hrs2day(sw,hr_in_day).to_gphys.val[0]
#    slon = (time - time.to_i)*360
#    slon = 0  #
#    slon = UNumeric[slon,"degree"]    # 太陽直下点経度

    # 大気上端下向きのSW
#    tsw = osr[false,0].copy
#    tsw[false] = -1.0
#    tsw = tsw*SolarConst*((slon-tsw.axis("lon").to_gphys)*PI/180.0).cos
#    tsw = tsw*(tsw.axis("lat").to_gphys*PI/180.0).cos
#  tsw = tsw[nlon/4..nlon*3/4-1,true,-1,true]
#  else
  tsw = tsw.cut("sigm"=>0)

#  end

  # 計算
  ofile = NetCDF.create(dir + "local_" + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([osr,tsw], ofile,'time') { 
    |sw,top|

    # OSRの地方時変換
    sw = local_time(sw,hr_in_day)
    top = local_time(top,hr_in_day)
    sw = sw[nlon/4..nlon*3/4-1,false]
    top = top[nlon/4..nlon*3/4-1,false]
    
    # albedo
    albedo = 1.0 + sw/top
    albedo.name = data_name
    albedo.units = "1"
    albedo.long_name = "planetary albedo"
    [albedo]
  }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)
list = Utiles_spe::Explist.new(ARGV[0])

list.dir.each_index{|n| albedo(list.dir[n],list.name[n]) } 
