#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 地方時で平均
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require '/home/ishioka/ruby/lib/utiles_spe'
include NumRu
include Math


def local_time(var_name,list)
  list.dir.each_index do |n|
    begin 
      gp = GPhys::IO.open(list.dir[n] + var_name + '.nc',var_name)
      time = GPhys::IO.open(list.dir[n] + var_name + '.nc','time')
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end
    #gp = gp[false,0..300]  
    #time = time[false,0..300]

    if time.get_att("hour_in_day") != nil then
      hr_in_day = time.get_att("hour_in_day")
    else

      hr_in_day = 24 / omega_ratio(list.name[n])
    end

    if time.units.to_s=='min' 
      time = time / 60
      time.units = 'hrs'
    elsif time.units.to_s=='day'
      time = time * 24
      time.units = 'hrs'
    end
    lon = gp.axis('lon')
    p hr_in_day
    local_time = lon.pos / 360 * hr_in_day
    local_time.long_name = "local time"
    local_time.units = "hrs"

    lon = lon.to_gphys
    dlon = lon[1].val-lon[0].val

    data_name = 'local_' + var_name
    ofile = NetCDF.create(list.dir[n] + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gp,time], ofile, 'time') { 
      |gphys,gtime|  
      gp_local = gphys.copy
      gp_local[false] = 0

      hr = gtime.val/hr_in_day
      hr = hr - hr.to_i

      eqtime = 360*hr
      local = lon + eqtime
      for i in 0..local.length-1
        if local[i].val > 360 then
          local[i].val = local[i].val-360.0
        end
      end
      min = local.val.min
      for i in 0..lon.length-1
        n = local.to_a.index(min + dlon*i)
        gp_local[i,false].val = gphys[n,false].val
      end

      gp_local.axis(0).set_pos(local_time)

      [gp_local]
    }
    ofile.close
  end
end

def local_time_mean(var_name,dir)
  for n in 0..dir.length-1
    begin 
      gp = GPhys::IO.open(dir[n] + var_name + '.nc',var_name)
      time = GPhys::IO.open(dir[n] + var_name + '.nc','time')
    rescue
      print "[#{var_name}](#{dir[n]}) is not exist\n"
      next
    end

#    gp = gp[false,0..300]  
#    time = time[false,0..300]

    if time.units.to_s=='min' 
      time = time / 60
      time.units = 'hrs'
    elsif time.units.to_s=='day'
      time = time * 24
      time.units = 'hrs'
    end
    lon = gp.axis('lon')

    hr_in_day = time.get_att("hour_in_day")
    hr_in_day = 24

    local_time = lon.pos / 360 * hr_in_day
    local_time.long_name = "local time"
    local_time.units = "hrs"

    lon = lon.to_gphys
    dlon = lon[1].val-lon[0].val

    ave = 0
    ofile = NetCDF.create(dir[n] + "MTlocal_" + var_name + '.nc')
    GPhys.each_along_dims([gp,time], 'time') do |gphys,gtime|  
      gp_local = gphys.copy
      gp_local[false] = 0

      hr = gtime.val/hr_in_day
      hr = hr - hr.to_i

      eqtime = 360*hr
      local = lon + eqtime
      for i in 0..local.length-1
        if local[i].val > 360 then
          local[i].val = local[i].val-360.0
        end
      end

      min = local.val.min
      for i in 0..lon.length-1
        n = local.to_a.index(min + dlon*i)
        gp_local[i,false].val = gphys[n,false].val
      end
      gp_local.axis(0).set_pos(local_time)
      ave = ave + gp_local      
    end
    ave = ave[false,0]/time.length
    GPhys::IO.write(ofile, ave)
    ofile.close
  end
end
def omega_ratio(name)# 名前解析 nameからomega/omega_Eを抽出
  if name[0..4] == "omega" or name[0..4] == "Omega" then
    var = name.sub("omega","").sub("Omega","")
    if var.include?("-")
      var = var.split("-")
      var = var[1].to_f/var[0].to_f
    elsif var.include?("/")
      var = var.split("/") 
      var = var[0].to_f/var[1].to_f
    end
    ratio = var.to_f
  else
    print "ERROR: [#{name}] can't decode\n"
    ratio = 1.0
  end
  return ratio
end

list = Utiles_spe::Explist.new(ARGV[0])
varname = ARGV[1]

local_time(varname,list) if varname != nil
local_time("OSRA",list)
=begin
local_time_mean('Rain',dir)
local_time_mean('RainCumulus',dir)
local_time_mean('RainLsc',dir)
local_time_mean('EvapA',dir)
local_time_mean('SensA',dir)
local_time_mean('SSRA',dir)
local_time_mean('SLRA',dir)
local_time_mean('OSRA',dir)
local_time_mean('OLRA',dir)
#local_time_mean('SurfTemp',dir)
#local_time_mean('Temp',dir)
=end
#local_time_mean('RH',dir,name)
#local_time_mean("QVap",dir)
#local_time_mean("SigDot",dir)
#local_time_mean("U",dir)
#local_time_mean("V",dir)
#local_time_mean("RadLDWFLXA",dir)
#local_time_mean("RadSDWFLXA",dir)
#local_time_mean("RadLUWFLXA",dir)
#local_time_mean("RadSUWFLXA",dir)

#local_time_mean("Ps",dir)
#local_time_mean("QVapCulumu",dir)

#local_time("DQVapDtCond",dir)
#local_time("DQVapDtVDiff",dir)    
#local_time("DTempDtDyn",dir)   
#local_time("DTempDtVDiff",dir)
#local_time("DQVapDtCumulus",dir)  
#local_time("DTempDtCond",dir)     
#local_time("DTempDtLsc",dir)   
#local_time("DQVapDtDyn",dir)      
#local_time("DTempDtCumulus",dir)  
#local_time("DTempDtRadL",dir)
#local_time("DQVapDtLsc",dir)      
#local_time("DTempDtDryConv",dir)  
#local_time("DTempDtRadS",dir)
print `date`

=begin
DCL.gropn(1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)
GGraph.tone gp_local.mean(-1)
DCL.grcls
=end 

