#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 地方時で平均
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require '/home/ishioka/ruby/lib/utiles_spe'
include Utiles_spe
include NumRu
include Math


def local_time(var_name,list)
  list.dir.each_index do |n|
    begin 
      gp = gpopen(list.dir[n] + var_name + '.nc',var_name)
      time = gpopen(list.dir[n] + var_name + '.nc','time')
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end

    # hr_in_day の取得
    if time.get_att("hour_in_day") != nil then
      hr_in_day = time.get_att("hour_in_day")
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end

=begin
    # 時間の単位を hrs に合わせる
    if time.units.to_s=='min' 
      time = time / 60
      time.units = 'hrs'
    elsif time.units.to_s=='day'
      time = time * 24
      time.units = 'hrs'
    end
=end
    lon = gp.axis('lon').to_gphys
#    local_time = lon.pos / 360 * hr_in_day
    local_time = lon.copy
    local_time.name = "local"
    local_time.long_name = "local time"
    local_time.units = "hrs"

    lon = lon.to_gphys
#    dlon = lon[1].val-lon[0].val

    data_name = 'local_' + var_name
    ofile = NetCDF.create(list.dir[n] + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gp,time], ofile, 'time') { 
      |gphys,gtime|

      # 時間の単位を[day]に変更
      nowtime = gtime/hr_in_day    if gtime.units.to_s != "hrs"
      nowtime = gtime/hr_in_day/60 if gtime.units.to_s != "min"

      local_time.val = nowtime[0].val + lon.val/360
      local_time = (local_time - local_time.to_i)*hr_in_day

      # 補助座標に地方時を設定 
      gphys.set_assoc_coords([local_time])
    
      # 地方時の値を準備
#      press_crd = sig.val*RefPrs
#      p press_crd
      local_crd = VArray.new( local_crd, {"units"=>"hrs"}, "local")
  
      # 鉛直座標を気圧に変換
      gp_local = gphys.interpolate(lon.name=>local_crd)
#
#      min = local.val.min
#      for i in 0..lon.length-1
#        n = local.to_a.index(min + dlon*i)
#        gp_local[i,false].val = gphys[n,false].val
#      end
#
#      gp_local.axis(0).set_pos(local_time)
      [gp_local]
    }
    ofile.close
  end
end

def local_time_mean(var_name,list)
  list.dir.each_index do |n|
    begin 
      gp = gpopen(list.dir[n] + var_name + '.nc',var_name)
      time = gpopen(list.dir[n] + var_name + '.nc','time')
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end

    # hr_in_day の取得
    if time.get_att("hour_in_day") != nil then
      hr_in_day = time.get_att("hour_in_day")
    else
      hr_in_day = 24 / omega_ratio(list.name[n])
    end

    # 時間の単位を hrs に合わせる
    if time.units.to_s=='min' 
      time = time / 60
      time.units = 'hrs'
    elsif time.units.to_s=='day'
      time = time * 24
      time.units = 'hrs'
    end

    lon = gp.axis('lon')
    local_time = lon.pos / 360 * hr_in_day
    local_time.long_name = "local time"
    local_time.units = "hrs"

    lon = lon.to_gphys
    dlon = lon[1].val-lon[0].val

    ave = 0
    ofile = NetCDF.create(list.dir[n] + "MTlocal_" + var_name + '.nc')
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
      gp_local.axis("lon").set_pos(local_time)
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
#local_time("OSRA",list)
#=begin
local_time_mean('Rain',list)
local_time_mean('RainCumulus',list)
local_time_mean('RainLsc',list)
local_time_mean('EvapA',list)
local_time_mean('SensA',list)
local_time_mean('SSRA',list)
local_time_mean('SLRA',list)
local_time_mean('OSRA',list)
local_time_mean('OLRA',list)
local_time_mean('SurfTemp',list)
local_time_mean('Temp',list)
#=end
#local_time_mean('RH',list,name)
local_time_mean("QVap",list)
local_time_mean("SigDot",list)
local_time_mean("U",list)
local_time_mean("V",list)
local_time_mean("RadLDWFLXA",list)
local_time_mean("RadSDWFLXA",list)
local_time_mean("RadLUWFLXA",list)
local_time_mean("RadSUWFLXA",list)

local_time_mean("Ps",list)
#local_time_mean("QVapCulumu",list)

#local_time("DQVapDtCond",list)
#local_time("DQVapDtVDiff",list)    
#local_time("DTempDtDyn",list)   
#local_time("DTempDtVDiff",list)
#local_time("DQVapDtCumulus",list)  
#local_time("DTempDtCond",list)     
#local_time("DTempDtLsc",list)   
#local_time("DQVapDtDyn",list)      
#local_time("DTempDtCumulus",list)  
#local_time("DTempDtRadL",list)
#local_time("DQVapDtLsc",list)      
#local_time("DTempDtDryConv",list)  
#local_time("DTempDtRadS",list)
print `date`

=begin
DCL.gropn(1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)
GGraph.tone gp_local.mean(-1)
DCL.grcls
=end 

