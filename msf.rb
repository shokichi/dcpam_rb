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
    gv = GPhys::IO.open(dir + "V.nc", "V")
    gps = GPhys::IO.open(dir + "Ps.nc", "Ps")
    sigm = GPhys::IO.open(dir + "V.nc", "sigm")
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

dir, name = Utiles_spe.explist(ARGV[0])
dir.each{|datadir| calc_msf(datadir)}

