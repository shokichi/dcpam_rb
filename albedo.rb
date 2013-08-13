#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 絶対角運動量の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require '/home/ishioka/ruby/lib/utiles_spe'
include Utiles_spe
include NumRu
include Math



def albedo(dir,name)
  # 定数
  SolarConst = UNumeric[1366.0, "W.m-2"]

#  data_name = "Albedo"
  data_name = "RadSDWFLX"
  # file open
  begin
    osr = GPhys::IO.open(dir+"OSRA.nc","OSRA")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end

  hr_in_day = 24 / Utiles_spe.omega_ratio(name)

  # 計算
  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write(osr, ofile,'time') { 
    |sw|
    # 太陽直下点の計算
    time = hrs2day(sw,hr_in_day).to_gphys.val[0]
    slon = (time - time.to_i)*360
    slon = UNumeric[slon,"degree"]    # 太陽直下点経度

    # 大気上端下向きのSW
    tsw = sw[false,0].copy
#    tsw = sw.copy
    tsw[false] = -1.0
    tsw = tsw*SolarConst*((slon-tsw.axis("lon").to_gphys)*PI/180.0).cos
    tsw = tsw*(tsw.axis("lat").to_gphys*PI/180.0).cos
    # albedo
    albedo = sw.copy
    albedo.val = 1.0 + sw.val/tsw.val.abs
    albedo.name = data_name
    albedo.units = "1"
    albedo.long_name = "planetary albedo"
    [albedo]
  }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
end

def hrs2day(gp,hr_in_day)
  if gp.axis("time").pos.units.to_s != "hrs"
#    print "Time units: "
#    print gp.axis("time").units.to_s,"\n"
    return gp.axis("time")
  end
  time = gp.axis("time").pos / hr_in_day
  return gp.axis("time").set_pos(time) 
end

list = Utiles_spe::Explist.new(ARGV[0])
list.dir.each_index{|n| albedo(list.dir[n],list.name[n]) } 
