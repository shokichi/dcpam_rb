#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 温位の鉛直勾配
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math

def potential_temperature(temp,press)
  return  temp*(RefPrs/press)**(GasRDry/CpDry) 
end

def diff_sig(gp,sigm)
  lon = gp.axis("lon")
  lat = gp.axis("lat")
  time = gp.axis("time")
  result = GPhys.new(Grid.new(lon,lat,sigm.axis("sigm"),time),
                     VArray.new(
                       NArray.sfloat(
                         lon.length,lat.length,sigm.length,time.length)))
  result.name = gp.name
  result[false] = 0

  sig = gp.axis("sig").to_gphys
  (sig.length-1).times do |n|
    result[n+1] = (gp.axis("sig"=>sig[n+1])-gp.axis("sig"=>sig[n]))/
                                                    (sig[n+1]-sig[n])
  end
  return result
end

def calc_dthetadsig(list)
  list.dir.each_index do |n|
    data_name = 'Theta'
    temp = gpopen list.dir[n] + "Temp.nc"  
    ps = gpopen list.dir[n] + "Ps.nc"
    return temp.nil? or ps.nil?  
    sig = tmep.axis("sig").to_gphys
    
    if defined?(HrInDay).nil? and HrInDay.nil? then
      hr_in_day = HrInDay 
    elsif list.id.include? "coriolis"
      hr_in_day = 24
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end
    
    ave = 0
    GPhys.each_along_dims([gv,gps],'time') do 
      press = calc_press(ps,sig)
      theta = potetial_temperature(temp,press)
      dthetadsig = diff_sig(theta,sig)
      ave += local_time(dthetadsig,hr_in_day)
    end
    ave.name = data_name    
    ave = ave[false,0] if ave.axnames.include?("time")
    ave = ave/gv.axis("time").pos.length
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

calc_dthetadsig(Explist.new(ARGV[0]))
