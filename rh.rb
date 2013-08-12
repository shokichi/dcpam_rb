#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 相対湿度の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math
include NMath

def calc_rh(dir) # 相対湿度の計算
  # file open
  data_name = 'RH'
  begin
    gqvap = gpopen(dir + "QVap.nc", "QVap")
    gps = gpopen(dir + "Ps.nc", "Ps")
    gtemp = gpopen(dir + "Temp.nc", "Temp")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end
  # 座標データの取得
  lon = gtemp.axis('lon')
  lat = gtemp.axis('lat')
  sig = gtemp.axis('sig').to_gphys

  # 定数設定
  grav = UNumeric[9.8, "m.s-2"]
  round = UNumeric[6400000.0, "m"]
  qvapmol = UNumeric[18.01528e-3, "kg.mol-1"]
  drymol =UNumeric[28.964e-3,"kg.mol-1"]
  p0 = UNumeric[1.4e+11,"Pa"]
  latheat = UNumeric[43655,"J.mol-1"]
  gasruniv = UNumeric[8.314,"J.K-1.mol-1"]

  es0 = UNumeric[611,"Pa"]
  latentheat = UNumeric[2.5e+6,"J.kg-1"]
  gasrwet = gasruniv / qvapmol
  epsv = qvapmol / drymol


  ofile = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqvap,gps,gtemp],ofile,'time'){ 
    |qvap,ps,temp|

    time = ps.axis('time')  
 
    # 気圧の計算
    press_na = NArray.sfloat(lon.length,lat.length,sig.length,time.length)
    grid = Grid.new(lon,lat,sig.axis('sig'),time)
    press = GPhys.new(grid,VArray.new(press_na))
    press.units = 'Pa'
    press[false] = 1.0
    
    press = press * ps
    press = press * sig
    
#    for k in 0..sig.length-1
#      press[false,k,true] = ps * sig[k].val
#    end

    # 飽和水蒸気圧の計算
    es = es0 * ( latentheat / gasrwet * ( 1/273.0 - 1/temp ) ).exp
  
    # 飽和非湿の計算
#    qvap_sat = epsv * (p0 / press) * (-latheat / (gasruniv * temp) ).exp

    # 水蒸気圧の計算
    e = qvap * press / epsv

    # 相対湿度の計算
    rh = e / es * 100 # [%]
#    rh = qvap / qvap_sat * 100 # [%]

    rh.units = '%'
    rh.long_name = 'relative humidity'
    rh.name = data_name  

    [rh]
    }
  ofile.close
  print "[#{data_name}](#{dir}) is created\n"
end

dir, name = Utiles_spe.explist(ARGV[0])
dir.each{|dir| calc_rh(dir)}


=begin
#p es_t.val
#p rh.max
#p rh2.max
#rh2 = GPhys.new(grid,VArray.new(rh2))
# DCL
DCL.gropn(1)
DCL.sgpset('lcntl',false)
DCL.uzfact(1.0)

#GGraph.tone e.mean(0,-1),true,'color_bar'=>true
GGraph.tone es.mean(0,-1),true,'color_bar'=>true#,'keep'=>true
#GGraph.tone press.mean(0,-1), true,'color_bar'=>true
GGraph.tone rh.mean(0,-1), true,'color_bar'=>true,'min'=>0,'max'=>100
DCL.grcls
=end
