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

def sub_sig2sigm(gp,sigm)
  lon = gp.axis("lon")
  lat = gp.axis("lat")
  time = gp.axis("time")
  result = GPhys.new(Grid.new(lon,lat,sigm.axis("sigm"),time),
                     VArray.new(
                       NArray.sfloat(
                         lon.length,lat.length,sigm.length,time.length)))
  result.name = gp.name
  result.units = gp.units
  result[false] = 0
  return result
end

def diff_sig(gp,sigm)
  result = sub_sig2sigm(gp,sigm)
  sig = gp.axis("sig").to_gphys.val
  (sig.length-1).times do |n|
    result[false,n+1,true].val = 
          (gp.cut("sig"=>sig[n+1]).val-gp.cut("sig"=>sig[n]).val)/
                                                    (sig[n+1]-sig[n])
  end
  return result
end

def r_inp_z(z_gp,sigm)
  sig = z_gp.axis("sig").to_gphys.val
  r_gp = sub_sig2sigm(z_gp,sigm)
  sigm = sigm.val
  r_gp[false,0,true].val = z_gp[false,0,true].val
  (sig.length-2).times do |n|
    alph = log(sigm[n+1]/sig[n+1]) / log(sig[n]/sig[n+1])
    beta = log(sig[n]/sigm[n+1]) / log(sig[n]/sig[n+1])
    r_gp[false,n+1,true].val = alph * z_gp[false,n,true].val 
                               + beta * z_gp[false,n+1,true].val
  end
  r_gp[false,-1,true].val = z_gp[false,-1,true].val

  return r_gp
end

def calc_dthetadz(list)
  list.dir.each_index do |n|
    data_name = 'BVfreq'
    data_long_name = "buoyancy frequency"
    temp = gpopen list.dir[n] + "Temp.nc"
    sigm = gpopen list.dir[n] + "Temp.nc","sigm"  
    ps = gpopen list.dir[n] + "Ps.nc"
    return if temp.nil? or ps.nil?  
    sig = temp.axis("sig").to_gphys
    
    if defined? HrInDay  and HrInDay.nil? then
      hr_in_day = HrInDay 
    elsif list.id.include? "coriolis"
      hr_in_day = 24
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end
    
    ave = 0
    GPhys.each_along_dims([temp,ps],'time') do
      |z_temp,gps|
 
      z_press = calc_press(gps,sig)
      r_press = calc_press(gps,sigm)
      r_temp = r_inp_z(z_temp,sigm)

      z_theta = potential_temperature(z_temp,z_press)
      r_theta = potential_temperature(r_temp,r_press)

      dthetadz = - diff_sig(z_theta,sigm) * sigm/(r_theta*r_temp*GasRDry+1e-14) * Grav**2
      ave += local_time(dthetadz,hr_in_day)
    end
    ave.name = data_name
    ave.long_name = data_long_name    
    ave = ave[false,0] if ave.axnames.include?("time")
    ave = ave/temp.axis("time").pos.length
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

calc_dthetadz(Explist.new(ARGV[0]))
