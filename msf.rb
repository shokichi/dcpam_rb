#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# stream function
# 質量流線関数
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math


def calc_msf(dir)
  data_name = 'Strm'
  # file open
  begin
    gv = gpopen(dir + "V.nc", "V")
    gps = gpopen(dir + "Ps.nc", "Ps")
    sigm = gpopen(dir + "V.nc", "sigm")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end
  # 定数設定
  grav = UNumeric[9.8, "m.s-2"]
  a = UNumeric[6400000.0, "m"]

  # 座標データの取得
  lon = gv.axis("lon")
  lat = gv.axis("lat")

  ofile2 = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gv,gps], ofile2, 'time') { 
    |vwind,ps|  
    #
    time = vwind.axis("time")    

    psi_na = NArray.sfloat(lon.length,lat.length,sigm.length,time.length)
    grid = Grid.new(lon,lat,sigm.axis("sigm"),time)
    psi = GPhys.new(grid,VArray.new(psi_na))
    psi.units = 'kg.s-1'
    psi.long_name = 'mass stream function'
    psi.name = data_name
    psi[false] = 0

    cos_phi = ( vwind.axis("lat").to_gphys * (PI/180.0) ).cos
    alph = vwind * cos_phi * ps * a * PI * 2 / grav 
    kmax = 15
    for i in 0..kmax
      k = kmax-i
      psi[false,k,true] = psi[false,k+1,true] +
                alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
    end
    [psi]
   }
  ofile2.close
  print "[#{data_name}](#{dir}) is created \n"
end

def calc_msf_rank(dir)
  rank = ["rank000006.nc","rank000004.nc","rank000002.nc","rank000000.nc",
          "rank000001.nc","rank000003.nc","rank000005.nc","rank000007.nc"]
  rank.each do |footer|
    begin 
      ps = GPhys::IO.open(dir +"Ps"+"_"+footer,"Ps")
      qvap = GPhys::IO.open(dir +"QVap"+"_"+footer,"QVap")
      temp = GPhys::IO.open(dir +"Temp"+ "_"+footer,"Temp")
    rescue 
      print "[RH](#{dir}) is not created\n"
      next
    end
    Utiles_spe.calc_msf(qvap,temp,ps)
  end
end


list = Utiles_spe::Explist.new(ARGV[0])
if ARGV.index("-rank") then
  list.dir.each{ |dir| calc_msf_rank(dir) }
else
  list.dir.each{|dir| calc_msf(dir)}
end
