#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 相対湿度の計算
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math
include NMath

def calc_rh(dir) # 相対湿度の計算
  # file open
  data_name = 'RH'
  gqvap = gpopen(dir + "QVap.nc", "QVap")
  gps = gpopen(dir + "Ps.nc", "Ps")
  gtemp = gpopen(dir + "Temp.nc", "Temp")
  if gqvap.nil? or gps.nil? or gtemp.nil? then 
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end
  # 座標データの取得
  lon = gtemp.axis('lon')
  lat = gtemp.axis('lat')
  sig = gtemp.axis('sig').to_gphys

  # 定数設定
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

    # 気圧の計算
    press = calc_press(ps,sig)    
    

    # dcpamのデフォルトでは飽和比湿の計算で 
    # saturate_t1930.f90 が使われている
    #
    # 飽和水蒸気圧の計算
    es = es0 * ( latentheat / gasrwet * ( 1/273.0 - 1/temp ) ).exp
    # 水蒸気圧の計算
    e = qvap * press / epsv
    # 相対湿度の計算
    rh = e / es * 100 # [%] 


    # 飽和非湿の計算
#    qvap_sat = epsv * (p0 / press) * (-latheat / (gasruniv * temp) ).exp
    # 相対湿度の計算
#    rh = qvap / qvap_sat * 100 # [%]

    rh.units = '%'
    rh.long_name = 'relative humidity'
    rh.name = data_name  

    [rh]
    }
  ofile.close
  print "[#{data_name}](#{dir}) is created\n"
end

def calc_rh_rank(dir)
  rank = ["rank000006.nc","rank000004.nc","rank000002.nc","rank000000.nc",
          "rank000001.nc","rank000003.nc","rank000005.nc","rank000007.nc"]
  rank.each do |footer|
    begin 
      ps = gpopen(dir +"Ps"+"_"+footer,"Ps")
      qvap = gpopen(dir +"QVap"+"_"+footer,"QVap")
      temp = gpopen(dir +"Temp"+ "_"+footer,"Temp")
    rescue 
      print "[RH](#{dir}) is not created\n"
      next
    end
    Utiles_spe.calc_rh(qvap,temp,ps)
  end
end

# option
opt = OptionParser.new
opt.on('-r','--rank'){Flag_rank = true}
opt.parse!(ARGV) 
list = Utiles_spe::Explist.new(ARGV[0])

list.dir.each{ |dir| calc_rh_rank(dir) } if defined?(Flag_rank)
list.dir.each{|dir| calc_rh(dir)} if !defined?(Flag_rank)

