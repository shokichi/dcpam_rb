#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 可降水量
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math


def calc_prcwtr(dir)
  data_name = 'PrcWtr'
  # file open
  begin
    gqv = gpopen(dir + "QVap.nc", "QVap")
    gps = gpopen(dir + "Ps.nc", "Ps")
    sigm = gpopen(dir + "QVap.nc", "sigm")
  rescue
    print "[#{data_name}](#{dir}) is not created \n"
    return
  end

  # constant
  grav = UNumeric[9.8, "m.s-2"]

  lon = gqv.axis("lon")
  lat = gqv.axis("lat")

  ofile2 = NetCDF.create( dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([gqv,gps], ofile2, 'time') { 
    |qvap,ps|  
    #
    time = qvap.axis("time")    

    qc_na = NArray.sfloat(lon.length,lat.length,time.length)
    grid = Grid.new(lon,lat,time)
    qc = GPhys.new(grid,VArray.new(qc_na))
    qc.units = 'kg.m-2'
    qc.long_name = 'precipitable water'
    qc.name = data_name
    qc[false] = 0

    alph = qvap * ps / grav 
    kmax = 15
    for i in 0..kmax
      k = kmax-i
      qc = qc + alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
    end
    [qc]
   }
  ofile2.close
  print "[#{data_name}](#{dir}) is created \n"
end

list= Utiles_spe.explist(ARGV[0])
list.dir.each{|dir| calc_prcwtr(dir)}
