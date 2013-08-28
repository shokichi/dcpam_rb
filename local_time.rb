#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 地方時で平均
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


def local_time(var_name,list)
  list.dir.each_index do |n|
    begin 
      gp = gpopen(list.dir[n] + var_name + '.nc',var_name)
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end
 
    begin
      rst_file = list.dir[n].sub("data/","rst_data/rst1800.nc").sub("data1400/","rst_data/rst1440.nc")
      hr_in_day = gpopen(rst_file,'time').get_att("hour_in_day")
    rescue
      hr_in_day = 24 / omega_ratio(list.name[n])
      hr_in_day = 24 if list.id.include?("coriolis")
    end

    lon = gp.axis('lon')

    local = lon.pos
    local = lon.pos*hr_in_day/360
    local.long_name = "local time"
#    local.name = "hrs"

    lon = lon.to_gphys
    local_time = lon.copy
    nlon = lon.length

    data_name = 'local_' + var_name
    ofile = NetCDF.create(list.dir[n] + data_name + '.nc')
    GPhys::NetCDF_IO.each_along_dims_write([gp], ofile, 'time') { 
      |gphys|

      nowtime = gphys.axis("time").to_gphys
      gp_local = gphys.copy
      # 時間の単位を[day]に変更
      nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
      nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
      # 日付が変わる経度を検出
      local_time = nowtime + lon/360
      local_time = (local_time - local_time.to_i)*hr_in_day
      local_min_index = local_time.val.to_a.index(local_time.val.min)
      # データの並び替え
      gp_local[0..nlon-1-local_min_index,false] = gphys[local_min_index..-1,false]
      gp_local[nlon-local_min_index..-1,false] = gphys[0..local_min_index-1,false]
      # lon -> localtime 変換
      gp_local.axis("lon").set_pos(local)
      [gp_local]
    }
    ofile.close
  end
end

def local_time_mean(var_name,list)
  list.dir.each_index do |n|
    begin 
      gp = GPhys::IO.open(list.dir[n] + var_name + '.nc',var_name)
    rescue
      print "[#{var_name}](#{list.dir[n]}) is not exist\n"
      next
    end
 
    begin
      rst_file = list.dir[n].sub("data/","rst_data/rst1800.nc").sub("data1400/","rst_data/rst1440.nc")
      hr_in_day = gpopen(rst_file,'time').get_att("hour_in_day")
    rescue
      hr_in_day = 24 / omega_ratio(list.name[n])
    end

    lon = gp.axis('lon')

    local = lon.pos
    local = lon.pos*hr_in_day/360

    lon = lon.to_gphys
    local_time = lon.copy
    nlon = lon.length
    
    ave = 0
    GPhys.each_along_dims(gp, 'time') { 
      |gphys|

      nowtime = gphys.axis("time").to_gphys
      gp_local = gphys.copy
      # 時間の単位を[day]に変更
      nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
      nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
      # 日付が変わる経度を検出
      local_time.val = nowtime.val + lon.val/360
      local_time.val = (local_time.val - local_time.val.to_i)*hr_in_day
      local_min_index = local_time.val.to_a.index(local_time.val.min)
      # データの並び替え
      if local_min_index != 0 then
        gp_local[0..nlon-1-local_min_index,false].val = gphys[local_min_index..-1,false].val
        gp_local[nlon-local_min_index..-1,false].val = gphys[0..local_min_index-1,false].val
      end
      # lon -> localtime 変換
      gp_local.axis("lon").set_pos(local)
      ave = ave + gp_local      
    }
    ave = ave[false,0]/gp.axis("time").pos.length
    data_name = 'MTlocal_' + var_name
    ofile = NetCDF.create(list.dir[n] + data_name + '.nc')
    GPhys::IO.write(ofile, ave)
    ofile.close
  end
end

def local_time_mean_rank(var_name,list)
  rank = ["rank000006.nc","rank000004.nc","rank000002.nc","rank000000.nc",
          "rank000001.nc","rank000003.nc","rank000005.nc","rank000007.nc"]
  list.dir.each_index do |n|
    if !defined?(HrInDay).nil?
      hr_in_day = HrInDay 
    else
      begin
        rst_file = list.dir[n].sub("data/","rst_data/rst1800.nc").sub("data1400/","rst_data/rst1440.nc")
        hr_in_day = gpopen(rst_file,'time').get_att("hour_in_day")
      rescue
        hr_in_day = 24 / omega_ratio(list.name[n])
        hr_in_day = 24 if list.id.include?("coriolis")
      end
    end
    str_add(list.dir[n]+var_name.sub(".nc","")+ "_",rank).each do |file|
      begin 
        gp = GPhys::IO.open(file,var_name)
      rescue
        print "[#{var_name}](#{list.dir[n]}) is not exist\n"
        next
      end
  
      lon = gp.axis('lon')
  
      local = lon.pos
      local = lon.pos*hr_in_day/360
      local.long_name = "local time"
  
      lon = lon.to_gphys
      local_time = lon.copy
      nlon = lon.length
      
      ave = 0
      GPhys.each_along_dims(gp,'time') do 
        |gphys|
  
        nowtime = gphys.axis("time").to_gphys
        gp_local = gphys.copy
        # 時間の単位を[day]に変更
        nowtime.val = nowtime.val/hr_in_day    if nowtime.units.to_s == "hrs"
        nowtime.val = nowtime.val/hr_in_day/60 if nowtime.units.to_s == "min"
        # 日付が変わる経度を検出
        local_time.val = nowtime.val + lon.val/360
        local_time.val = (local_time.val - local_time.val.to_i)*hr_in_day
        local_min_index = local_time.val.to_a.index(local_time.val.min)
        # データの並び替え
        if local_min_index != 0 then
          gp_local[0..nlon-1-local_min_index,false].val = gphys[local_min_index..-1,false].val
          gp_local[nlon-local_min_index..-1,false].val = gphys[0..local_min_index-1,false].val
        end
        # lon -> localtime 変換
        gp_local.axis("lon").set_pos(local)
        ave = ave + gp_local      
      end
      ave = ave[false,0]/gp.axis("time").pos.length
      ofile = NetCDF.create(file.sub(var_name,"MTlocal_" + var_name))
      GPhys::IO.write(ofile, ave)
      ofile.close
    end
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

rank_flag = false
varname = nil
opt = OptionParser.new
opt.on("-r","--rank") {rank_flag = true}
opt.on("-n VAR") {|str| varname = str}
opt.on("-n VAL","--hr_in_day=VAL") {|hr_in_day| HrInDay = hr_in_day}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])


if !varname.nil? then
  local_time_mean_rank(varname,list) if rank_flag
  local_time_mean(varname,list) if !rank_flag
else
var_list = 
[ 
  'Rain',
  'RainCumulus',
  'RainLsc',
  'EvapA',
  'SensA',
  'SSRA',
  'SLRA',
  'OSRA',
  'OLRA',
  'SurfTemp',
  'Temp',
  "QVap",
  "SigDot",
  "U",
  "V",
  "RadLDWFLXA",
  "RadSDWFLXA",
  "RadLUWFLXA",
  "RadSUWFLXA",
  "Ps",
  "H2OLiq",
  "PrcWtr",
  'RH',
  "DQVapDtCond",
  "DQVapDtVDiff",    
  "DTempDtDyn",   
  "DTempDtVDiff",
  "DQVapDtCumulus",  
  "DTempDtCond",     
  "DTempDtLsc",   
  "DQVapDtDyn",      
  "DTempDtCumulus",  
  "DTempDtRadL",
  "DQVapDtLsc",      
  "DTempDtDryConv",  
  "DTempDtRadS"
]

var_list.each{ |var| local_time_mean_rank(var,list) } 

end


  #local_time("OSRA",list)
=begin
  local_time_mean_rank('Rain',list)
  local_time_mean_rank('RainCumulus',list)
  local_time_mean_rank('RainLsc',list)
  local_time_mean_rank('EvapA',list)
  local_time_mean_rank('SensA',list)
  local_time_mean_rank('SSRA',list)
  local_time_mean_rank('SLRA',list)
  local_time_mean_rank('OSRA',list)
  local_time_mean_rank('OLRA',list)
  local_time_mean_rank('SurfTemp',list)
  local_time_mean_rank('Temp',list)
  #local_time_mean_rank("QVap",list)
  local_time_mean_rank("SigDot",list)
  local_time_mean_rank("U",list)
  local_time_mean_rank("V",list)
  local_time_mean_rank("RadLDWFLXA",list)
  local_time_mean_rank("RadSDWFLXA",list)
  local_time_mean_rank("RadLUWFLXA",list)
  local_time_mean_rank("RadSUWFLXA",list)
  
  local_time_mean_rank("Ps",list)
  #=end
  #local_time_mean_rank("H2OLiq",list)
  #local_time_mean_rank("PrcWtr",list)
  local_time_mean_rank('RH',list)
  
  local_time_mean_rank("DQVapDtCond",list)
  local_time_mean_rank("DQVapDtVDiff",list)    
  local_time_mean_rank("DTempDtDyn",list)   
  local_time_mean_rank("DTempDtVDiff",list)
  local_time_mean_rank("DQVapDtCumulus",list)  
  local_time_mean_rank("DTempDtCond",list)     
  local_time_mean_rank("DTempDtLsc",list)   
  local_time_mean_rank("DQVapDtDyn",list)      
  local_time_mean_rank("DTempDtCumulus",list)  
  local_time_mean_rank("DTempDtRadL",list)
  local_time_mean_rank("DQVapDtLsc",list)      
  local_time_mean_rank("DTempDtDryConv",list)  
  local_time_mean_rank("DTempDtRadS",list)
  print `date`
=end
=begin
DCL.gropn(1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)
GGraph.tone gp_local.mean(-1)
DCL.grcls
=end 
