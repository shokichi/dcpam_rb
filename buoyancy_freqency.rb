#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 温位の鉛直勾配
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/lib/dcpam.rb")
require 'optparse'
include NumRu
include Math

def calc_BVfreq(z_temp,gp,sig,sigm)
  z_press = calc_press(ps,sig)
  r_press = calc_press(ps,sigm)
  r_temp = r_inp_z(z_temp,sigm)
  
  z_theta = potential_temperature(z_temp,z_press)
  r_theta = potential_temperature(r_temp,r_press)
  
  bvfreq = - diff_sig(z_theta,sigm) * sigm/(r_theta*r_temp*GasRDry+1e-14) * Grav**2
  return bvfreq
end

def calc_DThetaDsig(z_temp,ps,sig,sigm)
  z_press = calc_press(ps,sig)
  z_theta = potential_temperature(z_temp,z_press)
  result = - diff_sig(z_theta,sigm)
  return result
end

def calc_DThetaDsigMoist(z_temp,qvap,ps,sig,sigm)
  z_press = calc_press(ps,sig)
  z_theta = equiv_potential_temperature(z_temp,qvap,z_press)
  result = - diff_sig(z_theta,sigm)
  return result
end

def create_BVfreq(list)
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
      |gtemp,gps|
      dthetadz = calc_BVfreq(gtemp,gps,sig,sigm)
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

def create_DThetaDsigMoist(list)
  list.dir.each_index do |n|
    data_name = 'DThetaDsigMoist'
    data_long_name = "vertical grad of equiv potential temp"
    temp = gpopen list.dir[n] + "Temp.nc"
    temp = gpopen list.dir[n] + "QVap.nc"
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
    GPhys.each_along_dims([temp,qvap,ps],'time') do
      |gtemp,gqvap,gps|
      dthetadz = calc_DThetaDsig(gtemp,gqvap,gps,sig,sigm)
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


def create_DThetaDsig(list)
  list.dir.each_index do |n|
    data_name = 'DThetaDsig'
    data_long_name = "vertical grad of potential temp"
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
      |gtemp,gps|
      dthetadz = calc_DThetaDsigMoist(gtemp,gps,sig,sigm)
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
opt.on("--bf") {CalcBF = true}
opt.on("--moist") {CalcEQV = true}
opt.parse!(ARGV)

if defined? CalcBF
  create_BVfreq(Explist.new(ARGV[0]))
elsif defined? CalcEQV
  create_DThetaDsigSat(Explist.new(ARGV[0]))
else
  create_DThetaDsigSat(Explist.new(ARGV[0]))
end
