#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# stream function
# 質量流線関数
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require "optparse"
include Utiles_spe
include NumRu
include Math


def calc_msf(dir)
  data_name = 'Strm'
  # file open
  gv = gpopen(dir + "V.nc", "V")
  gps = gpopen(dir + "Ps.nc", "Ps")
  sigm = gpopen(dir + "V.nc", "sigm")
  return if gv.nil? or gps.nil? or sigm.nil?

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
    alph = vwind * cos_phi * ps * RPlanet * PI * 2 / Grav 
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

def calc_msf_rank(list)
  data_name = 'Strm'
  list.dir.each_index do |n|
    # file open
    gv = gpopen list.dir[n] + "V.nc"
    gps = gpopen list.dir[n] + "Ps.nc"
    sigm = gpopen list.dir[n] + "V.nc", "sigm"
    return if gv.nil? or gps.nil? or sigm.nil?

    # 座標データの取得
    lon = gv.axis("lon")
    lat = gv.axis("lat")
    
    if defined? HrInDay
      hr_in_day = HrInDay
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end
    
    ave = 0
    GPhys.each_along_dims([gv,gps],'time') do 
      |vwind,ps|  
      #
      time = vwind.axis("time")    
      psi_va = VArray.new(
                 NArray.sfloat(
                   lon.length,lat.length,sigm.length,time.length))

      grid = Grid.new(lon,lat,sigm.axis("sigm"),time)
      psi = GPhys.new(grid,psi_va)
      psi.units = 'kg.s-1'
      psi.long_name = 'mass stream function'
      psi.name = data_name
      psi[false] = 0
      
      cos_phi = ( vwind.axis("lat").to_gphys * (PI/180.0) ).cos
      alph = vwind * cos_phi * ps * RPlanet * PI * 2 / Grav 
      kmax = 15
      for i in 0..kmax
        k = kmax-i
        psi[false,k,true] = psi[false,k+1,true] +
          alph[false,k,true] * (sigm[k].val - sigm[k+1].val) 
      end
      
      # local time mean
      ave += local_time(psi,hr_in_day)
    end
    
    ave = ave[false,0] if ave.axnames.include?("time")
    ave = ave/vwind.axis("time").pos.length
    ofile = NetCDF.create(list.dir[n]+"MTlocal_"+data_name+".nc")
    GPhys::IO.write(ofile, ave)
    ofile.close
    print "[#{data_name}](#{list.dir[n]}) is created \n"
  end
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-h VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day.to_i}
opt.parse!(ARGV)
list = Utiles_spe::Explist.new(ARGV[0])
HrInDay = 24 if list.id.include?("coriolis")


if defined? Flag_rank
  calc_msf_rank(list)
else
  list.dir.each{|dir| calc_msf(dir)}
end
