#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Global average

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math
include NMath

def gave_list(var_name,dir,name,file)
  for n in 0..dir.length-1
    # データの取得
    begin
      gp = GPhys::IO.open(dir[n] + var_name + ".nc",var_name).cut("time"=>1080..1440)
    rescue
      print "[#{var_name}](#{dir[n]}) is not exist\n"
      return
    end
    gp = gp[false,0,true] if gp.rank == 4

    # 全球平均
    gp = Utiles_spe.glmean(gp) if gp.rank != 1
 
    # 降水量の単位変換
    gp = Utiles_spe.wm2mmyr(gp) if var_name[0..3]=="Rain"

    # リスト作成
    if n == 0 then
      std = gp.mean("time")
      file.print "--- #{gp.long_name} ---\n"       
    end
    file.print "#{name[n]}\t#{gp.mean("time")}\t#{(gp.mean("time")-std)/std}\n" 
#    file.printf ("\t%6f",gp.mean("time"))
  end
end

def gave_netrad(dir,name)  # エネルギー収支の確認
  # データの取得
  begin
    osr = GPhys::IO.open(dir + "OSRA.nc","OSRA")
    olr = GPhys::IO.open(dir + "OLRA.nc","OLRA")
  rescue
    print "[OSR,OLR](#{dir}) is not exist\n"
    next
  end
  # 全球平均
  if osr.rank != 1 then
    osr = Utiles_spe.glmean(osr)
    olr = Utiles_spe.glmean(olr)
  end
  # 描画
  GGraph.line osr+olr,true,'title'=>'OSR+OLR '+name
end


def gave_AM(dir,name)  # エネルギー収支の確認
  # データの取得
  begin
    am = GPhys::IO.open(dir + "AnglMom.nc","AnglMom")
    ps = GPhys::IO.open(dir + "Ps.nc","Ps")
  rescue
    print "[AnglMon](#{dir}) is not exist\n"
    next
  end

  # 全球平均
  am = Utiles_spe.virtical_integral(Utiles_spe.glmean(am*ps)) if am.rank !=1

  # 描画
  GGraph.line am, true, 'title'=>'AnglMom '+name
end

#
list=ARGV[0]
dir, name = Utiles_spe.explist(list)
id_exp = list.split("/")[-1].sub(".list","") if list != nil


if ARGV.index("-net") or ARGV.index("-a") then
  DCL.gropn(4)
  DCL.sgpset('lcntl',true)
  DCL.sgpset('isub', 96)
  DCL.uzfact(1.0)
  (0..dir.length-1).each{|n| gave_netrad(dir[n],name[n])}
  (0..dir.length-1).each{|n| gave_AM(dir[n],name[n])}
  DCL.grcls
end 

if !ARGV.index("-net") then 
  file = File.open("#{id_exp}_global-ave.dat","w")
  gave_list('OSRA',dir,name,file)
  gave_list('OLRA',dir,name,file)
  gave_list('SurfTemp',dir,name,file)
  gave_list('Temp',dir,name,file)
  gave_list('Rain',dir,name,file)
  gave_list('RainCumulus',dir,name,file)
  gave_list('RainLsc',dir,name,file)
  gave_list('PrcWtr',dir,name,file)
  gave_list('QVap',dir,name,file)
  gave_list('SSRA',dir,name,file)
  gave_list('SLRA',dir,name,file)
  gave_list('EvapA',dir,name,file)
  gave_list('SensA',dir,name,file)
  gave_list('RadSUWFLXA',dir,name,file)
  gave_list('RadSDWFLXA',dir,name,file)
  gave_list('RadLUWFLXA',dir,name,file)
  gave_list('RadLDWFLXA',dir,name,file)
  file.close
  puts "#{id_exp}_global-ave.dat created\n"
end
