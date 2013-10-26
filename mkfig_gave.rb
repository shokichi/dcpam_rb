#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Global average

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu

#
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("--max=max") {|max| Max = max.to_f}
opt.on("--min=min") {|min| Min = min.to_f}
opt.on("--nlev=nlev") {|nlev| Nlev = nlev.to_f}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}

opt.parse!(ARGV)


def gave_list(var_name,list)
  datalist = []
  list.dir.lengtheach_index do |n|
    # データの取得
    gp = gpopen list.dir[n] + varname
    return if gp.nil?
    
    # 大気最下層切り出し
    gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
    gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")

    # 全球平均
    gp = Utiles_spe.glmean(gp) if gp.rank != 1
 
    # 降水量の単位変換
    gp = Utiles_spe.wm2mmyr(gp) if var_name[0..3]=="Rain"

    # リスト作成
    datalist << [list.name[n]}, gp.mean("time")] 
  end

  # ファイル出力
  Outfile.print "--- #{gp.long_name} ---\n"
  datalist.each do |data|
    Outfile.print data, "\t"
    Outfile.print data[1]-datalist[list.refnum][1]/datalist[list.refnum][1], "\n"
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
list = Utiles_spe::Explist.new(ARGV[0])

if ARGV.index("-net") or ARGV.index("-a") then
  DCL.gropn(4)
  DCL.sgpset('lcntl',true)
  DCL.sgpset('isub', 96)
  DCL.uzfact(1.0)
  (0..dir.length-1).each{|n| gave_netrad(dir[n],name[n])}
  (0..dir.length-1).each{|n| gave_AM(dir[n],name[n])}
  DCL.grcls
end 

  Outfile = File.open("#{list.id}_global-ave.dat","w")
  gave_list('OSRA',list)
  gave_list('OLRA',list)
  gave_list('SurfTemp',list)
  gave_list('Temp',list)
  gave_list('Rain',list)
  gave_list('RainCumulus',list)
  gave_list('RainLsc',list)
  gave_list('PrcWtr',list)
  gave_list('QVap',list)
  gave_list('SSRA',list)
  gave_list('SLRA',list)
  gave_list('EvapA',list)
  gave_list('SensA',list)
  gave_list('RadSUWFLXA',list)
  gave_list('RadSDWFLXA',list)
  gave_list('RadLUWFLXA',list)
  gave_list('RadLDWFLXA',list)
  file.close
  puts "#{list.id}_global-ave.dat created\n"
